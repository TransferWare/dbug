CREATE OR REPLACE TYPE BODY "DBUG_LOG4PLSQL_OBJ_T" 
is

constructor function dbug_log4plsql_obj_t(self in out nocopy dbug_log4plsql_obj_t)
return self as result
is
  l_object_name constant std_objects.object_name%type := 'DBUG_LOG4PLSQL';
  l_std_object std_object;
begin
  std_object_mgr.get_std_object(l_object_name, l_std_object);
  self := treat(l_std_object as dbug_log4plsql_obj_t);
  -- do not set dirty, since we do not verify changes

  -- essential
  return;
end;

overriding member function name(self in dbug_log4plsql_obj_t)
return varchar2
is
begin
  return 'DBUG_LOG4PLSQL';
end name;

member procedure serialize(self in std_object, p_json_object in out nocopy json_object_t)
is
begin
  -- every sub type must first start with (self as <super type>).serialize(p_json_object)
  (self as std_object).serialize(p_json_object);

  p_json_object.put('ISDEFAULTINIT', isdefaultinit);
  p_json_object.put('LLEVEL', llevel);
  p_json_object.put('LSECTION', lsection);
  p_json_object.put('LTEXT', ltext);
  p_json_object.put('USE_LOG4J', use_log4j);
  p_json_object.put('USE_OUT_TRANS', use_out_trans);
  p_json_object.put('USE_LOGTABLE', use_logtable);
  p_json_object.put('USE_ALERT', use_alert);
  p_json_object.put('USE_TRACE', use_trace);
  p_json_object.put('USE_DBMS_OUTPUT', use_dbms_output);
  p_json_object.put('INIT_LSECTION', init_lsection);
  p_json_object.put('INIT_LLEVEL', init_llevel);
  p_json_object.put('DBMS_OUTPUT_WRAP', dbms_output_wrap);
end serialize;

end;
/

