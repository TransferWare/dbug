CREATE OR REPLACE TYPE BODY "DBUG_LOG4PLSQL_OBJ_T" 
is

constructor function dbug_log4plsql_obj_t(self in out nocopy dbug_log4plsql_obj_t)
return self as result
is
  l_object_name constant std_objects.object_name%type := 'DBUG_LOG4PLSQL';

  l_log_ctx plogparam.log_ctx;

  function bool2int(p_bool in boolean)
  return integer
  is
  begin
    return case p_bool when true then 1 when false then 0 else null end;
  end bool2int;
begin
  begin
    std_object_mgr.get_std_object(l_object_name, self);
  exception
    when no_data_found
    then
      l_log_ctx := plog.init;

      self := dbug_log4plsql_obj_t
              ( 0 -- dirty
              , null
              , null
              , null
              , null
              , bool2int(l_log_ctx.isdefaultinit)
              , l_log_ctx.llevel
              , l_log_ctx.lsection
              , l_log_ctx.ltext
              , bool2int(l_log_ctx.use_log4j)
              , bool2int(l_log_ctx.use_out_trans)
              , bool2int(l_log_ctx.use_logtable)
              , bool2int(l_log_ctx.use_alert)
              , bool2int(l_log_ctx.use_trace)
              , bool2int(l_log_ctx.use_dbms_output)
              , l_log_ctx.init_lsection
              , l_log_ctx.init_llevel
              , l_log_ctx.dbms_output_wrap
              );
      self.set_session_attributes();

      -- make it a singleton by storing it
      std_object_mgr.set_std_object(l_object_name, self);
  end;

  if self.dirty = 0
  then
    null; -- ok
  else
    raise program_error;
  end if;

  -- essential
  return;
end;

overriding member function name(self in dbug_log4plsql_obj_t)
return varchar2
is
begin
  return 'DBUG_LOG4PLSQL';
end name;

overriding member procedure serialize(self in dbug_log4plsql_obj_t, p_json_object in out nocopy json_object_t)
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

