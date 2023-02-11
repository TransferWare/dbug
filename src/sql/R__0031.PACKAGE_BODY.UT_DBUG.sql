CREATE OR REPLACE PACKAGE BODY "UT_DBUG" IS

procedure PROC
is
  procedure NESTED_PROC
  is
    i integer;
  begin
    dbug2.enter;

    i := 42/0;

    dbug2.leave;
  exception
    when others
    then
      dbug2.on_error;
      raise;
  end NESTED_PROC;
begin
  dbug2.enter;
  NESTED_PROC;
  dbug2.leave;
end PROC;

procedure ut_run
is
begin
  dbug2.enter;
  PROC;
  dbug2.leave;
exception
  when others
  then
    dbug2.leave_on_error;
    raise;
end ut_run;

END UT_DBUG;
/

