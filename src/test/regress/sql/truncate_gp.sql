-- Mask out segment file name
-- start_matchsubs
-- m/\ +stat_table_segfile_size\ +/
-- s/\ +stat_table_segfile_size\ +/stat_table_segfile_size/
-- m/----------------------------+/
-- s/----------------------------+/---------------------------/
-- m/segfile.*,/
-- s/segfile:\d+\/\d+/segfile###/
-- end_matchsubs

-- start_ignore
CREATE EXTENSION plpython3u;
-- end_ignore
--- Fucntion which lists the table segment file size on each segment.
CREATE OR REPLACE FUNCTION stat_table_segfile_size(datname text, tabname text)
    RETURNS TABLE (dbid int2, relfilenode_dboid_relative_path text, size int)
    VOLATILE LANGUAGE plpython3u
AS
$fn$
import os
db_instances = {}
relfilenodes = {}

result = plpy.execute("SELECT oid AS dboid FROM pg_database WHERE datname='%s'" % datname)
dboid = result[0]['dboid']

result = plpy.execute("SELECT relfilenode FROM gp_dist_random('pg_class') WHERE relname = '%s' ORDER BY gp_segment_id" % tabname)
for col in range(0, result.nrows()):
    relfilenodes[col] = str(result[col]['relfilenode'])

result = plpy.execute("select dbid, datadir from gp_segment_configuration where role ='p' and content >= 0 order by dbid;")
for col in range(0, result.nrows()):
    db_instances[result[col]['dbid']] = result[col]['datadir']

rows = []
i = -1
for dbid, datadir in db_instances.items():
    relative_path_to_dboid_dir = ''
    absolute_path_to_dboid_dir = '%s/base/%d' % (datadir, dboid)
    i = i+1
    try:
        for relfilenode in sorted(os.listdir(absolute_path_to_dboid_dir)):
            relfilenode_prefix = relfilenode.split('.')[0]
            if relfilenodes[i] != relfilenode_prefix:
                continue
            relfilenode_absolute_path = absolute_path_to_dboid_dir + '/' + relfilenode
            size_relfilenode = os.stat(relfilenode_absolute_path).st_size
            row = {
                'relfilenode_dboid_relative_path': 'segfile:%d/%s' % (dboid, relfilenode),
                'dbid': dbid,
                'size': size_relfilenode
            }
            rows.append(row)
    except OSError:
        #plpy.notice("dboid dir for database %s does not exist on dbid = %d" % (datname, dbid))
        rows.append({
            'relfilenode_dboid_relative_path': None,
            'dbid': dbid,
            'size': None
        })
return rows
$fn$;

-- switch to unaligned output mode
\pset format unaligned

-- test truncate table and create table are in the same transaction for ao table
begin;
create table truncate_with_create_ao(a int, b int) with (appendoptimized = true, orientation = row) distributed by (a);
insert into truncate_with_create_ao select i, i from generate_series(1,10)i;
truncate truncate_with_create_ao;
end; 

-- the ao table segment file size after truncate should be zero
select stat_table_segfile_size('regression', 'truncate_with_create_ao');

-- test truncate table and create table are in the same transaction for aocs table
begin;
create table truncate_with_create_aocs(a int, b int) with (appendoptimized = true, orientation = column) distributed by (a);
insert into truncate_with_create_aocs select i, i from generate_series(1,10)i;
truncate truncate_with_create_aocs;
end; 

-- the aocs table segment file size after truncate should be zero
select stat_table_segfile_size('regression', 'truncate_with_create_aocs');

-- test truncate table and create table are in the same transaction for heap table
begin;                                                                          
create table truncate_with_create_heap(a int, b int) distributed by (a);
insert into truncate_with_create_heap select i, i from generate_series(1,10)i;
truncate truncate_with_create_heap;
end;

-- the heap table segment file size after truncate should be zero
select stat_table_segfile_size('regression', 'truncate_with_create_heap');
