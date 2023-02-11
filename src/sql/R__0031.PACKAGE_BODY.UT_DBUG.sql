CREATE OR REPLACE PACKAGE BODY "UT_DBUG" IS

procedure PROC
is
  procedure NESTED_PROC
  is
    i integer;
  begin
    dbug.enter;

    i := 42/0;

    dbug.leave;
  exception
    when others
    then
      dbug.on_error;
      raise;
  end NESTED_PROC;
begin
  dbug.enter;
  NESTED_PROC;
  dbug.leave;
end PROC;

procedure ut_run
is
begin
  dbug.enter;
  PROC;
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
end ut_run;

END UT_DBUG;
/

