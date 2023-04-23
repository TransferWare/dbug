CREATE OR REPLACE TYPE BODY "STD_OBJECT" 
is

member procedure set_session_attributes
( self in out nocopy std_object
)
is
begin
  self.db_session := dbms_session.unique_session_id;
  self.db_username := 'ORCL-' || sys_context('USERENV', 'SESSION_USER');
  self.app_session := case when sys_context('APEX$SESSION', 'APP_SESSION') is not null then sys_context('APEX$SESSION', 'APP_SESSION') end;
  self.app_username := case
                         when sys_context('APEX$SESSION', 'APP_USER') is not null
                         then 'APEX-' || sys_context('APEX$SESSION', 'APP_USER')
                         when sys_context('USERENV', 'CLIENT_IDENTIFIER') is not null
                         then 'CLNT-' || regexp_substr(sys_context('USERENV', 'CLIENT_IDENTIFIER'), '^[^:]*')
                       end;         
end set_session_attributes;

final member function get_session_attributes
( self in std_object
)
return varchar2
is
begin
  return self.db_session || '|' || self.db_username || '|' || self.app_session || '|' || self.app_username;
end get_session_attributes;

final member function belongs_to_same_session
( p_std_object in std_object
)
return integer
is
begin
  return case
           when self.get_session_attributes() = p_std_object.get_session_attributes()
           then 1
           else 0
         end;
end belongs_to_same_session;

final member function belongs_to_this_session
return integer
is
  l_std_object std_object := treat(self as std_object);
begin
  l_std_object.set_session_attributes();
  return self.belongs_to_same_session(l_std_object);
end belongs_to_this_session;

final
member procedure store(self in out nocopy std_object)
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
  std_object_mgr.del_std_object(null, name());
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
  p_json_object.put('DB_SESSION', db_session);
  p_json_object.put('DB_USERNAME', db_username);
  p_json_object.put('APP_SESSION', app_session);
  p_json_object.put('APP_USERNAME', app_username);
end serialize;

member function repr(self in std_object)
return clob
is
  l_clob clob := serialize();
begin
  select  json_serialize(l_clob returning clob pretty)
  into    l_clob
  from    dual;

  if dbms_lob.getlength(l_clob) > 0
  then
    null;
  else
    raise program_error;
  end if;

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
    , dbms_lob.substr(lob_loc => repr(), amount => 4000)
    )
  );
  /* GJP 2023-03-11 Sometimes it may be necessary to uncomment the next block for debugging DBUG. */ 
/*  
  raise program_error; -- where does it happen?
exception
  when others 
  then
    dbms_output.put_line( dbms_utility.FORMAT_ERROR_STACK );
    dbms_output.put_line( dbms_utility.format_error_backtrace );
    raise;
*/    
end print;

order member function compare(p_other in std_object)
return integer
is
  l_json_object_self json_object_t := json_object_t();
  l_json_object_other json_object_t := json_object_t();
  l_clob_self clob;
  l_clob_other clob;
  l_cmp pls_integer;
begin
  case
    when self.get_type() < p_other.get_type() then return -1;
    when self.get_type() > p_other.get_type() then return +1;
    else
      -- same type
      self.serialize(l_json_object_self);
      p_other.serialize(l_json_object_other);

      -- ignore dirty
      l_json_object_self.put_null('DIRTY');
      l_json_object_other.put_null('DIRTY');

      l_clob_self := l_json_object_self.to_clob();
      l_clob_other := l_json_object_other.to_clob();

      select  nvl(min(0), 1)
      into    l_cmp
      from    dual
      where   json_equal(l_clob_self, l_clob_other);

      return l_cmp;
  end case;
end compare;

end;
/

