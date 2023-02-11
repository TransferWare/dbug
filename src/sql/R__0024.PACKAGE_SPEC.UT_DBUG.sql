CREATE OR REPLACE PACKAGE "UT_DBUG" AUTHID DEFINER IS

-- A separate package to test dbug.enter / dbug.leave.
-- Since those routines test whether the enter / leave comes from outdide the DBUG package,
-- you can not test them inside DBUG so that's why UT_DBUG.

c_testing constant boolean := $if $$Testing $then true $else false $end;

--%suitepath(DBUG)
--%suite
--%rollback(manual)

--%beforeall
procedure ut_setup;

--%afterall
procedure ut_teardown;

--%test
procedure ut_dbug;

procedure ut_run;

--%test
procedure ut_leave_on_error;

end ut_dbug;
/

