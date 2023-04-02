CREATE OR REPLACE PACKAGE "UT_DBUG" AUTHID DEFINER IS

-- A separate package to test dbug.enter / dbug.leave.
-- Since those routines test whether the enter / leave comes from outdide the DBUG package,
-- you can not test them inside DBUG so that's why UT_DBUG.

c_testing constant boolean := $if $$Testing $then true $else false $end;

-- start of help test procedures coming from plsdbug
procedure leave
( p_testcase in positiven
);

procedure ut_leave
( p_dbug_method in dbug.method_t
, p_plsdbug_options in varchar2 default null
);

procedure ut_benchmark
( p_count in positiven
, p_dbug_method in dbug.method_t
, p_plsdbug_options in varchar2 default null
);

procedure ut_factorial
( p_dbug_method in dbug.method_t
, p_plsdbug_options in varchar2 default null
);

-- end of help test procedures coming from plsdbug

procedure ut_run;

--%suitepath(DBUG)
--%suite
--%rollback(manual)

--%beforeeach
procedure ut_setup;

--%aftereach
procedure ut_teardown;

--%test
procedure ut_dbug;

--%test
procedure ut_leave_on_error;

--%test
procedure ut_leave_dbms_output;

--%test
procedure ut_leave_log4plsql;

--%test
procedure ut_benchmark_dbms_output;

--%test
procedure ut_benchmark_log4plsql;

--%test
procedure ut_factorial_dbms_output;

--%test
procedure ut_factorial_log4plsql;

end ut_dbug;
/

