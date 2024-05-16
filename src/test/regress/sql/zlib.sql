-- Test temporary file compression.
--
-- The test file is called 'zlib' for historical reasons. GPDB uses Zstandard
-- rather than zlib for temporary file compression, nowadays.

-- If the server is built without libzstd (configure --without-zstd), this
-- fails with error "workfile compresssion is not supported by this build".
-- The tests are less interesting in that case, but they should still pass.
-- So use a gpdiff rule to ignore that error:
--
-- start_matchignore
-- m/ERROR:  workfile compresssion is not supported by this build/
-- end_matchignore
SET gp_workfile_compression = on;

DROP TABLE IF EXISTS test_zlib_hashjoin;
CREATE TABLE test_zlib_hashjoin (i1 int, i2 int, i3 int, i4 int, i5 int, i6 int, i7 int, i8 int) WITH (APPENDONLY=true) DISTRIBUTED BY (i1) ; 
INSERT INTO test_zlib_hashjoin SELECT i,i,i,i,i,i,i,i FROM 
	(select generate_series(1, nsegments * 333333) as i from 
	(select count(*) as nsegments from gp_segment_configuration where role='p' and content >= 0) foo) bar;

-- start_ignore
create language plpython3u;
-- end_ignore

-- Check if compressed work file count is limited to file_count_limit
-- If the parameter is_comp_buff_limit is true, it means the comp_workfile_created
-- must be smaller than file_count_limit because some work files are not compressed;
-- If the parameter is_comp_buff_limit is false, it means the comp_workfile_created
-- must be equal to file_count_limit because all work files are compressed.
create or replace function check_workfile_compressed(explain_query text,
    is_comp_buff_limit bool)
returns setof int as
$$
import re
rv = plpy.execute(explain_query)
search_text = 'Work file set'
result = []
for i in range(len(rv)):
    cur_line = rv[i]['QUERY PLAN']
    if search_text.lower() in cur_line.lower():
        p = re.compile('(\d+) files \((\d+) compressed\)')
        m = p.search(cur_line)
        workfile_created = int(m.group(1))
        comp_workfile_created = int(m.group(2))
        if is_comp_buff_limit:
            result.append(int(comp_workfile_created < workfile_created))
        else:
            result.append(int(comp_workfile_created == workfile_created))
return result
$$
language plpython3u;

SET statement_mem=5000;

--Fail after workfile creation and before add it to workfile set
select gp_inject_fault('workfile_creation_failure', 'reset', 2);
select gp_inject_fault('workfile_creation_failure', 'error', 2);

SELECT COUNT(t1.*) FROM test_zlib_hashjoin AS t1, test_zlib_hashjoin AS t2 WHERE t1.i1=t2.i2;

select gp_inject_fault('workfile_creation_failure', 'status', 2);

RESET statement_mem;
DROP TABLE IF EXISTS test_zlib_hagg; 
CREATE TABLE test_zlib_hagg (i1 int, i2 int, i3 int, i4 int);
INSERT INTO test_zlib_hagg SELECT i,i,i,i FROM 
	(select generate_series(1, nsegments * 300000) as i from 
	(select count(*) as nsegments from gp_segment_configuration where role='p' and content >= 0) foo) bar;

SET statement_mem=2000;

--Fail after workfile creation and before add it to workfile set
select gp_inject_fault('workfile_creation_failure', 'reset', 2);
select gp_inject_fault('workfile_creation_failure', 'error', 2);

SELECT MAX(i1) FROM test_zlib_hagg GROUP BY i2;

select gp_inject_fault('workfile_creation_failure', 'status', 2);

-- Reset faultinjectors
select gp_inject_fault('workfile_creation_failure', 'reset', 2);

create table test_zlib (i int, j text);
insert into test_zlib select i, i from generate_series(1,1000000) as i;
create table test_zlib_t1(i int, j int);

set statement_mem='10MB';

create or replace function FuncA()
returns void as
$body$
begin
 	insert into test_zlib values(2387283, 'a');
 	insert into test_zlib_t1 values(1, 2);
    CREATE TEMP table TMP_Q_QR_INSTM_ANL_01 WITH(APPENDONLY=true,COMPRESSLEVEL=5,ORIENTATION=row,COMPRESSTYPE=zlib) on commit drop as
    SELECT t1.i from test_zlib as t1 join test_zlib as t2 on t1.i = t2.i;
EXCEPTION WHEN others THEN
 -- do nothing
end
$body$ language plpgsql;

-- Inject fault before we close workfile in ExecHashJoinNewBatch
select gp_inject_fault('workfile_creation_failure', 'reset', 2);
select gp_inject_fault('workfile_creation_failure', 'error', 2);

select FuncA();
select * from test_zlib_t1;

select gp_inject_fault('workfile_creation_failure', 'status', 2);

drop function FuncA();
drop table test_zlib;
drop table test_zlib_t1;
drop table test_zlib_hashjoin;

select gp_inject_fault('workfile_creation_failure', 'reset', 2);

-- Test gp_workfile_compression_overhead_limit to control the memory limit used by
-- compressed temp file

DROP TABLE IF EXISTS test_zlib_memlimit;
create table test_zlib_memlimit(a int, b text, c timestamp) distributed by (a);
insert into test_zlib_memlimit select id, 'test ' || id, clock_timestamp() from
   (select generate_series(1, nsegments * 30000) as id from
   (select count(*) as nsegments from gp_segment_configuration where role='p' and content >= 0) foo) bar;
insert into test_zlib_memlimit select 1,'test', now() from
   (select generate_series(1, nsegments * 2000) as id from
   (select count(*) as nsegments from gp_segment_configuration where role='p' and content >= 0) foo) bar;
insert into test_zlib_memlimit select id, 'test ' || id, clock_timestamp() from
   (select generate_series(1, nsegments * 3000) as id from
   (select count(*) as nsegments from gp_segment_configuration where role='p' and content >= 0) foo) bar;
analyze test_zlib_memlimit;

set statement_mem='2MB';
set gp_workfile_compression=on;
set gp_workfile_limit_files_per_query=0;

-- Run the query with a large value of gp_workfile_compression_overhead_limit
-- The compressed file number should be equal to total work file number

set gp_workfile_compression_overhead_limit=2048000;

select * from check_workfile_compressed('
explain (analyze)
with B as (select distinct a+1 as a,b,c from test_zlib_memlimit)
,C as (select distinct a+2 as a,b,c from test_zlib_memlimit)
,D as (select a+3 as a,b,c from test_zlib_memlimit)
,E as (select a+4 as a,b,c from test_zlib_memlimit)
,F as (select (a+5)::text as a,b,c from test_zlib_memlimit)
select count(*) from test_zlib_memlimit A
inner join  B on A.a = B.a
inner join  C on A.a = C.a
inner join  D on A.a = D.a
inner join  E on A.a = E.a
inner join  F on A.a::text = F.a ;',
false) limit 6;

-- Run the query with a smaller value of gp_workfile_compression_overhead_limit
-- The compressed file number should be less than total work file number

set gp_workfile_compression_overhead_limit=5000;

select * from check_workfile_compressed('
explain (analyze)
with B as (select distinct a+1 as a,b,c from test_zlib_memlimit)
,C as (select distinct a+2 as a,b,c from test_zlib_memlimit)
,D as (select a+3 as a,b,c from test_zlib_memlimit)
,E as (select a+4 as a,b,c from test_zlib_memlimit)
,F as (select (a+5)::text as a,b,c from test_zlib_memlimit)
select count(*) from test_zlib_memlimit A
inner join  B on A.a = B.a
inner join  C on A.a = C.a
inner join  D on A.a = D.a
inner join  E on A.a = E.a
inner join  F on A.a::text = F.a ;',
true) limit 6;

-- Run the query with gp_workfile_compression_overhead_limit=0, which means
-- no limit
-- The compressed file number should be equal to total work file number

set gp_workfile_compression_overhead_limit=0;

select * from check_workfile_compressed('
explain (analyze)
with B as (select distinct a+1 as a,b,c from test_zlib_memlimit)
,C as (select distinct a+2 as a,b,c from test_zlib_memlimit)
,D as (select a+3 as a,b,c from test_zlib_memlimit)
,E as (select a+4 as a,b,c from test_zlib_memlimit)
,F as (select (a+5)::text as a,b,c from test_zlib_memlimit)
select count(*) from test_zlib_memlimit A
inner join  B on A.a = B.a
inner join  C on A.a = C.a
inner join  D on A.a = D.a
inner join  E on A.a = E.a
inner join  F on A.a::text = F.a ;',
false) limit 6;

DROP TABLE test_zlib_memlimit;
