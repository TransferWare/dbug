CREATE OR REPLACE PACKAGE "DBUG_PROFILER" AUTHID DEFINER AS

/**

This package is **ONLY** invoked by the DBUG package when DBUG.ACTIVATE('PROFILER') is issued.

It is meant to add some rudimentary profiling to your application.

The time elapsed is determined by starting (DBUG.ENTER that invokes DBUG_PROFILER.ENTER) and
stopping (DBUG.LEAVE that invokes DBUG_PROFILER.LEAVE) a routine, like this procedure P1:

```
PROCEDURE P1
IS
BEGIN
  DBUG.ENTER($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT_OWNER);
  <do your stuff>
  DBUG.LEAVE;
EXCEPTION
  WHEN OTHERS
  THEN
    DBUG.LEAVE_ON_ERROR;
    RAISE;
END P;
```

When a routine P1 is invoked (with DBUG.ENTER and DBUG.LEAVE at the begin and end of the routine) and
another routine P2 is invoked (also with DBUG.ENTER/DBUG.LEAVE at the begin and end):
- the time elapsed for P2 is not counted for P1 because the P1 timer stops when P2 is invoked (in DBUG_PROFILER.ENTER)
- the P1 timer restarts when P2 stops (in DBUG_PROFILER.LEAVE)

There are two use cases:
1. activate the profiler in a current session.
2. feed the profiler with information from other sessions by issuing dbug_profiler.enter(<module>, <timestamp>)
   and dbug_profiler.leave(<timestamp>) at the appropriate places.

In both cases you can use "select * from table(dbug_profiler.show)" to have the profiling details.

Issues:
- https://github.com/TransferWare/dbug/issues/10 - It must be possible to profile based on other logging modules than DBUG_PROFILER.

**/

c_testing constant boolean := $if $$Testing $then true $else false $end;

-- SYSTIMESTAMP
subtype t_timestamp is timestamp(6); /** the type for UTC timestamps (having no problems with Winter and Summer time) **/

type t_profiler_rec is record (
  /* see dbugrpt */
  module_name dbug.module_name_t -- varchar2(4000)
, nr_calls integer
--  perc_calls number
, elapsed_time number
--  perc_time number
, avg_time number
--, min_time number
--, max_time number
--, weight integer
);

/** The profiler info. **/

type t_profiler_tab is table of t_profiler_rec;

/** The table of profiler info. */

procedure enter(
  p_module in dbug.module_name_t -- the module entered
, p_timestamp in t_timestamp default sys_extract_utc(systimestamp) -- the timestamp (can be from other sources)
);

/** The enter routine invoked by dbug.enter. **/

procedure leave
( p_timestamp in t_timestamp default sys_extract_utc(systimestamp) -- https://github.com/TransferWare/dbug/issues/10
);

/** The leave routine invoked by dbug.leave. **/

procedure done;

/** The done routine invoked by dbug.done: profiling cache is cleared.  **/

function show
return t_profiler_tab pipelined;

/** Show the profiling information as a pipelined function. Idempotent function. */

procedure show;

/** Show the profiling information via DBMS_OUTPUT. Idempotent procedure. */

-- necessary functions for the dbug interface but they do nothing
procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2
);

/** The print routine invoked by dbug.print. **/

procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2,
  p_arg2 in varchar2
);

/** The print routine invoked by dbug.print. **/

procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2,
  p_arg2 in varchar2,
  p_arg3 in varchar2
);

/** The print routine invoked by dbug.print. **/

procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2,
  p_arg2 in varchar2,
  p_arg3 in varchar2,
  p_arg4 in varchar2
);

/** The print routine invoked by dbug.print. **/

procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2,
  p_arg2 in varchar2,
  p_arg3 in varchar2,
  p_arg4 in varchar2,
  p_arg5 in varchar2
);

/** The print routine invoked by dbug.print. **/

-- test functions

--%suitepath(DBUG)
--%suite

--%beforeeach
procedure ut_setup;

--%aftereach
procedure ut_teardown;

--%test
procedure ut_test;

end dbug_profiler;
/

