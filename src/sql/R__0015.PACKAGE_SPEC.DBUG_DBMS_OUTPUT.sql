CREATE OR REPLACE PACKAGE "DBUG_DBMS_OUTPUT" AUTHID DEFINER IS

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

$if ut_dbug.c_testing $then

  --%suitepath(DBUG)
  --%suite

  --%beforeeach
  procedure ut_setup;

  --%aftereach
  procedure ut_teardown;

  --%test
  procedure ut_store_remove;

  --%test
  procedure ut_dbug_dbms_output;

  --%test
  procedure ut_set_ignore_buffer_overflow;

  --%test
  procedure ut_ignore_buffer_overflow;
  
$end

end dbug_dbms_output;
/

