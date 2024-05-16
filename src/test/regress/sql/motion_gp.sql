CREATE TABLE motiondata (
  id int,
  plain text,     -- inline, uncompressed
  main text,      --inline, compressible
  external text,  -- external, uncompressed
  extended text); -- external, compressible

ALTER TABLE motiondata ALTER COLUMN plain SET STORAGE plain;
ALTER TABLE motiondata ALTER COLUMN main SET STORAGE main;
ALTER TABLE motiondata ALTER COLUMN external SET STORAGE external;
ALTER TABLE motiondata ALTER COLUMN extended SET STORAGE extended;

-- a simple small tuple.
INSERT INTO motiondata (id, plain, main, external, extended) VALUES (1, 'foo', 'bar', 'baz', 'foobar');

-- Large datum, inline uncompressed
INSERT INTO motiondata (id, plain) VALUES (2, repeat('1234567890', 1000));

-- Large datum, inline compressed
INSERT INTO motiondata (id, main)  VALUES (3, repeat('1234567890', 1000));

-- Large datum, inline compressed, but doesn't fit in a short varlen even
-- after compression
INSERT INTO motiondata (id, main)  VALUES (4, repeat('1234567890', 2000));

-- Large datum, external uncompressed
INSERT INTO motiondata (id, external) VALUES (5, repeat('1234567890', 1000));

-- Large datum, external, compressed
INSERT INTO motiondata (id, extended) VALUES (6, repeat('1234567890', 100000));

-- Check that the sizes are as expected. The exact sizes are not important,
-- but should be in the right ballpark.
SELECT id,
       pg_column_size(plain) AS plain_sz,
       pg_column_size(main) AS main_sz,
       pg_column_size(external) AS external_sz,
       pg_column_size(extended) AS extended_sz
FROM motiondata;

CREATE TABLE motiondata_ao WITH (appendonly=true) AS SELECT * from motiondata;

-- A helper function for printing an abbreviated version of a long datum. Otherwise, the output
-- of selecting the large datums become unwieldly.
create or replace function abbreviate(t text) returns text as $$
begin
  if length(t) <= 15 then
    return length(t) || ': ' || t;
  else
    return length(t) || ': ' || substring(t from 1 for 5) || '...' || substring(t from length(t)-4 for 5);
  end if;
end;
$$ language plpgsql;

-- Runs query 'sql', and prints an abbreviated result set.
--
-- Note: It's important that we run the query as it is, and abbreviate the
-- resulting values afterwards. If we put the abbreviate() function calls into
-- the query itself, then they will be evaluated in the QEs, and the original
-- large datums are not sent through the Motion at all. Since we're trying to
-- test the Motion tuple serialization code, that would defeat the purpose.
create or replace function abbreviate_result(sql text) returns setof motiondata
as $$
declare
  rec motiondata%rowtype;
begin
  for rec in EXECUTE sql
  loop
     rec.plain = abbreviate(rec.plain);
     rec.main = abbreviate(rec.main);
     rec.external = abbreviate(rec.external);
     rec.extended = abbreviate(rec.extended);
     RETURN NEXT rec ;
  end loop;
end;
$$ language plpgsql;

-- This exercises the codepath where the HeapTuple is sent over the wire as is, if it
-- doesn't contain toasted datums.
select * from abbreviate_result($$
  select id, plain, main, external, extended from motiondata
$$) order by id;

-- Because of the 'id + 0' expression, the Seq Scan node has to project,
-- and passes a virtual slot to the Motion.
select * from abbreviate_result($$
  select id + 0 as id, plain, main, external, extended from motiondata
$$) order by id;

-- Here, the Motion gets an already-built MemTuple from the Seq Scan, because it's
-- an AO table.
select * from abbreviate_result($$
  select id, plain, main, external, extended from motiondata_ao
$$) order by id;

-- Test with a table with zero columns. Motion tuple serialization has a special
-- codepath for zero-attribute tuples.
CREATE TABLE motion_noatts ();
INSERT INTO motion_noatts SELECT;
SELECT * FROM motion_noatts;
