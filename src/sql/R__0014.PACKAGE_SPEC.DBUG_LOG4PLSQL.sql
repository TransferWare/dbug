CREATE OR REPLACE PACKAGE "DBUG_LOG4PLSQL" AUTHID DEFINER IS

/**

This package is **ONLY** invoked by the DBUG package when DBUG.ACTIVATE('LOG4PLSQL') is issued.

It is meant to log to package PLOG that by default logs to table TLOG.

**/

c_testing constant boolean := $if $$Testing $then true $else false $end;

procedure done;

procedure enter(
  p_module in dbug.module_name_t
);

/** The enter routine invoked by dbug.enter. **/

procedure leave;

/** The leave routine invoked by dbug.leave. **/

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

procedure feed_profiler(
  p_session in tlog.lsession%type default oracle_tools.data_session_id -- The session for which to feed profiling info. Defaults to current session.
);

/**

Feed the DBUG_PROFILER package with profiling information so you can have profiling info not only from the current session.
The table TLOG will be searched for but only for LDATE < SYSDATE (history).

When p_session is null, the last LSESSION in TLOG will be used with LDATE < SYSDATE.

**/

--%suitepath(DBUG)
--%suite

--%beforeeach
procedure ut_setup;

--%aftereach
procedure ut_teardown;

--%test
procedure ut_store_remove;

--%test
procedure ut_dbug_log4plsql;

end dbug_log4plsql;
/

