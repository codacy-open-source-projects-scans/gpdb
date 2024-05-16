/*---------------------------------------------------------------------
 *
 * gp_dump_oids.c
 *
 * Copyright (c) 2015-Present VMware, Inc. or its affiliates.
 *
 *
 * IDENTIFICATION
 *	    src/backend/utils/adt/gp_dump_oids.c
 *
 *---------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/genam.h"
#include "access/table.h"
#include "catalog/dependency.h"
#include "catalog/indexing.h"
#include "catalog/pg_attrdef.h"
#include "catalog/pg_depend.h"
#include "catalog/pg_inherits.h"
#include "catalog/pg_proc.h"
#include "common/hashfn.h"
#include "tcop/tcopprot.h"
#include "optimizer/optimizer.h"
#include "optimizer/planmain.h"
#include "parser/analyze.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/rel.h"
#include "utils/syscache.h"

static List *proc_oids_for_dump = NIL;
static bool is_proc_oids_valid = false;

Datum gp_dump_query_oids(PG_FUNCTION_ARGS);

List* get_proc_oids_for_dump(void);

PG_FUNCTION_INFO_V1(gp_dump_query_oids);

/*
 * Append a list of Oids to a StringInfo, separated by commas.
 */
static void
appendOids(StringInfo buf, List *oids)
{
	ListCell   *lc;
	bool		first = true;

	foreach(lc, oids)
	{
		if (!first)
			appendStringInfoChar(buf, ',');
		appendStringInfo(buf, "%u", lfirst_oid(lc));
		first = false;
	}
}

/*
 * Error context callback for handling errors in the SQL query passed as
 * argument to gp_dump_query_oids()
 */
static void
sql_query_parse_error_callback(void *arg)
{
	const char *query_text = (const char *) arg;
	int			syntaxerrposition = geterrposition();

	/*
	 * The error is not in the original query. Report the query that was
	 * passed as argument as an "internal query", and the position in it.
	 */
	errposition(0);
	internalerrposition(syntaxerrposition);
	internalerrquery(query_text);
}

void
add_proc_oids_for_dump(Oid funcid)
{
	if (is_proc_oids_valid)
		proc_oids_for_dump = lappend_oid(proc_oids_for_dump, funcid);
}

List*
get_proc_oids_for_dump()
{
	return proc_oids_for_dump;
}

/*
 * Collect a list of OIDs of all attribute default of the specified relation,
 * if they have a dependency from the attribute default to the relation.
 */
static List *
getAttrDefaultOfRel(Oid relid)
{
	List	   *result = NIL;
	Relation	depRel;
	ScanKeyData key[2];
	SysScanDesc scan;
	HeapTuple	tup;

	depRel = table_open(DependRelationId, AccessShareLock);

	ScanKeyInit(&key[0],
				Anum_pg_depend_refclassid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(RelationRelationId));
	ScanKeyInit(&key[1],
				Anum_pg_depend_refobjid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(relid));

	scan = systable_beginscan(depRel, DependReferenceIndexId, true,
							  NULL, 2, key);

	while (HeapTupleIsValid(tup = systable_getnext(scan)))
	{
		Form_pg_depend deprec = (Form_pg_depend) GETSTRUCT(tup);
		if (deprec->classid == AttrDefaultRelationId &&
			deprec->objsubid == 0 &&
			deprec->refobjsubid != 0)
		{
			result = lappend_oid(result, deprec->objid);
		}
	}

	systable_endscan(scan);
	table_close(depRel, AccessShareLock);

	return result;
}

/*
 * Collect a list of OIDs of all sequences referenced by the specified relation,
 * whether or not they are owned by relation.
 */
static List *
getRefedSequences(Oid relid)
{
	List	   *result = getAttrDefaultOfRel(relid);
	List	   *seqresult = NIL;
	Relation	depRel;
	ScanKeyData key[2];
	SysScanDesc scan;
	HeapTuple	tup;
	ListCell   *lc;

	if (!result)
		return seqresult;

	depRel = table_open(DependRelationId, AccessShareLock);

	foreach(lc, result)
	{
		Oid objid = lfirst_oid(lc);
		ScanKeyInit(&key[0],
				Anum_pg_depend_classid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(AttrDefaultRelationId));

		ScanKeyInit(&key[1],
				Anum_pg_depend_objid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(objid));

		scan = systable_beginscan(depRel, DependDependerIndexId, true,
							  NULL, 2, key);

		while (HeapTupleIsValid(tup = systable_getnext(scan)))
		{
			Form_pg_depend deprec = (Form_pg_depend) GETSTRUCT(tup);

			/*
			 * The attrdef have dependency on both relation column and seuqence if they invoke
			 * nextval(). We need the relkind test)
			 */
			if(deprec->refclassid == RelationRelationId &&
				deprec->refobjsubid == 0 &&
				get_rel_relkind(deprec->refobjid) == RELKIND_SEQUENCE)
			{
				seqresult = lappend_oid(seqresult, deprec->refobjid);
			}
		}

		systable_endscan(scan);
	}

	table_close(depRel, AccessShareLock);

	return seqresult;
}

/*
 * Function dumping dependent relation & function oids for a given SQL text
 */
Datum
gp_dump_query_oids(PG_FUNCTION_ARGS)
{
	char	   *sqlText = text_to_cstring(PG_GETARG_TEXT_P(0));
	List	   *raw_parsetree_list;
	List	   *flat_query_list;
	ListCell   *lc;
	HASHCTL		ctl;
	HTAB	   *dedup_htab;
	StringInfoData str;
	ErrorContextCallback sqlerrcontext;
	List	   *invalidItems = NIL;
	List	   *relationOids = NIL;
	List       *seqrelationOids = NIL;
	List	   *deduped_relationOids = NIL;
	List	   *procOids = NIL;

	/*
	 * Setup error traceback support for ereport().
	 */
	sqlerrcontext.callback = sql_query_parse_error_callback;
	sqlerrcontext.arg = sqlText;
	sqlerrcontext.previous = error_context_stack;
	error_context_stack = &sqlerrcontext;

	/*
	 * Parse and analyze the query.
	 */
	raw_parsetree_list = pg_parse_query(sqlText);

	flat_query_list = NIL;
	foreach(lc, raw_parsetree_list)
	{
		RawStmt    *parsetree = lfirst_node(RawStmt, lc);
		List	   *queryTree_sublist;


		Query	*query = parse_analyze(parsetree, sqlText, NULL, 0, NULL);
		if (query->commandType == CMD_UTILITY && IsA(query->utilityStmt, ExplainStmt))
		{
			query = (Query *)((ExplainStmt *) query->utilityStmt)->query;
		}
		query->expandMatViews = true;
		queryTree_sublist = pg_rewrite_query(query);

		flat_query_list = list_concat(flat_query_list,
									  list_copy(queryTree_sublist));
	}

	error_context_stack = sqlerrcontext.previous;

	/* Then scan each Query and scrape any relation and function OIDs */
	is_proc_oids_valid = true;
	PG_TRY();
	{
		foreach(lc, flat_query_list)
		{
			Query	   *q = lfirst(lc);
			List	   *q_relationOids = NIL;
			List	   *q_invalidItems = NIL;
			bool	   hasRowSecurity = false;

			extract_query_dependencies((Node *) q, &q_relationOids, &q_invalidItems, &hasRowSecurity);

			relationOids = list_concat(relationOids, q_relationOids);
			invalidItems = list_concat(invalidItems, q_invalidItems);
		}
	}
	PG_CATCH();
	{
		/* Make proc_oids_valid set false and proc_oids_for_dump set null */
		is_proc_oids_valid = false;
		proc_oids_for_dump = NIL;
		PG_RE_THROW();
	}
	PG_END_TRY();
	is_proc_oids_valid = false;

	/*
	 * Collect referenced sequences
	 */
	foreach(lc, relationOids)
	{
		Oid                     relid = lfirst_oid(lc);
		seqrelationOids = list_concat(seqrelationOids, getRefedSequences(relid));
	}
	relationOids = list_concat(relationOids, seqrelationOids);

	/*
	 * Deduplicate the relation oids
	 */
	memset(&ctl, 0, sizeof(HASHCTL));
	ctl.keysize = sizeof(Oid);
	ctl.entrysize = sizeof(Oid);
	ctl.hash = oid_hash;
	dedup_htab = hash_create("relid hash table", 100, &ctl, HASH_ELEM | HASH_FUNCTION);

	deduped_relationOids = NIL;
	foreach(lc, relationOids)
	{
		Oid			relid = lfirst_oid(lc);
		bool		found;

		hash_search(dedup_htab, (void *) &relid, HASH_ENTER, &found);
		if (!found)
		{
			deduped_relationOids = lappend_oid(deduped_relationOids, relid);

			/*
			 * Also find all child table relids including inheritances,
			 * interior and leaf partitions of given root table oid
			 */
			List *child_relids = find_all_inheritors(relid, NoLock, NULL);

			if (child_relids)
			{
				child_relids = list_delete_first(child_relids);
				deduped_relationOids = list_concat(deduped_relationOids, child_relids);
			}
		}
	}
	relationOids = deduped_relationOids;

	/*
	 * Fetch the procedure OIDs based on the PlanInvalItems. Deduplicate them as
	 * we go.
	 */
	memset(&ctl, 0, sizeof(HASHCTL));
	ctl.keysize = sizeof(Oid);
	ctl.entrysize = sizeof(Oid);
	ctl.hash = oid_hash;
	dedup_htab = hash_create("funcid hash table", 100, &ctl, HASH_ELEM | HASH_FUNCTION);

	foreach (lc, get_proc_oids_for_dump())
	{
		Oid funcId = lfirst_oid(lc);
		bool		found;

		hash_search(dedup_htab, (void *) &funcId, HASH_ENTER, &found);
		if (!found)
			procOids = lappend_oid(procOids, funcId);
	}

	proc_oids_for_dump = NIL;

	/*
	 * Construct the final output
	 */
	initStringInfo(&str);

	appendStringInfo(&str, "{\"relids\": \"");
	appendOids(&str, relationOids);

	appendStringInfoString(&str, "\", \"funcids\": \"");
	appendOids(&str, procOids);
	appendStringInfo(&str, "\"}");

	PG_RETURN_TEXT_P(cstring_to_text(str.data));
}
