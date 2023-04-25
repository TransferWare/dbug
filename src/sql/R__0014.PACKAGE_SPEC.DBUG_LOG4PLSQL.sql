CREATE OR REPLACE PACKAGE "DBUG_LOG4PLSQL" AUTHID DEFINER IS

  c_testing constant boolean := $if $$Testing $then true $else false $end;

  procedure done;

  procedure enter(
    p_module in dbug.module_name_t
  );

  procedure leave;

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2
  );

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2,
    p_arg2 in varchar2
  );

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2,
    p_arg2 in varchar2,
    p_arg3 in varchar2
  );

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2,
    p_arg2 in varchar2,
    p_arg3 in varchar2,
    p_arg4 in varchar2
  );

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2,
    p_arg2 in varchar2,
    p_arg3 in varchar2,
    p_arg4 in varchar2,
    p_arg5 in varchar2
  );


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

