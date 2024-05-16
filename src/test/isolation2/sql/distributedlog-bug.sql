--
-- Test for a bug in checking tuple visibility against a distributed snapshot
-- that turned up during merge PostgreSQL 9.6. We incorrectly set the
-- HEAP_XMAX_DISTRIBUTED_SNAPSHOT_IGNORE hint bit on a tuple, when the
-- transaction was in fact a distributed transaction that was still
-- in-progress.
--
CREATE TABLE distributed_snapshot_test ( id INTEGER, f FLOAT);

1: BEGIN;
2: BEGIN;
2: SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
2: select 'dummy select to establish snapshot';
1: select count(*) > 0 as tbl_found from gp_dist_random('pg_class') where relname = 'distributed_snapshot_test';

-- Drop table in a transaction
1: drop table distributed_snapshot_test;

3: vacuum pg_class;

-- Commit the DROP.
1: COMMIT;

-- The table should still be visible to transaction 2's snapshot.
2: select count(*) > 0 as tbl_found from gp_dist_random('pg_class') where relname = 'distributed_snapshot_test';
