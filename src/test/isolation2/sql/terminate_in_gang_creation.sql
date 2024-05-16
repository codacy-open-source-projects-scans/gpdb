-- start_matchsubs
-- m/seg[0-9] [0-9.]+:\d+/
-- s/seg[0-9] [0-9.]+:\d+/segN IP:PORT/
-- m/lock \[\d+,\d+\]/
-- s/lock \[\d+,\d+\]//
-- end_matchsubs

-- skip dtx recovery check to avoid hitting the fault create_gang_in_progress.
SELECT gp_inject_fault_infinite('before_orphaned_check', 'skip', dbid)
    FROM gp_segment_configuration WHERE role='p' AND content=-1;
ALTER SYSTEM SET gp_dtx_recovery_interval to 5;
SELECT pg_reload_conf();
SELECT gp_wait_until_triggered_fault('before_orphaned_check', 1, dbid)
    FROM gp_segment_configuration WHERE role='p' AND content=-1;

-- SIGSEGV issue when freeing gangs
--
-- When SIGTERM is handled during gang creation we used to trigger
-- a wild pointer access like below backtrace:
--
-- #0  raise
-- #1  StandardHandlerForSigillSigsegvSigbus_OnMainThread
-- #2  <signal handler called>
-- #3  MemoryContextFreeImpl
-- #4  cdbconn_termSegmentDescriptor
-- #5  DisconnectAndDestroyGang
-- #6  freeGangsForPortal
-- #7  AbortTransaction
-- ...
-- #14 ProcessInterrupts
-- #15 createGang_async
-- #16 createGang
-- #17 AllocateWriterGang

DROP TABLE IF EXISTS foo;
CREATE TABLE foo (c1 int, c2 int) DISTRIBUTED BY (c1);

10: BEGIN;

SELECT gp_inject_fault('create_gang_in_progress', 'reset', 1);
SELECT gp_inject_fault('create_gang_in_progress', 'suspend', 1);

10&: SELECT * FROM foo a JOIN foo b USING (c2);

SELECT gp_wait_until_triggered_fault('create_gang_in_progress', 1, 1);

SELECT pg_terminate_backend(pid) FROM pg_stat_activity
 WHERE query = 'SELECT * FROM foo a JOIN foo b USING (c2);';

SELECT gp_inject_fault('create_gang_in_progress', 'resume', 1);

10<:
10q:

DROP TABLE foo;

-- Test a bug that if cached idle primary QE is gone (e.g. after kill-9, pg_ctl
-- restart, etc), a new query needs a new created reader gang might fail with
-- error like this:
--
-- ERROR:  failed to acquire resources on one or more segments
-- DETAIL:  FATAL:  reader could not find writer proc entry
-- DETAIL:  lock [0,1260] AccessShareLock 0. Probably because writer gang is gone somehow. Maybe try rerunning.
-- (seg2 127.0.0.1:7004)
--
-- This is ok since the writer gang is gone, but previously QD code does
-- not reset all gangs (just retry creating the new reader gang) so re-running
-- this query could always fail with the same error since the reader gang would
-- always fail to create. The below test is used to test the fix.

-- skip FTS probes to avoid segment being marked down on restart
SELECT gp_inject_fault_infinite('fts_probe', 'skip', dbid)
    FROM gp_segment_configuration WHERE role='p' AND content=-1;
SELECT gp_request_fts_probe_scan();
SELECT gp_wait_until_triggered_fault('fts_probe', 1, dbid)
    FROM gp_segment_configuration WHERE role='p' AND content=-1;

-- Prevent below pg_ctl restart timeout although the timeout should be enough.
CHECKPOINT;

-- not recycle idle QEs to avoid the flaky test where restarting primary takes a long time.
11: SET gp_vmem_idle_resource_timeout TO 0;
11: CREATE TABLE foo (c1 int, c2 int) DISTRIBUTED BY (c1);
-- ORCA optimizes value scan so there is no additional reader gang in below INSERT.
11: SET optimizer = off;
-- the value scan (reader gang) might be on any segment so restart all segments.
SELECT pg_ctl(datadir, 'restart', 'immediate')
	FROM gp_segment_configuration WHERE role='p' AND content != -1;
11: INSERT INTO foo values(2),(1);
11: INSERT INTO foo values(2),(1);
11: DROP TABLE foo;
11: RESET gp_vmem_idle_resource_timeout;

SELECT gp_inject_fault('fts_probe', 'reset', dbid)
	FROM gp_segment_configuration WHERE role='p' AND content=-1;
SELECT gp_inject_fault_infinite('before_orphaned_check', 'reset', dbid)
    FROM gp_segment_configuration WHERE role='p' AND content=-1;
2: ALTER SYSTEM RESET gp_dtx_recovery_interval;
2: SELECT pg_reload_conf();
