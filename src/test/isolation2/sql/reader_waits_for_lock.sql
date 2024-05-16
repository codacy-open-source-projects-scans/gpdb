-- This test validates that a reader process waits if lock is not
-- available.  There used to be a bug where reader didn't wait even if
-- lock was held by some other session.

-- setup
CREATE or REPLACE FUNCTION check_readers_are_blocked ()
RETURNS bool AS
$$
declare
retries int; /* in func */
begin
  retries := 1200; /* in func */
  loop
    if (SELECT count(*) > 0 as reader_waits from
        pg_locks l join pg_stat_activity a on a.pid = l.pid
    	and a.query like '%reader_waits_for_lock_table%'
	and not a.pid = pg_backend_pid()
	and l.granted = false and l.mppiswriter = false) then
      return true; /* in func */
    end if; /* in func */
    if retries <= 0 then
      return false; /* in func */
    end if; /* in func */
    perform pg_sleep(0.1); /* in func */
    perform pg_stat_clear_snapshot(); /* in func */
    retries := retries - 1; /* in func */
  end loop; /* in func */
end; /* in func */
$$ language plpgsql;
1: create table reader_waits_for_lock_table(a int, b int) distributed by (a);
1: insert into reader_waits_for_lock_table select 1, 1;

-- Aquire a conflicting lock in utility mode on seg0.
0U: BEGIN;
0U: LOCK reader_waits_for_lock_table IN ACCESS EXCLUSIVE MODE;
-- A utility mode connection should not have valid gp_session_id, else
-- locks aquired by it may not confict with locks requested by a
-- normal mode backend.
0U: show gp_session_id;
-- Run the same query involving at least one reader gang.  It should
-- block this time.
1&: SELECT t1.* FROM reader_waits_for_lock_table t1 INNER JOIN reader_waits_for_lock_table t2 ON t1.b = t2.b;
-- At least one reader process from session 1 should be blocked on
-- AccessExclusiveLock held by 0U.  That distinct is needed because
-- plans for above select query differ between Orca and planner.
-- Planner generates three slices such that the two reader backends
-- are blocked for the lock.  Orca generates two slices such that the
-- reader and as well as the writer are blocked.  We get two rows (due
-- to "mppwriter=false" predicate) with planner and one row with Orca.
0U: select check_readers_are_blocked();
0U: select distinct relation::regclass, mode, query
    from pg_locks l join pg_stat_activity a on a.pid = l.pid
    and a.query like '%reader_waits_for_lock_table%'
    and not a.pid = pg_backend_pid()
    and l.granted = false and l.mppiswriter = false;
0U: COMMIT;
1<:
