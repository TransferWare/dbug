CREATE OR REPLACE TYPE BODY "STD_OBJECT" 
is

final
member procedure store(self in std_object)
is
begin
  std_object_mgr.set_std_object(name(), self);
end store;

final
member procedure remove(self in std_object)
is
begin
  std_object_mgr.del_std_object(name());
end remove;

member procedure print(self in std_object)
is
begin
  dbms_output.put_line
  ( utl_lms.format_message
    ( '%s.%s.%s; name: %s; dirty: %s'
    , $$PLSQL_UNIT_OWNER
    , $$PLSQL_UNIT
    , 'PRINT'
    , name()
    , to_char(dirty)
    )
  );
end print;

end;
/

