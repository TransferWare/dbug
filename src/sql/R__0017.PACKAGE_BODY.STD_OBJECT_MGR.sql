CREATE OR REPLACE PACKAGE BODY "STD_OBJECT_MGR" IS

type std_object_tab_t is table of std_object index by object_name_t;
subtype session_info_t is varchar2(4000 char);
type session_std_object_tab_t is table of std_object_tab_t index by session_info_t;

g_escape constant varchar2(1) := chr(92); -- escape character

g_std_object_tab session_std_object_tab_t;

-- PRIVATE

function current_session_info
return session_info_t
is
begin
  return
    sys_context('USERENV', 'SESSIONID') ||
    '|' ||
    sys_context('USERENV', 'SESSION_USER') ||
    '|' ||
    sys_context('APEX$SESSION', 'APP_SESSION') ||
    '|' ||
    case
      when sys_context('APEX$SESSION', 'APP_USER') is not null
      then 'APEX-' || sys_context('APEX$SESSION', 'APP_USER')
      when sys_context('USERENV', 'CLIENT_IDENTIFIER') is not null
      then 'CLNT-' || regexp_substr(sys_context('USERENV', 'CLIENT_IDENTIFIER'), '^[^:]*')
    end;         
end current_session_info;

procedure get_std_object
( p_session_info in session_info_t
, p_object_name in object_name_t
, p_std_object out nocopy std_object
)
is
begin
  -- this may raise NO_DATA_FOUND as it should
  p_std_object := g_std_object_tab(p_session_info)(p_object_name);
  p_std_object.dirty := 0;

$if std_object_mgr.c_debugging $then
  dbms_output.put_line
  ( utl_lms.format_message
    ( '[%s.%s] p_session_info: %s; p_object_name: %s; p_std_object.dirty: %s'
    , $$PLSQL_UNIT
    , 'GET_STD_OBJECT'
    , p_session_info
    , p_object_name
    , to_char(p_std_object.dirty)
    )
  );
$end
end get_std_object;  

procedure set_std_object
( p_session_info in session_info_t
, p_object_name in object_name_t
, p_std_object in out nocopy std_object
)
is
  /* Store when:
  -- A) first when dirty equals 1
  -- B) then if the object is not stored yet
  */
  l_store boolean := case when p_std_object.dirty = 1 then true /* case A */ else null end;
  l_std_object std_object;
begin
  /*
  -- NOTE about dirty.
  --
  -- We start by setting dirty to 0 so a comparison with cache will not be different for dirty
  -- since the object stored will also have dirty equal to 0 due to this line.
  */
  p_std_object.dirty := 0;

  if l_store is null
  then
    -- retrieve the last version stored
    begin
      get_std_object
      ( p_session_info => p_session_info
      , p_object_name => p_object_name
      , p_std_object => l_std_object
      );
      l_store := false;
    exception
      when no_data_found
      then
        l_store := true; /* case B */
    end;
  end if;

$if std_object_mgr.c_debugging $then
  dbms_output.put_line
  ( utl_lms.format_message
    ( '[%s.%s] p_session_info: %s; p_object_name: %s; l_store: %s'
    , $$PLSQL_UNIT
    , 'SET_STD_OBJECT'
    , p_session_info
    , p_object_name
    , case l_store when true then 'TRUE' when false then 'FALSE' else 'NULL' end
    )
  );
$end

  if l_store
  then
    -- set package state
    g_std_object_tab(p_session_info)(p_object_name) := p_std_object;
  end if;
end set_std_object;

procedure delete_std_objects
( p_session_info in session_info_t
, p_object_name in object_name_t
)
is
  l_session_info constant session_info_t := current_session_info;
  l_object_name object_name_t;
  l_object_name_prev object_name_t;
begin
$if std_object_mgr.c_debugging $then
  dbms_output.put_line
  ( utl_lms.format_message
    ( '[%s.%s] p_session_info: %s; p_object_name: %s; objects exist: %s'
    , $$PLSQL_UNIT
    , 'DELETE_STD_OBJECTS'
    , p_session_info
    , p_object_name
    , case g_std_object_tab.exists(p_session_info) when true then 'TRUE' when false then 'FALSE' else 'NULL' end
    )
  );
$end

  if p_object_name is null
  then
    raise value_error;
  elsif g_std_object_tab.exists(p_session_info)
  then
    l_object_name := g_std_object_tab(p_session_info).first;
$if std_object_mgr.c_debugging $then
    dbms_output.put_line
    ( utl_lms.format_message
      ( '[%s.%s] first object name: %s'
      , $$PLSQL_UNIT
      , 'DELETE_STD_OBJECTS'
      , l_object_name
      )
    );
$end
    while l_object_name is not null
    loop
      /* a delete now may influence the next operation,
         so first do next and then maybe delete (the previous) */
      l_object_name_prev := l_object_name;
      l_object_name := g_std_object_tab(p_session_info).next(l_object_name);
$if std_object_mgr.c_debugging $then
      dbms_output.put_line
      ( utl_lms.format_message
        ( '[%s.%s] l_object_name_prev: %s; l_object_name: %s; l_object_name_prev like p_object_name escape g_escape: %s'
        , $$PLSQL_UNIT
        , 'DELETE_STD_OBJECTS'
        , l_object_name_prev
        , l_object_name
        , case l_object_name_prev like p_object_name when true then 'TRUE' when false then 'FALSE' else 'NULL' end
        )
      );
$end
      if l_object_name_prev like p_object_name escape g_escape
      then
        g_std_object_tab(p_session_info).delete(l_object_name_prev);
      end if;
    end loop;
    if g_std_object_tab(p_session_info).count = 0
    then
      g_std_object_tab.delete(p_session_info);
    end if;
  end if;
end delete_std_objects;

-- PUBLIC
procedure get_std_object
( p_object_name in object_name_t
, p_std_object out nocopy std_object
)
is
begin
  get_std_object
  ( p_session_info => current_session_info
  , p_object_name => p_object_name
  , p_std_object => p_std_object
  );
end get_std_object;

procedure set_std_object
( p_object_name in object_name_t
, p_std_object in out nocopy std_object
)
is
begin
  set_std_object
  ( p_session_info => current_session_info
  , p_object_name => p_object_name
  , p_std_object => p_std_object
  );
end set_std_object;

procedure del_std_object
( p_object_name in object_name_t
)
is
begin
  delete_std_objects
  ( p_session_info => current_session_info
  , p_object_name => replace(p_object_name, '_', g_escape || '_')
  );
end del_std_object;

procedure get_object_names
( p_object_name_tab out nocopy sys.odcivarchar2list
)
is
  l_session_info constant session_info_t := current_session_info;
  l_object_name object_name_t;
begin
  p_object_name_tab := sys.odcivarchar2list();
  if g_std_object_tab.exists(l_session_info)
  then
    l_object_name := g_std_object_tab(l_session_info).first;
    while l_object_name is not null
    loop
      p_object_name_tab.extend(1);
      p_object_name_tab(p_object_name_tab.last) := l_object_name;
      l_object_name := g_std_object_tab(l_session_info).next(l_object_name);
    end loop;
  end if;
end get_object_names;

procedure delete_std_objects
( p_object_name in object_name_t
)
is
begin
  delete_std_objects
  ( p_session_info => current_session_info
  , p_object_name => p_object_name
  );
end delete_std_objects;

$if std_object_mgr.c_testing $then

procedure ut_setup
is
begin
  delete_std_objects;
end;

procedure ut_teardown
is
begin
  delete_std_objects;
end;

procedure ut_store_remove
is
  l_std_object std_object;
  l_dbug_obj_exp dbug_obj_t;
  l_dbug_obj_act dbug_obj_t;
  l_count pls_integer;
begin
  ut.expect(g_std_object_tab.count, 'no sessions/objects at the beginning').to_equal(0);

  begin
    get_std_object('DBUG', l_std_object);
    raise program_error;
  exception
    when no_data_found
    then
      ut.expect(sqlcode, 'sqlcode after get').to_equal(sqlcode); -- no_data_found
  end;

  l_dbug_obj_exp := dbug_obj_t();
  ut.expect(l_dbug_obj_exp.dirty, 'dirty after first get').to_equal(0);

  set_std_object('DBUG', l_dbug_obj_exp);
  get_std_object('DBUG', l_dbug_obj_act);

  ut.expect(g_std_object_tab(current_session_info).count, '# objects at the end').to_equal(1);

  ut.expect(l_dbug_obj_act.dirty, 'dirty after second get').to_equal(0);

  dbms_output.put_line('act: ' || l_dbug_obj_act.serialize());
  dbms_output.put_line('exp: ' || l_dbug_obj_exp.serialize());

  ut.expect(json_object_t(l_dbug_obj_act.serialize()), 'json').to_equal(json_object_t(l_dbug_obj_exp.serialize()));

  l_dbug_obj_act.dirty := 1;
  l_dbug_obj_exp.dirty := 0;

  ut.expect(l_dbug_obj_act = l_dbug_obj_exp, 'compare ignores dummy').to_equal(true);

  del_std_object('DBUG');
end;

$else -- $if std_object_mgr.c_testing $then

procedure ut_setup
is
begin
  raise program_error;
end;

procedure ut_teardown
is
begin
  raise program_error;
end;

procedure ut_store_remove
is
begin
  raise program_error;
end;

$end -- $if std_object_mgr.c_testing $then

end std_object_mgr;
/

