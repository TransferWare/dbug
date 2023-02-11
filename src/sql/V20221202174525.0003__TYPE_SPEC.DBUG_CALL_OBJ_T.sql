CREATE TYPE "DBUG_CALL_OBJ_T" AUTHID DEFINER IS OBJECT (
  module_name varchar2(4000)
, depth integer  
, called_from varchar2(4000) -- the location from which this module is called (initially null)
);
/

