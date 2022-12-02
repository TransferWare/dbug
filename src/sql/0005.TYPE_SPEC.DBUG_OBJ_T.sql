CREATE TYPE "DBUG_OBJ_T" AUTHID DEFINER under std_object (
  active_str_tab sys.odcivarchar2list
, active_num_tab sys.odcinumberlist
, indent_level integer
, call_tab dbug_call_tab_t
, dbug_level integer
, break_point_level_str_tab sys.odcivarchar2list
, break_point_level_num_tab sys.odcinumberlist
, ignore_buffer_overflow integer

, constructor function dbug_obj_t(self in out nocopy dbug_obj_t)
  return self as result

, overriding member function name(self in dbug_obj_t)
  return varchar2

  -- every sub type must add its attributes (in capital letters)
, member procedure serialize(self in dbug_obj_t, p_json_object in out nocopy json_object_t)

) final;
/

