CREATE OR REPLACE TYPE BODY "DBUG_OBJ_T" 
is

constructor function dbug_obj_t(self in out nocopy dbug_obj_t)
return self as result
is
  l_object_name constant std_objects.object_name%type := 'DBUG';
  l_std_object std_object;
begin
  begin
    std_object_mgr.get_std_object(l_object_name, l_std_object);
    self := treat(l_std_object as dbug_obj_t);
    self.dirty := 0;
  exception
    when no_data_found
    then
      /* std_object fields */
      dirty := 1;

      active_str_tab := sys.odcivarchar2list();
      active_num_tab := sys.odcinumberlist();
      indent_level := 0;
      call_tab := dbug_call_tab_t();
      dbug_level := dbug.c_level_default; -- default level
      break_point_level_str_tab :=
        sys.odcivarchar2list
        ( dbug."debug"
        , dbug."error"
        , dbug."fatal"
        , dbug."info"
        , dbug."input"
        , dbug."output"
        , dbug."trace"
        , dbug."warning"
        );
      break_point_level_num_tab :=
        sys.odcinumberlist
        ( dbug.c_level_debug
        , dbug.c_level_error
        , dbug.c_level_fatal
        , dbug.c_level_info
        , dbug.c_level_debug
        , dbug.c_level_debug
        , dbug.c_level_debug
        , dbug.c_level_warning
        );
      ignore_buffer_overflow := 0; -- false
  end;

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

  function to_json_array(p_str_tab in sys.odcivarchar2list)
  return json_array_t
  is
  begin
    l_json_array := json_array_t();
    if p_str_tab.count > 0
    then
      for i_idx in p_str_tab.first .. p_str_tab.last
      loop
        l_json_array.append(p_str_tab(i_idx));
      end loop;
    end if;
    return l_json_array;
  end to_json_array;

  function to_json_array(p_num_tab in sys.odcinumberlist)
  return json_array_t
  is
  begin
    l_json_array := json_array_t();
    if p_num_tab.count > 0
    then
      for i_idx in p_num_tab.first .. p_num_tab.last
      loop
        l_json_array.append(p_num_tab(i_idx));
      end loop;
    end if;
    return l_json_array;
  end to_json_array;

  function to_json_array(p_dbug_call_tab in dbug_call_tab_t)
  return json_array_t
  is
    l_json_object json_object_t;
  begin
    l_json_array := json_array_t();
    if p_dbug_call_tab.count > 0
    then
      for i_idx in p_dbug_call_tab.first .. p_dbug_call_tab.last
      loop
        l_json_object := json_object_t();

        l_json_object.put('MODULE_NAME', p_dbug_call_tab(i_idx).module_name);
        l_json_object.put('CALLED_FROM', p_dbug_call_tab(i_idx).called_from);
        l_json_object.put('OTHER_CALLS', p_dbug_call_tab(i_idx).module_name);

        l_json_array.append(l_json_object);
      end loop;
    end if;
    return l_json_array;
  end to_json_array;
begin
  (self as std_object).serialize(p_json_object); -- Generalized invocation

  p_json_object.put('ACTIVE_STR_TAB', to_json_array(active_str_tab));
  p_json_object.put('ACTIVE_NUM_TAB', to_json_array(active_num_tab));
  p_json_object.put('INDENT_LEVEL', indent_level);
  p_json_object.put('CALL_TAB', to_json_array(call_tab));
  p_json_object.put('DBUG_LEVEL', dbug_level);
  p_json_object.put('BREAK_POINT_LEVEL_STR_TAB', to_json_array(break_point_level_str_tab));
  p_json_object.put('BREAK_POINT_LEVEL_NUM_TAB', to_json_array(break_point_level_num_tab));
  p_json_object.put('IGNORE_BUFFER_OVERFLOW', ignore_buffer_overflow);
end serialize;

end;
/

