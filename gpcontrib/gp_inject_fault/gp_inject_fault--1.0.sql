/* contrib/gp_fault_inject/gp_fault_inject--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION gp_fault_inject" to load this file. \quit

-- NOTE: we let some background process ignore all but a few faults (check checkBgProcessSkipFault()).
CREATE FUNCTION @extschema@.gp_inject_fault(
  faultname text,
  type text,
  ddl text,
  database text,
  tablename text,
  start_occurrence int4,
  end_occurrence int4,
  extra_arg int4,
  db_id int4,
  gp_session_id int4)
RETURNS text
AS 'MODULE_PATHNAME'
LANGUAGE C VOLATILE STRICT NO SQL;

-- Simpler version, without specific session id.
CREATE FUNCTION @extschema@.gp_inject_fault(
  faultname text,
  type text,
  ddl text,
  database text,
  tablename text,
  start_occurrence int4,
  end_occurrence int4,
  extra_arg int4,
  db_id int4)
RETURNS text
AS $$ select @extschema@.gp_inject_fault($1, $2, $3, $4, $5, $6, $7, $8, $9, -1) $$
LANGUAGE SQL;

-- Simpler version, trigger only one time, occurrence start at 1 and
-- end at 1, no sleep and no ddl/database/tablename/sessionid.
CREATE FUNCTION @extschema@.gp_inject_fault(
  faultname text,
  type text,
  db_id int4)
RETURNS text
AS $$ select @extschema@.gp_inject_fault($1, $2, '', '', '', 1, 1, 0, $3, -1) $$
LANGUAGE SQL;

-- Simpler version, trigger only one time, occurrence start at 1 and
-- end at 1, no sleep and no ddl/database/tablename.
CREATE FUNCTION @extschema@.gp_inject_fault(
  faultname text,
  type text,
  db_id int4,
  gp_session_id int4)
RETURNS text
AS $$ select @extschema@.gp_inject_fault($1, $2, '', '', '', 1, 1, 0, $3, $4) $$
LANGUAGE SQL;

-- Simpler version, always trigger until fault is reset.
CREATE FUNCTION @extschema@.gp_inject_fault_infinite(
  faultname text,
  type text,
  db_id int4)
RETURNS text
AS $$ select @extschema@.gp_inject_fault($1, $2, '', '', '', 1, -1, 0, $3, -1) $$
LANGUAGE SQL;

-- Simpler version to avoid confusion for wait_until_triggered fault.
-- occurrence in call below defines wait until number of times the
-- fault hits.
CREATE FUNCTION @extschema@.gp_wait_until_triggered_fault(
  faultname text,
  numtimestriggered int4,
  db_id int4)
RETURNS text
AS $$ select @extschema@.gp_inject_fault($1, 'wait_until_triggered', '', '', '', 1, 1, $2, $3, -1) $$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION @extschema@.insert_noop_xlog_record()
    RETURNS VOID
AS 'MODULE_PATHNAME',
'insert_noop_xlog_record'
LANGUAGE C;

-- Force a mirror to have applied as much XLOG as it's primary has shipped.
CREATE OR REPLACE FUNCTION @extschema@.force_mirrors_to_catch_up() RETURNS VOID AS $$
BEGIN
    -- Switch wal to have no-op record at far distance from
    -- previously emitted WAL record. This is required due to
    -- existing code behavior in startup and walreceiver process. If
    -- primary writes big (means spanning across multiple pages) WAL
    -- record, flushes only partial WAL record due to
    -- XLogBackgroundFlush() but restarts before commiting the
    -- transaction, mirror only receives partial record and waits to
    -- get complete record. Meanwhile after recover, no-op record gets
    -- written in place of that big record, startup process on mirror
    -- continues to wait to receive WAL beyond previously received
    -- point to proceed further. Hence, switch WAL as temporary
    -- workaround before writing no-op record to avoid this test from
    -- hanging sometimes in CI. Refer
    -- https://groups.google.com/a/greenplum.org/d/msg/gpdb-dev/vR7-LwpPsVs/zKmhIpJ3CAAJ

    PERFORM pg_switch_wal();
    PERFORM pg_switch_wal() from gp_dist_random('gp_id');

    PERFORM @extschema@.gp_inject_fault('after_xlog_redo_noop', 'sleep', dbid) FROM gp_segment_configuration WHERE role='m';
    PERFORM @extschema@.insert_noop_xlog_record();
    PERFORM @extschema@.insert_noop_xlog_record() from gp_dist_random('gp_id');
    PERFORM @extschema@.gp_wait_until_triggered_fault('after_xlog_redo_noop', 1, dbid) FROM gp_segment_configuration WHERE role='m';
    PERFORM @extschema@.gp_inject_fault('after_xlog_redo_noop', 'reset', dbid) FROM gp_segment_configuration WHERE role='m';
END;
$$ LANGUAGE plpgsql;
