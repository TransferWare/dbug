CREATE OR REPLACE PACKAGE BODY "STD_OBJECT_MGR" IS

-- index by std_objects.object_name
type std_object_tabtype is table of std_objects%rowtype index by std_objects.object_name%type;

g_escape constant varchar2(1) := chr(92); -- escape character

g_std_object_tab std_object_tabtype;

g_group_name std_objects.group_name%type := null;

procedure set_group_name
( p_group_name in std_objects.group_name%type
)
is
begin
  g_group_name := p_group_name;
end set_group_name;

function get_group_name
return std_objects.group_name%type
is
begin
  return g_group_name;
end get_group_name;

procedure get_std_object
( p_object_name in std_objects.object_name%type
, p_std_object out nocopy std_object
)
is
begin
  if g_group_name is not null
  then
    select  tab.obj
    into    p_std_object
    from    std_objects tab
    where   tab.group_name = g_group_name
    and     tab.object_name = p_object_name;
  else
    p_std_object := g_std_object_tab(p_object_name).obj;
  end if;

  p_std_object.dirty := null;
end get_std_object;

procedure set_std_object
( p_object_name in std_objects.object_name%type
, p_std_object in std_object
)
is
  pragma autonomous_transaction;
begin
  if p_std_object.dirty = 0
  then
    null; -- not changed
  elsif g_group_name is not null
  then
    update  std_objects tab
    set     tab.obj = p_std_object
    ,       tab.last_updated_by = user
    ,       tab.last_update_date = sysdate
    where   tab.group_name = g_group_name
    and     tab.object_name = p_object_name;

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
      , obj
      )
      values
      ( g_group_name
      , p_object_name
      , user
      , sysdate
      , user
      , sysdate
      , p_std_object
      );
    end if;

    commit;
  else
    g_std_object_tab(p_object_name).obj := p_std_object;
  end if;
end set_std_object;

procedure del_std_object
( p_object_name in std_objects.object_name%type
)
is
begin
  delete_std_objects
  ( p_group_name => replace(g_group_name, '_', g_escape || '_')
  , p_object_name => replace(p_object_name, '_', g_escape || '_')
  );
end del_std_object;

procedure get_object_names
( p_object_name_tab out nocopy sys.odcivarchar2list
)
is
  l_object_name std_objects.object_name%type;
begin
  if g_group_name is not null
  then
    select  tab.object_name
    bulk collect
    into    p_object_name_tab
    from    std_objects tab
    where   tab.group_name = g_group_name;
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
  pragma autonomous_transaction;

  l_object_name std_objects.object_name%type;
  l_object_name_prev std_objects.object_name%type;
begin
  if p_object_name is null
  then
    raise value_error;
  elsif p_group_name is not null
  then
    delete
    from    std_objects tab
    where   tab.group_name like p_group_name escape g_escape
    and     tab.object_name like p_object_name escape g_escape;

    commit;
  else
    l_object_name := g_std_object_tab.first;
    while l_object_name is not null
    loop
      /* a delete now may influence the next operation, 
         so first do next and then maybe delete (the previous) */
      l_object_name_prev := l_object_name;
      l_object_name := g_std_object_tab.next(l_object_name);
      if l_object_name_prev like p_object_name
      then
        g_std_object_tab.delete(l_object_name_prev);
      end if;
    end loop;
  end if;
end delete_std_objects;

end std_object_mgr;
/

