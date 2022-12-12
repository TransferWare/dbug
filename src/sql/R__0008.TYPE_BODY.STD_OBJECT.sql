CREATE OR REPLACE TYPE BODY "STD_OBJECT" 
is

final
member procedure store(self in std_object)
is
begin
$if std_object_mgr.c_debugging $then
  dbms_output.put_line
  ( utl_lms.format_message
    ( '[%s.%s] name(): %s'
    , $$PLSQL_UNIT
    , 'STORE'
    , name()
    )
  );
$end
  std_object_mgr.set_std_object(name(), self);
end store;

final
member procedure remove(self in std_object)
is
begin
$if std_object_mgr.c_debugging $then
  dbms_output.put_line
  ( utl_lms.format_message
    ( '[%s.%s] name(): %s'
    , $$PLSQL_UNIT
    , 'REMOVE'
    , name()
    )
  );
$end
  std_object_mgr.del_std_object(name());
end remove;

static
function deserialize(p_obj_type in varchar2, p_obj in clob)
return std_object
is
  l_cursor sys_refcursor;
  l_std_object std_object;
begin
  open l_cursor
    for q'[select json_value(:obj, '$' returning ]' || p_obj_type || q'[) from dual]'
    using p_obj;
  fetch l_cursor into l_std_object;
  if l_cursor%notfound
  then
    close l_cursor;
    raise no_data_found;
  else
    close l_cursor;
  end if;
  return l_std_object;
end deserialize;

final
member function get_type(self in std_object)
return varchar2
is
begin
  return sys.anydata.getTypeName(sys.anydata.convertObject(self));
end get_type;

final
member function serialize(self in std_object)
return clob
is
  l_json_object json_object_t := json_object_t();
begin
  serialize(l_json_object);

  return l_json_object.to_clob();
end serialize;

member procedure serialize(self in std_object, p_json_object in out nocopy json_object_t)
is
begin
  -- every sub type must first start with (self as <super type>).serialize(p_json_object)
  p_json_object.put('DIRTY', dirty);
end serialize;

member function repr(self in std_object)
return clob
is
  l_clob clob := serialize();
begin
  select  json_serialize(l_clob returning clob pretty)
  into    l_clob
  from    dual;

  return l_clob;
end repr;

final
member procedure print(self in std_object)
is
begin
  dbms_output.put_line
  ( utl_lms.format_message
    ( 'type: %s; repr: %s'
    , get_type()
    , repr()
    )
  );
end print;

order member function compare(p_other in std_object)
return integer
is
  l_one std_object := self;
begin
  l_one.dirty := p_other.dirty; -- ignore dirty
  return dbms_lob.compare(l_one.repr(), p_other.repr());
end compare;

end;
/

