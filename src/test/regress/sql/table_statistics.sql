create schema table_stats;
set search_path=table_stats;
set optimizer_print_missing_stats = off;
-- Regular Table
Create table stat_heap_t1 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) distributed by (i);

Insert into stat_heap_t1 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Create index stat_idx_heap_t1 on stat_heap_t1(i);

Analyze stat_heap_t1;

select count(*) from pg_class where relname like 'stat_heap_t1%';

-- Alter table without a default value
Alter table stat_heap_t1 add column new_col varchar;
 
select  count(*) from pg_class where relname like 'stat_heap_t1%';

-- Alter table with a default value
Alter table stat_heap_t1 add column new_col2 text default 'new column with new value';

select  count(*) from pg_class where relname like 'stat_heap_t1%';

-- Partitioned Table
Create table stat_part_heap_t1 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_heap_t1 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_heap_t1;

select  count(*) from pg_class where relname like 'stat_part_heap_t1';

-- Alter table without a default value
Alter table stat_part_heap_t1 add column new_col varchar;

select  count(*) from pg_class where relname like 'stat_part_heap_t1';

-- Alter table with a default value
Alter table stat_part_heap_t1 add column new_col2 text default 'new column with new value';

select  count(*) from pg_class where relname like 'stat_part_heap_t1';

-- Regular Table
Create table stat_ao_t1 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5) distributed by (i) ;

Insert into stat_ao_t1 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_ao_t1;

select  count(*) from pg_class where relname like 'stat_ao_t1%';

-- Alter table with a default value
Alter table stat_ao_t1 add column new_col2 text default 'new column with new value';

select  count(*) from pg_class where relname like 'stat_ao_t1%';

-- Partitioned Table
Create table stat_part_ao_t1 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5) distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_ao_t1 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Create index stat_part_idx_ao_t1 on stat_part_ao_t1(d);

Analyze stat_part_ao_t1;

select  count(*) from pg_class where relname like 'stat_part_ao_t1';

-- Alter table with a default value
Alter table stat_part_ao_t1 add column new_col2 text default 'new column with new value';

select  count(*) from pg_class where relname like 'stat_part_ao_t1';

-- Regular Table
Create table stat_co_t1 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5, orientation=column) distributed by (i) ;

Insert into stat_co_t1 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_co_t1;

select  count(*) from pg_class where relname like 'stat_co_t1%';

-- Alter table with a default value
Alter table stat_co_t1 add column new_col2 text default 'new column with new value';

select  count(*) from pg_class where relname like 'stat_co_t1%';

-- Partitioned Table
Create table stat_part_co_t1 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5, orientation=column) distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_co_t1 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_co_t1;

select  count(*) from pg_class where relname like 'stat_part_co_t1';

-- Alter table with a default value
Alter table stat_part_co_t1 add column new_col2 text default 'new column with new value';

select  count(*) from pg_class where relname like 'stat_part_co_t1';

-- Regular Table
Create table stat_heap_t2 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) distributed by (i);

Insert into stat_heap_t2 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_heap_t2;

select  count(*) from pg_class where relname like 'stat_heap_t2%';

-- Alter table drop column
Alter table stat_heap_t2 drop column d;
 
select  count(*) from pg_class where relname like 'stat_heap_t2%';

-- Partitioned Table
Create table stat_part_heap_t2 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_heap_t2 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_heap_t2;

select  count(*) from pg_class where relname like 'stat_part_heap_t2';

-- Alter table drop column
Alter table stat_part_heap_t2 drop column d;

select  count(*) from pg_class where relname like 'stat_part_heap_t2';

-- Regular Table
Create table stat_ao_t2 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5) distributed by (i) ;

Insert into stat_ao_t2 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_ao_t2;

select  count(*) from pg_class where relname like 'stat_ao_t2%';

-- Alter table drop column
Alter table stat_ao_t2 drop column t;

select  count(*) from pg_class where relname like 'stat_ao_t2%';

-- Partitioned Table
Create table stat_part_ao_t2 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5) distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_ao_t2 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_ao_t2;

select  count(*) from pg_class where relname like 'stat_part_ao_t2';

-- Alter table drop column
Alter table stat_part_ao_t2 drop column t;

select  count(*) from pg_class where relname like 'stat_part_ao_t2';

-- Regular Table
Create table stat_co_t2 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5, orientation=column) distributed by (i) ;

Insert into stat_co_t2 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_co_t2;

select  count(*) from pg_class where relname like 'stat_co_t2%';

-- Alter table drop column
Alter table stat_co_t2 drop column t;


select  count(*) from pg_class where relname like 'stat_co_t2%';

-- Partitioned Table
Create table stat_part_co_t2 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5, orientation=column) distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_co_t2 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_co_t2;

select  count(*) from pg_class where relname like 'stat_part_co_t2';

-- Alter table drop column
Alter table stat_part_co_t2 drop column t;

select  count(*) from pg_class where relname like 'stat_part_co_t2';

-- Regular Table
Create table stat_heap_t3 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) distributed by (i);

Insert into stat_heap_t3 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_heap_t3;

select  count(*) from pg_class where relname like 'stat_heap_t3%';

-- Alter distribution
Alter table stat_heap_t3 set distributed by (j);
 
select  count(*) from pg_class where relname like 'stat_heap_t3%';

-- Partitioned Table
Create table stat_part_heap_t3 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
distributed by (i)  partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_heap_t3 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Create index stat_part_idx_heap_t3 on stat_part_heap_t3(d);

Analyze stat_part_heap_t3;

select  count(*) from pg_class where relname like 'stat_part_heap_t3';

-- Alter distribution
Alter table stat_part_heap_t3 set distributed by (j);

select  count(*) from pg_class where relname like 'stat_part_heap_t3';

-- Regular Table
Create table stat_ao_t3 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5) distributed by (i) ;

Insert into stat_ao_t3 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_ao_t3;

select  count(*) from pg_class where relname like 'stat_ao_t3%';

-- Alter distribution
Alter table stat_ao_t3 set distributed by (j);

select  count(*) from pg_class where relname like 'stat_ao_t3%';

-- Partitioned Table
Create table stat_part_ao_t3 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5) distributed by (i) partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_ao_t3 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_ao_t3;

select  count(*) from pg_class where relname like 'stat_part_ao_t3';

-- Alter distribution
Alter table stat_part_ao_t3 set distributed by (j);

select  count(*) from pg_class where relname like 'stat_part_ao_t3';

-- Regular Table
Create table stat_co_t3 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5, orientation=column) distributed by (i) ;

Insert into stat_co_t3 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_co_t3;

select  count(*) from pg_class where relname like 'stat_co_t3%';

-- Alter distribution
Alter table stat_co_t3 set distributed by (j);


select  count(*) from pg_class where relname like 'stat_co_t3%';

-- Partitioned Table
Create table stat_part_co_t3 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5, orientation=column) distributed by (i) partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_co_t3 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_co_t3;

select  count(*) from pg_class where relname like 'stat_part_co_t3';

-- Alter distribution
Alter table stat_part_co_t3 set distributed by (j);

select  count(*) from pg_class where relname like 'stat_part_co_t3';

-- Regular Table
Create table stat_heap_t4 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) distributed by (i);

Insert into stat_heap_t4 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_heap_t4;

select  count(*) from pg_class where relname like 'stat_heap_t4%';

-- Alter distribution
Alter table stat_heap_t4 set distributed randomly;
 
select  count(*) from pg_class where relname like 'stat_heap_t4%';

Alter table stat_heap_t4 set with (reorganize=true);

select  count(*) from pg_class where relname like 'stat_heap_t4%';

-- Partitioned Table
Create table stat_part_heap_t4 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
distributed by (i)  partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_heap_t4 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_heap_t4;

select  count(*) from pg_class where relname like 'stat_part_heap_t4';

-- Alter distribution
Alter table stat_part_heap_t4 set distributed randomly;

select  count(*) from pg_class where relname like 'stat_part_heap_t4';

Alter table stat_part_heap_t4 set with (reorganize=true);

select  count(*) from pg_class where relname like 'stat_part_heap_t4';

-- Regular Table
Create table stat_ao_t4 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5) distributed by (i) ;

Insert into stat_ao_t4 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_ao_t4;

select  count(*) from pg_class where relname like 'stat_ao_t4%';

-- Alter distribution
Alter table stat_ao_t4 set distributed randomly;

select  count(*) from pg_class where relname like 'stat_ao_t4%';

Alter table stat_ao_t4 set with (reorganize=true);

select  count(*) from pg_class where relname like 'stat_ao_t4%';

-- Partitioned Table
Create table stat_part_ao_t4 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5) distributed by (i) partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_ao_t4 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_ao_t4;

select  count(*) from pg_class where relname like 'stat_part_ao_t4';

-- Alter distribution
Alter table stat_part_ao_t4 set distributed randomly;

select  count(*) from pg_class where relname like 'stat_part_ao_t4';

Alter table stat_part_ao_t4 set with (reorganize=true);

select  count(*) from pg_class where relname like 'stat_part_ao_t4';

-- Regular Table
Create table stat_co_t4 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5, orientation=column) distributed by (i) ;

Insert into stat_co_t4 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_co_t4;

select  count(*) from pg_class where relname like 'stat_co_t4%';

-- Alter distribution
Alter table stat_co_t4 set distributed randomly;

select  count(*) from pg_class where relname like 'stat_co_t4%';

Alter table stat_co_t4 set with (reorganize=true);

select  count(*) from pg_class where relname like 'stat_co_t4%';

-- Partitioned Table
Create table stat_part_co_t4 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5, orientation=column) distributed by (i) partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_co_t4 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_co_t4;

select  count(*) from pg_class where relname like 'stat_part_co_t4';

-- Alter distribution
Alter table stat_part_co_t4 set distributed randomly;

select  count(*) from pg_class where relname like 'stat_part_co_t4';

Alter table stat_part_co_t4 set with (reorganize=true);

select  count(*) from pg_class where relname like 'stat_part_co_t4';


-- Regular Table
Create table stat_heap_t5 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) distributed randomly;

Insert into stat_heap_t5 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_heap_t5;

select  count(*) from pg_class where relname like 'stat_heap_t5%';

-- Alter distribution
Alter table stat_heap_t5 set distributed by (j);
 
select  count(*) from pg_class where relname like 'stat_heap_t5%';

-- Partitioned Table
Create table stat_part_heap_t5 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
distributed randomly  partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_heap_t5 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_heap_t5;

select  count(*) from pg_class where relname like 'stat_part_heap_t5';

-- Alter distribution
Alter table stat_part_heap_t5 set distributed by (j);

select  count(*) from pg_class where relname like 'stat_part_heap_t5';

-- Regular Table
Create table stat_ao_t5 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5) distributed randomly ;

Insert into stat_ao_t5 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_ao_t5;

select  count(*) from pg_class where relname like 'stat_ao_t5%';

-- Alter distribution
Alter table stat_ao_t5 set distributed by (j);

select  count(*) from pg_class where relname like 'stat_ao_t5%';

-- Partitioned Table
Create table stat_part_ao_t5 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5) distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_ao_t5 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_ao_t5;

select  count(*) from pg_class where relname like 'stat_part_ao_t5';

-- Alter distribution
Alter table stat_part_ao_t5 set distributed by (j);

select  count(*) from pg_class where relname like 'stat_part_ao_t5';

-- Regular Table
Create table stat_co_t5 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5, orientation=column) distributed randomly;

Insert into stat_co_t5 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_co_t5;

select  count(*) from pg_class where relname like 'stat_co_t5%';

-- Alter distribution
Alter table stat_co_t5 set distributed by (j);


select  count(*) from pg_class where relname like 'stat_co_t5%';

-- Partitioned Table
Create table stat_part_co_t5 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5, orientation=column) distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_co_t5 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_co_t5;

select  count(*) from pg_class where relname like 'stat_part_co_t5';

-- Alter distribution
Alter table stat_part_co_t5 set distributed by (j);

select  count(*) from pg_class where relname like 'stat_part_co_t5';

-- Regular Table
Create table stat_heap_t6 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) distributed by (i);

Insert into stat_heap_t6 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_heap_t6;

select  count(*) from pg_class where relname like 'stat_heap_t6%';

-- Alter table to reorganize = true
Alter table stat_heap_t6 set with (reorganize=true);
 
select  count(*) from pg_class where relname like 'stat_heap_t6%';

-- Alter table to reorganize = false
Alter table stat_heap_t6 set with (reorganize=false);

select  count(*) from pg_class where relname like 'stat_heap_t6%';

-- Partitioned Table
Create table stat_part_heap_t6 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
distributed by (i)  partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_heap_t6 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Create index stat_part_idx_heap_t6 on stat_part_heap_t6(d);

Analyze stat_part_heap_t6;

select  count(*) from pg_class where relname like 'stat_part_heap_t6';

-- Alter table to reorganize = true
Alter table stat_part_heap_t6 set with (reorganize=true);

select  count(*) from pg_class where relname like 'stat_part_heap_t6';

-- Alter table to reorganize = false
Alter table stat_part_heap_t6 set with (reorganize=false);

select  count(*) from pg_class where relname like 'stat_part_heap_t6';

-- Regular Table
Create table stat_ao_t6 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5) distributed by (i) ;

Insert into stat_ao_t6 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_ao_t6;

select  count(*) from pg_class where relname like 'stat_ao_t6%';

-- Alter table to reorganize = true
Alter table stat_ao_t6 set with (reorganize=true);

select  count(*) from pg_class where relname like 'stat_ao_t6%';

-- Alter table to reorganize = false
Alter table stat_ao_t6 set with (reorganize=false);

select  count(*) from pg_class where relname like 'stat_ao_t6%';

-- Partitioned Table
Create table stat_part_ao_t6 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5) distributed by (i) partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_ao_t6 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_ao_t6;

select  count(*) from pg_class where relname like 'stat_part_ao_t6';

-- Alter table to reorganize = true
Alter table stat_part_ao_t6 set with (reorganize=true);

select  count(*) from pg_class where relname like 'stat_part_ao_t6';

-- Alter table to reorganize = false
Alter table stat_part_ao_t6 set with (reorganize=false);

select  count(*) from pg_class where relname like 'stat_part_ao_t6';

-- Regular Table
Create table stat_co_t6 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5, orientation=column) distributed by (i) ;

Insert into stat_co_t6 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_co_t6;

select  count(*) from pg_class where relname like 'stat_co_t6%';

-- Alter table to reorganize = true
Alter table stat_co_t6 set with (reorganize=true);

select  count(*) from pg_class where relname like 'stat_co_t6%';

-- Alter table to reorganize = false
Alter table stat_co_t6 set with (reorganize=false);

select  count(*) from pg_class where relname like 'stat_co_t6%';

-- Partitioned Table
Create table stat_part_co_t6 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5, orientation=column) distributed by (i) partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_co_t6 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_co_t6;

select  count(*) from pg_class where relname like 'stat_part_co_t6';

-- Alter table to reorganize = true
Alter table stat_part_co_t6 set with (reorganize=true);

select  count(*) from pg_class where relname like 'stat_part_co_t6';

-- Alter table to reorganize = false
Alter table stat_part_co_t6 set with (reorganize=true);

select  count(*) from pg_class where relname like 'stat_part_co_t6';


-- Regular Table
Create table stat_heap_t7 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) distributed by (i);

Insert into stat_heap_t7 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_heap_t7;

select  count(*) from pg_class where relname like 'stat_heap_t7%';

-- Alter table alter column type
Alter table stat_heap_t7 alter column c type varchar;
 
select  count(*) from pg_class where relname like 'stat_heap_t7%';

-- Partitioned Table
Create table stat_part_heap_t7 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_heap_t7 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_heap_t7;

select  count(*) from pg_class where relname like 'stat_part_heap_t7';

-- Alter table alter type of a column
Alter table stat_part_heap_t7 alter column j type numeric;

select  count(*) from pg_class where relname like 'stat_part_heap_t7';


-- Regular Table
Create table stat_ao_t7 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5) distributed by (i) ;

Insert into stat_ao_t7 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_ao_t7;

select  count(*) from pg_class where relname like 'stat_ao_t7%';

-- Alter table alter column type
Alter table stat_ao_t7 alter column j type numeric;

select  count(*) from pg_class where relname like 'stat_ao_t7%';

-- Partitioned Table
Create table stat_part_ao_t7 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5) distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_ao_t7 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_ao_t7;

select  count(*) from pg_class where relname like 'stat_part_ao_t7';

-- Alter table alter column type
Alter table stat_part_ao_t7 alter column c type varchar;

select  count(*) from pg_class where relname like 'stat_part_ao_t7';

-- Regular Table
Create table stat_co_t7 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) with(appendonly=true,compresslevel=5, orientation=column) distributed by (i) ;

Insert into stat_co_t7 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_co_t7;

select  count(*) from pg_class where relname like 'stat_co_t7%';

-- Alter table alter type
Alter table stat_co_t7 alter column j type float;

select  count(*) from pg_class where relname like 'stat_co_t7%';

-- Partitioned Table
Create table stat_part_co_t7 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
with(appendonly=true,compresslevel=5, orientation=column) distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_co_t7 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_co_t7;

select  count(*) from pg_class where relname like 'stat_part_co_t7';

-- Alter table alter type
Alter table stat_part_co_t7 alter column i type numeric;

select  count(*) from pg_class where relname like 'stat_part_co_t7';

-- Regular Table
Create table stat_heap_t8 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) distributed by (i);

Insert into stat_heap_t8 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_heap_t8;

select  count(*) from pg_class where relname like 'stat_heap_t8%';

-- Create Index
Create index stat_idx_heap_t8 on stat_heap_t8(n);

-- Cluster on index
Cluster stat_idx_heap_t8 on stat_heap_t8;

select  count(*) from pg_class where relname like 'stat_heap_t8%';

-- Partitioned Table
Create table stat_part_heap_t8 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_heap_t8 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_heap_t8;

select  count(*) from pg_class where relname like 'stat_part_heap_t8';

-- Create Index
Create index stat_part_idx_heap_t8 on stat_part_heap_t8(d);

-- Cluster on index
Cluster stat_part_idx_heap_t8 on stat_part_heap_t8;

select  count(*) from pg_class where relname like 'stat_part_heap_t8';

-- Regular Table
Create table stat_heap_t9 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone) distributed by (i);

Insert into stat_heap_t9 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_heap_t9;

select  count(*) from pg_class where relname like 'stat_heap_t9%';

-- Create Index
Create index stat_idx_heap_t9 on stat_heap_t9(i);

-- Cluster on index
Cluster stat_idx_heap_t9 on stat_heap_t9;

select  count(*) from pg_class where relname like 'stat_heap_t9%';

Insert into stat_heap_t9 values(generate_series(1,10),500,'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

-- Cluster again 
Cluster stat_heap_t9;

select  count(*) from pg_class where relname like 'stat_heap_t9%';


-- Partitioned Table
Create table stat_part_heap_t9 (i int,j int, x text,c char,v varchar, d date, n numeric, t timestamp without time zone, tz time with time zone)  
distributed randomly partition by range (i) 
subpartition by list (j) subpartition template 
(
default subpartition subothers,
subpartition sub1 values(1,2,3), 
subpartition sub2 values(4,5,6)
) 
(default partition others, start (0) inclusive end (10) exclusive every (5) );

Insert into stat_part_heap_t9 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

Analyze stat_part_heap_t9;

select  count(*) from pg_class where relname like 'stat_part_heap_t9';

-- Create Index
Create index stat_part_idx_heap_t9 on stat_part_heap_t9(j);

-- Cluster on index
Cluster stat_part_idx_heap_t9 on stat_part_heap_t9;

select  count(*) from pg_class where relname like 'stat_part_heap_t9';

Insert into stat_part_heap_t9 values(generate_series(1,10),generate_series(1,5),'table statistics should be kept after alter','s', 'regular table','12-11-2012',3,'2012-10-09 10:23:54', '2011-08-19 10:23:54+02');

-- Cluster again
Cluster stat_part_heap_t9;

select  count(*) from pg_class where relname like 'stat_part_heap_t9';

