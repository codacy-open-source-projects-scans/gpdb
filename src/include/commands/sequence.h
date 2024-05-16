/*-------------------------------------------------------------------------
 *
 * sequence.h
 *	  prototypes for sequence.c.
 *
 * Portions Copyright (c) 2006-2008, Greenplum inc.
 * Portions Copyright (c) 2012-Present VMware, Inc. or its affiliates.
 * Portions Copyright (c) 1996-2019, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/commands/sequence.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef SEQUENCE_H
#define SEQUENCE_H

#include "access/xlogreader.h"
#include "catalog/objectaddress.h"
#include "fmgr.h"
#include "lib/stringinfo.h"
#include "nodes/parsenodes.h"
#include "parser/parse_node.h"
#include "storage/relfilenode.h"


typedef struct FormData_pg_sequence_data
{
	int64		last_value;
	int64		log_cnt;
	bool		is_called;
} FormData_pg_sequence_data;

typedef FormData_pg_sequence_data *Form_pg_sequence_data;

/*
 * PostgreSQL default value is 1, GPDB privately bump up to 20.
 * If a sequence in UDF, QE executor need to apply sequence value from QD.
 * Frequent sequence application is network bottleneck for query execution.
 */
#define SEQ_CACHE_DEFAULT 20

/*
 * Columns of a sequence relation
 */

#define SEQ_COL_LASTVAL			1
#define SEQ_COL_LOG				2
#define SEQ_COL_CALLED			3

#define SEQ_COL_FIRSTCOL		SEQ_COL_LASTVAL
#define SEQ_COL_LASTCOL			SEQ_COL_CALLED

/* XLOG stuff */
#define XLOG_SEQ_LOG			0x00

#define SEQ_NEXTVAL_FALSE		'f'
#define SEQ_NEXTVAL_TRUE		't'
#define SEQ_NEXTVAL_QUERY_RESPONSE	'?'

typedef struct xl_seq_rec
{
	RelFileNode 	node;

	/* SEQUENCE TUPLE DATA FOLLOWS AT THE END */
} xl_seq_rec;

extern int64 nextval_internal(Oid relid, bool check_permissions, bool called_from_dispatcher);
extern Datum nextval(PG_FUNCTION_ARGS);
extern void nextval_qd(Oid relid, int64 *plast, int64 *pcached, int64  *pincrement, bool *poverflow);
extern List *sequence_options(Oid relid);

extern ObjectAddress DefineSequence(ParseState *pstate, CreateSeqStmt *stmt);
extern ObjectAddress AlterSequence(ParseState *pstate, AlterSeqStmt *stmt);
extern void DeleteSequenceTuple(Oid relid);
extern void ResetSequence(Oid seq_relid);
extern void ResetSequenceCaches(void);

extern void seq_redo(XLogReaderState *rptr);
extern void seq_desc(StringInfo buf, XLogReaderState *rptr);
extern const char *seq_identify(uint8 info);
extern void seq_mask(char *pagedata, BlockNumber blkno);

#endif							/* SEQUENCE_H */
