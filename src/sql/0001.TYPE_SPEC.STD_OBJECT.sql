CREATE TYPE "STD_OBJECT" AUTHID DEFINER AS OBJECT (
  /*
  -- The dirty flag is used to speed up the performance when
  -- std_object_mgr.get_std_object()/std_object_mgr.set_std_object() are used.
  --
  -- These functions use an internal (PL/SQL package) or external (database table) cache
  -- to get or set an object.
  --
  -- There are two situations when std_object_mgr.get_std_object() is called in a
  -- constructor of a type depending on std_object:
  -- 1) std_object_mgr.get_std_object() raises no_data_found (no object found).
  -- Now the application should invoke std_object_mgr.set_std_object().
  -- 2) std_object_mgr.get_std_object() succeeds.
  -- The dirty flag is set to 0 automatically by
  -- std_object_mgr.get_std_object() and std_object_mgr.set_std_object().
  -- In the rest of the application the dirty flag should be set it to 1 if
  -- one of the members of the object changes.
  -- Now std_object_mgr.set_std_object() will write the object back to the cache.
  */
  dirty integer

, not instantiable
  member function name(self in std_object)
  return varchar2

, final
  member procedure store(self in out nocopy std_object)

, final
  member procedure remove(self in std_object)

, static
  function deserialize(p_obj_type in varchar2, p_obj in clob)
  return std_object

, final
  member function get_type(self in std_object)
  return varchar2

, final
  member function serialize(self in std_object)
  return clob

  -- every sub type must add its attributes (in capital letters)
, member procedure serialize(self in std_object, p_json_object in out nocopy json_object_t)

  -- this one just calls serialize() but maybe you want another representation, i.e. pretty print the object
, member function repr(self in std_object)
  return clob

, final
  member procedure print(self in std_object)

, order member function compare(p_other in std_object)
  return integer

) not instantiable not final;
/

