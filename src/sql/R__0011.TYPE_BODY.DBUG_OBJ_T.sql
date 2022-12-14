CREATE OR REPLACE TYPE BODY "DBUG_OBJ_T" 
is

constructor function dbug_obj_t(self in out nocopy dbug_obj_t)
return self as result
is
  l_object_name constant std_objects.object_name%type := 'DBUG';
begin
  begin
    std_object_mgr.get_std_object(l_object_name, self);
  exception
    when no_data_found
    then
      self := dbug_obj_t
              ( 0
              , sys.odcivarchar2list()
              , sys.odcinumberlist()
              , 0
              , dbug_call_tab_t()
              , dbug.c_level_default
              , sys.odcivarchar2list
                ( dbug."debug"
                , dbug."error"
                , dbug."fatal"
                , dbug."info"
                , dbug."input"
                , dbug."output"
                , dbug."trace"
                , dbug."warning"
                )
              , sys.odcinumberlist
                ( dbug.c_level_debug
                , dbug.c_level_error
                , dbug.c_level_fatal
                , dbug.c_level_info
                , dbug.c_level_debug
                , dbug.c_level_debug
                , dbug.c_level_debug
                , dbug.c_level_warning
                )
              , 0
              );

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

overriding member function name(self in dbug_obj_t)
return varchar2
is
begin
  return 'DBUG';
end name;

overriding member procedure serialize(self in dbug_obj_t, p_json_object in out nocopy json_object_t)
is
  l_json_array json_array_t;

  procedure to_json_array(p_attribute in varchar2, p_str_tab in sys.odcivarchar2list)
  is
  begin
    if p_str_tab is not null and p_str_tab.count > 0
    then
      l_json_array := json_array_t();
      for i_idx in p_str_tab.first .. p_str_tab.last
      loop
        l_json_array.append(p_str_tab(i_idx));
      end loop;
      p_json_object.put(p_attribute, l_json_array);
    end if;
  end to_json_array;

  procedure to_json_array(p_attribute in varchar2, p_num_tab in sys.odcinumberlist)
  is
  begin
    if p_num_tab is not null and p_num_tab.count > 0
    then
      l_json_array := json_array_t();
      for i_idx in p_num_tab.first .. p_num_tab.last
      loop
        l_json_array.append(p_num_tab(i_idx));
      end loop;
      p_json_object.put(p_attribute, l_json_array);
    end if;
  end to_json_array;

  procedure to_json_array(p_attribute in varchar2, p_dbug_call_tab in dbug_call_tab_t)
  is
    l_json_object json_object_t;
  begin
    if p_dbug_call_tab is not null and p_dbug_call_tab.count > 0
    then
      l_json_array := json_array_t();
      for i_idx in p_dbug_call_tab.first .. p_dbug_call_tab.last
      loop
        l_json_object := json_object_t();

        l_json_object.put('MODULE_NAME', p_dbug_call_tab(i_idx).module_name);
        l_json_object.put('CALLED_FROM', p_dbug_call_tab(i_idx).called_from);
        l_json_object.put('OTHER_CALLS', p_dbug_call_tab(i_idx).module_name);

        l_json_array.append(l_json_object);
      end loop;
      p_json_object.put(p_attribute, l_json_array);
    end if;
  end to_json_array;
begin
  (self as std_object).serialize(p_json_object); -- Generalized invocation

  to_json_array('ACTIVE_STR_TAB', active_str_tab);
  to_json_array('ACTIVE_NUM_TAB', active_num_tab);
  p_json_object.put('INDENT_LEVEL', indent_level);
  to_json_array('CALL_TAB', call_tab);
  p_json_object.put('DBUG_LEVEL', dbug_level);
  to_json_array('BREAK_POINT_LEVEL_STR_TAB', break_point_level_str_tab);
  to_json_array('BREAK_POINT_LEVEL_NUM_TAB', break_point_level_num_tab);
  p_json_object.put('IGNORE_BUFFER_OVERFLOW', ignore_buffer_overflow);
end serialize;

end;
/

