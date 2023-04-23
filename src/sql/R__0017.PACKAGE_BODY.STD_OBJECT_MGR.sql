CREATE OR REPLACE PACKAGE BODY "STD_OBJECT_MGR" IS

-- index by std_objects.object_name
type std_object_tabtype is table of std_object index by std_objects.object_name%type;

g_escape constant varchar2(1) := chr(92); -- escape character

g_std_object_tab std_object_tabtype;

-- PRIVATE

procedure set_std_object_at
( p_object_name in std_objects.object_name%type
, p_std_object in std_object
)
is
  pragma autonomous_transaction;

  l_obj_type constant std_objects.obj_type%type := p_std_object.get_type();
  l_obj constant std_objects.obj%type := p_std_object.serialize();

  l_user constant std_objects.created_by%type := nvl(p_std_object.app_username, p_std_object.db_username);
begin
  -- persistent storage
  update  std_objects tab
  set     tab.obj = l_obj
  ,       tab.last_updated_by = l_user
  ,       tab.last_update_date = sysdate
  where   tab.group_name = p_std_object.get_session_attributes() -- g_group_name
  and     tab.object_name = p_object_name;

$if std_object_mgr.c_debugging $then
  dbms_output.put_line
  ( utl_lms.format_message
    ( '[%s.%s] p_object_name: %s; sql%rowcount: %s'
    , $$PLSQL_UNIT
    , 'SET_STD_OBJECT_AT'
    , p_object_name
    , to_char(sql%rowcount)
    )
  );
$end

  if sql%rowcount = 0
  then
    insert
    into    std_objects
    ( group_name
    , object_name
    , created_by
    , creation_date
    , last_updated_by
    , last_update_date
    , obj_type
    , obj
    , db_session
    )
    values
    ( p_std_object.get_session_attributes() -- g_group_name
    , p_object_name
    , l_user
    , sysdate
    , l_user
    , sysdate
    , l_obj_type
    , l_obj
    , p_std_object.db_session
    );
  end if;

  commit;
end set_std_object_at;

procedure delete_std_objects_at
( p_group_name in std_objects.group_name%type
, p_object_name in std_objects.object_name%type
)
is
  pragma autonomous_transaction;
begin
  delete
  from    std_objects tab
  where   tab.group_name like p_group_name escape g_escape
  and     tab.object_name like p_object_name escape g_escape;

$if std_object_mgr.c_debugging $then
  dbms_output.put_line
  ( utl_lms.format_message
    ( '[%s.%s] p_group_name: %s; p_object_name: %s; sql%rowcount: %s'
    , $$PLSQL_UNIT
    , 'DELETE_STD_OBJECTS_AT'
    , p_group_name
    , p_object_name
    , to_char(sql%rowcount)
    )
  );
$end

  commit;
end delete_std_objects_at;

-- PUBLIC
procedure get_std_object
( p_object_name in std_objects.object_name%type
, p_std_object out nocopy std_object
)
is
  l_obj_type std_objects.obj_type%type;
  l_obj      std_objects.obj%type;
begin
  p_std_object := g_std_object_tab(p_object_name);
  if p_std_object.belongs_to_this_session() = 0
  then
    -- get from table (i.e. persistent storage)
    select  tab.obj_type
    ,       tab.obj
    into    l_obj_type
    ,       l_obj
    from    std_objects tab
    where   tab.group_name = p_std_object.get_session_attributes()
    and     tab.object_name = p_object_name;

    p_std_object := std_object.deserialize(l_obj_type, l_obj);
  end if;

  p_std_object.dirty := 0;

$if std_object_mgr.c_debugging $then
  dbms_output.put_line
  ( utl_lms.format_message
    ( '[%s.%s] p_object_name: %s; p_std_object.dirty: %s'
    , $$PLSQL_UNIT
    , 'GET_STD_OBJECT'
    , p_object_name
    , to_char(p_std_object.dirty)
    )
  );
$end
end get_std_object;

procedure set_std_object
( p_object_name in std_objects.object_name%type
, p_std_object in out nocopy std_object
)
is
  /* Store when:
  -- A) first when dirty equals 1
  -- B) then if the object is not stored yet
  -- C) else when the object stored is not equal to the input object (ignoring the dirty attribute)
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
    -- retrieve the last version stored and compare
    begin
      get_std_object
      ( p_object_name => p_object_name
      , p_std_object => l_std_object
      );
      l_store :=
        case
          /* comparison ignores attribute dirty:
             1) see order member function compare of type std_object.
             2) see NOTE about dirty.
          */
          when p_std_object = l_std_object
          then false
          else true /* case C */
        end;
    exception
      when no_data_found
      then
        l_store := true; /* case B */
    end;
  end if;

$if std_object_mgr.c_debugging $then
  dbms_output.put_line
  ( utl_lms.format_message
    ( '[%s.%s] p_object_name: %s; l_store: %s'
    , $$PLSQL_UNIT
    , 'SET_STD_OBJECT'
    , p_object_name
    , case l_store when true then 'TRUE' when false then 'FALSE' else 'NULL' end
    )
  );
$end

  if not(l_store)
  then
    null;
  else
    -- package state
    g_std_object_tab(p_object_name) := p_std_object;
  end if;
end set_std_object;

procedure del_std_object
( p_group_name in std_objects.group_name%type
, p_object_name in std_objects.object_name%type
)
is
begin
$if std_object_mgr.c_debugging $then
  dbms_output.put_line
  ( utl_lms.format_message
    ( '[%s.%s] p_group_name: %s; p_object_name: %s'
    , $$PLSQL_UNIT
    , 'DEL_STD_OBJECT'
    , p_group_name
    , p_object_name
    )
  );
$end

  delete_std_objects
  ( p_group_name => replace(p_group_name, '_', g_escape || '_')
  , p_object_name => replace(p_object_name, '_', g_escape || '_')
  );
end del_std_object;

procedure get_object_names
( p_group_name in std_objects.group_name%type
, p_object_name_tab out nocopy sys.odcivarchar2list
)
is
  l_object_name std_objects.object_name%type;
begin
  if p_group_name is not null
  then
    select  tab.object_name
    bulk collect
    into    p_object_name_tab
    from    std_objects tab
    where   tab.group_name = p_group_name;
  else
    p_object_name_tab := sys.odcivarchar2list();
    l_object_name := g_std_object_tab.first;
    while l_object_name is not null
    loop
      p_object_name_tab.extend(1);
      p_object_name_tab(p_object_name_tab.last) := l_object_name;
      l_object_name := g_std_object_tab.next(l_object_name);
    end loop;
  end if;
end get_object_names;

procedure delete_std_objects
( p_group_name in std_objects.group_name%type default '%'
, p_object_name in std_objects.object_name%type default '%'
)
is
  l_object_name std_objects.object_name%type;
  l_object_name_prev std_objects.object_name%type;
begin
$if std_object_mgr.c_debugging $then
  dbms_output.put_line
  ( utl_lms.format_message
    ( '[%s.%s] p_group_name: %s; p_object_name: %s'
    , $$PLSQL_UNIT
    , 'DELETE_STD_OBJECTS'
    , p_group_name
    , p_object_name
    )
  );
$end

  if p_object_name is null
  then
    raise value_error;
  elsif p_group_name is not null
  then
    delete_std_objects_at
    ( p_group_name => p_group_name
    , p_object_name => p_object_name
    );
  else
    l_object_name := g_std_object_tab.first;
    while l_object_name is not null
    loop
      /* a delete now may influence the next operation,
         so first do next and then maybe delete (the previous) */
      l_object_name_prev := l_object_name;
      l_object_name := g_std_object_tab.next(l_object_name);
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
        g_std_object_tab.delete(l_object_name_prev);
      end if;
    end loop;
  end if;
end delete_std_objects;

$if std_object_mgr.c_testing $then

procedure ut_setup
is
  pragma autonomous_transaction;
begin
  delete_std_objects
  ( p_group_name => 'TEST%'
  );
  commit;
end;

procedure ut_teardown
is
  pragma autonomous_transaction;
begin
  delete_std_objects
  ( p_group_name => 'TEST%'
  );
  commit;
end;

procedure ut_store_remove
is
  pragma autonomous_transaction;

  l_std_object std_object;
  l_dbug_obj_exp dbug_obj_t;
  l_dbug_obj_act dbug_obj_t;
  l_count pls_integer;
begin
  ut.expect(g_std_object_tab.count, 'try 1').to_equal(0);

  begin
    get_std_object('DBUG', l_std_object);
    raise program_error;
  exception
    when no_data_found
    then
      ut.expect(sqlcode, 'try 1').to_equal(sqlcode); -- no_data_found
  end;

  l_dbug_obj_exp := dbug_obj_t();
  ut.expect(l_dbug_obj_exp.dirty, 'try 1').to_equal(0);

  set_std_object('DBUG', l_dbug_obj_exp);
  get_std_object('DBUG', l_dbug_obj_act);

  ut.expect(g_std_object_tab.count, 'try 1').to_equal(1);

  ut.expect(l_dbug_obj_act.dirty, 'try 1').to_equal(0);

  dbms_output.put_line('act: ' || l_dbug_obj_act.serialize());
  dbms_output.put_line('exp: ' || l_dbug_obj_exp.serialize());

  ut.expect(json_object_t(l_dbug_obj_act.serialize()), 'try 1').to_equal(json_object_t(l_dbug_obj_exp.serialize()));

  l_dbug_obj_act.dirty := 1;
  l_dbug_obj_exp.dirty := 0;

  ut.expect(l_dbug_obj_act = l_dbug_obj_exp, 'compare ignores dummy try 1').to_equal(true);

  del_std_object(null, 'DBUG');

  commit;
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

