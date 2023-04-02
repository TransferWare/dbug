CREATE OR REPLACE PACKAGE "UT_DBUG" AUTHID DEFINER IS

-- A separate package to test dbug.enter / dbug.leave.
-- Since those routines test whether the enter / leave comes from outdide the DBUG package,
-- you can not test them inside DBUG so that's why UT_DBUG.

c_testing constant boolean := $if $$Testing $then true $else false $end;

--%suitepath(DBUG)
--%suite
--%rollback(manual)

procedure leave
( p_testcase in positiven
);

--beforeeach
procedure ut_setup;

--aftereach
procedure ut_teardown;

--%test
procedure ut_dbug;

procedure ut_run;

--%test
procedure ut_leave_on_error;

-- tests coming from plsdbug
procedure ut_leave
( p_dbug_method in dbug.method_t
, p_dbug_options in varchar2 default null
);

--%test
procedure ut_leave_dbms_output;

--%test
procedure ut_leave_log4plsql;

end ut_dbug;
/

