CREATE TYPE "DBUG_LOG4PLSQL_OBJ_T" AUTHID DEFINER under std_object (
  isdefaultinit integer
, llevel number
, lsection varchar2(2000)
, ltext varchar2(2000)
, use_log4j integer
, use_out_trans integer
, use_logtable integer
, use_alert integer
, use_trace integer
, use_dbms_output integer
, init_lsection varchar2(2000)
, init_llevel number
, dbms_output_wrap integer

, constructor function dbug_log4plsql_obj_t(self in out nocopy dbug_log4plsql_obj_t)
  return self as result

, overriding member function name(self in dbug_log4plsql_obj_t)
  return varchar2

  -- every sub type must add its attributes (in capital letters)
, overriding member procedure serialize(self in dbug_log4plsql_obj_t, p_json_object in out nocopy json_object_t)

) final;
/

