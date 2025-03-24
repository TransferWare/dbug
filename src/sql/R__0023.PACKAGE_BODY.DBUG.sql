CREATE OR REPLACE PACKAGE BODY "DBUG" IS


-- > private (DBUG)

-- dbms_output.put_line has increased line size limit since 10g Release 2 (10.2), but we allow only Oracle 12 and higher
$if dbms_db_version.version < 12 $then

  c_version_too_old constant integer := 1/0; -- divide by zero as a trick since $error is not parsed well by Flyway

$end

  /* TYPES */

  subtype t_cursor_key is varchar2(4000 char);

  type cursor_tabtype is table of integer index by t_cursor_key;

  subtype t_session_id is varchar2(4000 char);

  /* CONSTANTS */

  c_indent constant char(4) := '|   ';

  c_null constant varchar2(6) := '<NULL>';

  /* VARIABLES */

  g_obj dbug_obj_t := null /*dbug_obj_t()*/;

  -- table of dbms_sql cursors
  g_cursor_tab cursor_tabtype;

  g_session_id t_session_id := null;

  /* Invoke procedure DBUG_INIT if any */
  procedure init
  is
    l_cursor_key t_cursor_key;
    l_session_id constant t_session_id :=
      coalesce
      ( sys_context('APEX$SESSION', 'APP_SESSION')
      , sys_context('USERENV', 'SESSIONID')
      , dbms_session.unique_session_id
      );
  begin
    /* clear global package variables if session changes */
    if l_session_id = g_session_id
    then
      null;
    else
      g_obj := null;

      l_cursor_key := g_cursor_tab.first;
      while l_cursor_key is not null
      loop
        dbms_sql.close_cursor(g_cursor_tab(l_cursor_key));
        l_cursor_key := g_cursor_tab.next(l_cursor_key);
      end loop;
      g_cursor_tab.delete;

      g_session_id := l_session_id;

      -- invoke procedure DBUG_INIT if it exists
      declare
        l_found pls_integer;
        l_dbug_init constant user_objects.object_name%type := 'DBUG_INIT';
      begin
        select  1
        into    l_found
        from    user_objects
        where   object_name = l_dbug_init
        and     object_type = 'PROCEDURE';

        execute immediate 'begin ' || l_dbug_init || '; end;';
      exception
        when no_data_found
        then
          null;
      end;
    end if;
  end init;

  /* local modules */
  procedure set_number
  ( p_str in varchar2
  , p_num in number
    -- indexes if p_str_tab and p_num_tab must be in sync
  , p_str_tab in out nocopy sys.odcivarchar2list
  , p_num_tab in out nocopy sys.odcinumberlist
  )
  is
    l_idx pls_integer;
    l_str_tab_count constant naturaln := case when p_str_tab is null then 0 else p_str_tab.count end;
    l_num_tab_count constant naturaln := case when p_num_tab is null then 0 else p_num_tab.count end;
  begin
    if l_str_tab_count != l_num_tab_count
    then
      raise program_error;
    end if;
    
    if p_str_tab is null
    then
      p_str_tab := sys.odcivarchar2list();
    end if;

    if p_num_tab is null
    then
      p_num_tab := sys.odcinumberlist();
    end if;

    l_idx := p_str_tab.first;
    loop
      exit when l_idx is null or p_str_tab(l_idx) = p_str;

      if not p_num_tab.exists(l_idx)
      then
        raise program_error;
      end if;

      l_idx := p_str_tab.next(l_idx);
    end loop;

    if l_idx is null -- not found
    then
      p_str_tab.extend(1);
      p_num_tab.extend(1);
      l_idx := p_str_tab.last;
      p_str_tab(l_idx) := p_str;
    end if;

    p_num_tab(l_idx) := p_num;
  end set_number;

  function get_number
  ( p_str in varchar2
    -- indexes if p_str_tab and p_num_tab must be in sync
  , p_str_tab in sys.odcivarchar2list
  , p_num_tab in sys.odcinumberlist
  )
  return number
  is
    l_idx pls_integer;
    l_str_tab_count constant naturaln := case when p_str_tab is null then 0 else p_str_tab.count end;
    l_num_tab_count constant naturaln := case when p_num_tab is null then 0 else p_num_tab.count end;
  begin
    if l_str_tab_count != l_num_tab_count
    then
      raise program_error;
    end if;

    l_idx := case when p_str_tab is not null then p_str_tab.first end;
    loop
      exit when l_idx is null or p_str_tab(l_idx) = p_str;

      if not p_num_tab.exists(l_idx)
      then
        raise program_error;
      end if;

      l_idx := p_str_tab.next(l_idx);
    end loop;

    return case when l_idx is null then null else p_num_tab(l_idx) end;
  end get_number;

$if dbug.c_trace > 0 or dbug.c_trace_enter > 0 or dbug.c_trace_leave > 0 $then
  procedure trace( p_line in varchar2 )
  is
  begin
$if dbug.c_trace_log4plsql > 0 $then
    plog.debug('TRACE: ' || p_line);
$else
    dbms_output.put_line('TRACE: ' || p_line); -- dbms_output.put_line supports 32767 bytes
$end
  end trace;
$end

  function get_call( p_idx in pls_integer )
  return varchar2
  is
    l_idx constant pls_integer := p_idx + 1;
  begin
    /*
     * In the case of a call stack in which A calls B, which calls C, which calls D, which calls E, which calls F, which calls E, this stack can be written as a line with the dynamic depths underneath:
     *
     * A B C D E F E
     * 7 6 5 4 3 2 1
     *
     * Please note that this function is called from another place so the stack now is:
     *
     * A B C D E F E get_call
     * 8 7 6 5 4 3 2 1
     *
     * So index p_idx before the call is p_idx + 1 now.
     * The first call (A) should return stack number 1, so use (l_dynamic_depth + 1 - l_idx) as the stack number.
     */
    return utl_call_stack.owner(l_idx) ||
           '.' ||
           utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(l_idx)) ||
           '#' ||
           utl_call_stack.unit_line(l_idx)
           ;
  end get_call;

  function get_call_by_depth( p_depth in pls_integer )
  return varchar2
  is
  begin
    return get_call(utl_call_stack.dynamic_depth - p_depth + 1);
  end get_call_by_depth;

  procedure show_error
  ( p_line in varchar2
  , p_format_call_stack in varchar2 default dbms_utility.format_call_stack
  )
  is
    l_dynamic_depth constant pls_integer := utl_call_stack.dynamic_depth;
    l_subprogram_not_dbug_found boolean := false;
  begin
    dbms_output.put_line('ERROR: ' || p_line); -- dbms_output.put_line supports 32767 bytes

    /*
     * In the case of a call stack in which A calls B, which calls C, which calls D, which calls E, which calls F, which calls E, this stack can be written as a line with the dynamic depths underneath:
     *
     * A B C D E F E
     * 7 6 5 4 3 2 1
     */

    for i_idx in 1..l_dynamic_depth
    loop
      if utl_call_stack.subprogram(i_idx)(1) != $$PLSQL_UNIT -- (1) is unit name
      then
        l_subprogram_not_dbug_found := true;
      end if;
      if l_subprogram_not_dbug_found
      then
        dbms_output.put_line(get_call(i_idx));
      end if;
    end loop;
  end show_error;

  procedure get_cursor
  ( p_key in varchar2
  , p_plsql_stmt in varchar2
  , p_cursor out integer
  )
  is
  begin
    if g_cursor_tab.exists(p_key)
    then
      p_cursor := g_cursor_tab(p_key);
    else
      p_cursor := dbms_sql.open_cursor;

      -- dbms_sql.parse() does not like <cr> (chr(13)) and
      -- the dynamic sql here may have as the end of line
      -- 1) <cr><lf> (Windows) or
      -- 2) <cr> (Apple)
      -- 3) <lf> (Unix)
      -- So replace those line endings by <lf>.
      begin
$if dbug.c_trace > 1 $then
        trace(replace(replace(p_plsql_stmt, chr(13)||chr(10), chr(10)), chr(13), chr(10)));
$end
        dbms_sql.parse
        ( p_cursor
        , replace(replace(p_plsql_stmt, chr(13)||chr(10), chr(10)), chr(13), chr(10))
        , dbms_sql.native
        );
        g_cursor_tab(p_key) := p_cursor;
      exception
        when others -- parse error
        then
          -- show_error(sqlerrm);
          dbms_sql.close_cursor(p_cursor);
          g_cursor_tab(p_key) := null;
      end;
    end if;
  end get_cursor;

  function handle_error
  ( p_obj in dbug_obj_t
  , p_sqlcode in pls_integer
  , p_sqlerrm in varchar2
  , p_format_call_stack in varchar2 default dbms_utility.format_call_stack
  )
  return boolean
  is
    l_result boolean := true;

    procedure empty_dbms_output_buffer
    is
      l_lines dbms_output.chararr;
      l_numlines integer := power(2, 31); /* maximum nr of lines */
    begin
      -- clear the buffer
      dbms_output.get_lines(lines => l_lines, numlines => l_numlines);
$if dbug.c_trace > 1 $then
      trace('number of dbms_output lines cleared: ' || to_char(l_numlines));
$end
    end empty_dbms_output_buffer;
  begin
    if p_sqlcode = -20000 and
       instr(p_sqlerrm, 'ORU-10027:') > 0 -- dbms_output buffer overflow
    then
      case p_obj.ignore_buffer_overflow
        when 1
        then
          -- clear the buffer
          empty_dbms_output_buffer;
          show_error(p_sqlerrm, p_format_call_stack);
        when 0
        then
          l_result := false;
        else /* ???? */
          raise value_error;
      end case;
    else
      begin
        show_error(p_sqlerrm, p_format_call_stack);
      exception
        when others then null;
      end;
    end if;
    return l_result;
  exception
    when others
    then
      return false;
  end handle_error;

  procedure get_called_from
  ( p_depth in integer
  , p_called_from out nocopy module_name_t
  , p_module_name out nocopy module_name_t
  )
  is
    l_dynamic_depth constant pls_integer := utl_call_stack.dynamic_depth;
    l_found pls_integer := null;
  begin
    /*
     * In the case of a call stack in which A calls B, which calls C, which calls D, which calls E, which calls F, which calls E, this stack can be written as a line with the dynamic depths underneath:
     *
     * A B C D E F E
     * 7 6 5 4 3 2 1
     */

    <<search_loop>>
    for i_idx in 2 .. l_dynamic_depth -- since we are already in package DBUG, this call is utl_call_stack.subprogram(1)
    loop
      if ( l_dynamic_depth - i_idx + 1 ) = p_depth
      then
        -- the called_from has been found
        l_found := i_idx;
        p_called_from := utl_call_stack.subprogram(i_idx)(1); -- the unit name
        p_module_name := utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(i_idx)) || '#' || utl_call_stack.unit_line(i_idx);
        exit search_loop;
      end if;
    end loop search_loop;
    if l_found is null
    then
      raise_application_error(-20000, 'Could not find call stack with this depth (' || p_depth || ').');
    end if;
  end get_called_from;
  
  procedure pop_call_stack
  ( p_obj in out nocopy dbug_obj_t
  , p_lwb in binary_integer
  , p_leave_on_error in boolean -- are we in a leave_on_error?
  )
  is
    l_active_idx pls_integer;
    l_active_str method_t;
    l_cursor integer;
    l_dummy integer;
  begin
    -- GJP 21-04-2006
    -- When there is a mismatch in enter/leave pairs
    -- (for example caused by uncaught expections or program errors)
    -- we must pop from the call stack (p_obj.call_tab) all entries through
    -- the one which has the same called from location as this call.
    -- When there is no mismatch this means the top entry from p_obj.call_tab will be removed.

$if dbug.c_trace > 1 $then
    trace('>pop_call_stack(p_lwb => '||p_lwb||', p_leave_on_error => ' || dbug.cast_to_varchar2(p_leave_on_error) || ')');
$end

    if p_lwb = p_obj.call_tab.last
    then
      null;
    elsif not(p_leave_on_error) -- no error message when invoked from leave_on_error
    then
      show_error('Popping ' || to_char(p_obj.call_tab.last - p_lwb) || ' missing dbug.leave calls');
    end if;

    while p_obj.call_tab.last >= p_lwb
    loop

$if dbug.c_trace > 1 $then
      trace('p_obj.call_tab.last: '||p_obj.call_tab.last);
$end

      -- [ 1677186 ] Enter/leave pairs are not displayed correctly
      -- The level should be increased/decreased only once no matter how many methods are active.
      -- Decrement must take place before the leave.
      p_obj.indent_level := greatest(p_obj.indent_level - 1, 0);

      l_active_idx := case when p_obj.active_num_tab is not null then p_obj.active_num_tab.first end;
      while l_active_idx is not null
      loop
        l_active_str := p_obj.active_str_tab(l_active_idx);

        if p_obj.active_num_tab(l_active_idx) = 0
        then
          null;
        else
          begin
            get_cursor
            ( 'dbug_'||l_active_str||'.leave'
            , 'begin dbug_'||l_active_str||'.leave; end;'
            , l_cursor
            );
            l_dummy := dbms_sql.execute(l_cursor);
          exception
            when others
            then
              if not handle_error(p_obj, sqlcode, 'dbug_'||l_active_str||'.leave: '||sqlerrm)
              then
                raise;
              end if;
          end;
        end if;

        l_active_idx := p_obj.active_num_tab.next(l_active_idx);
      end loop;

      -- pop the call stack each time so format_leave can print the module name
      p_obj.call_tab.trim(1);

$if dbug.c_trace > 1 $then
      trace('trimmed p_obj.call_tab with 1 to '||p_obj.call_tab.count||' elements');
$end
    end loop;

    p_obj.dirty := 1;
    
$if dbug.c_trace > 1 $then
    trace('<pop_call_stack');
$end
  end pop_call_stack;

  procedure done
  ( p_obj in dbug_obj_t
  )
  is
    l_idx pls_integer;
    l_active_str method_t;
    l_cursor integer;
    l_dummy binary_integer;
  begin
    l_idx := case when p_obj.active_num_tab is not null then p_obj.active_num_tab.first end;
    loop
      -- GJP 2023-03-11 Clearly an error
      -- exit when l_active_str is null;
      exit when l_idx is null;

      l_active_str := p_obj.active_str_tab(l_idx);

      if p_obj.active_num_tab(l_idx) = 1
      then
        begin
          get_cursor
          ( 'dbug_'||l_active_str||'.done'
          , 'begin dbug_'||l_active_str||'.done; end;'
          , l_cursor
          );
          l_dummy := dbms_sql.execute(l_cursor);
        end;
      end if;

      l_idx := p_obj.active_num_tab.next(l_idx);
    end loop;
  end done;

  procedure activate
  ( p_obj in out nocopy dbug_obj_t
  , p_method in method_t
  , p_status in boolean
  )
  is
    l_method method_t;
  begin
$if dbug.c_trace > 1 $then
    trace('>activate('''||p_method||''', '||cast_to_varchar2(p_status)||') (1)');
$end

    if upper(p_method) = 'TS_DBUG' -- backwards compability with TS_DBUG
    then
      l_method := c_method_plsdbug;
    else
      l_method := p_method;
    end if;

    select  lower(l_method)
    into    l_method
    from    user_objects obj
    where   obj.object_type = 'PACKAGE BODY'
    and     obj.object_name = 'DBUG_' || upper(l_method);

    set_number
    ( p_str => l_method
    , p_num => case p_status when true then 1 when false then 0 else null end
    , p_str_tab => p_obj.active_str_tab
    , p_num_tab => p_obj.active_num_tab
    );

    p_obj.dirty := 1;

$if dbug.c_trace > 1 $then
    trace('<activate (1)');
$end
  end activate;

  function active
  ( p_obj in dbug_obj_t
  , p_method in method_t
  )
  return boolean
  is
    l_method method_t;
  begin
    if upper(p_method) = 'TS_DBUG' -- backwards compability with TS_DBUG
    then
      l_method := lower(c_method_plsdbug);
    else
      l_method := lower(p_method);
    end if;

    return
      case get_number
           ( p_str => l_method
           , p_str_tab => p_obj.active_str_tab
           , p_num_tab => p_obj.active_num_tab
           )
        when 1
        then true
        when 0
        then false
        else null
      end;
  end active;

  procedure set_level
  ( p_obj in out nocopy dbug_obj_t
  , p_level in level_t
  )
  is
  begin
    if p_obj.call_tab.count != 0
    then
      raise program_error;
    end if;

    if p_level between c_level_all and c_level_off
    then
      p_obj.dbug_level := p_level;
      p_obj.dirty := 1;
    else
      raise value_error;
    end if;
  end set_level;

  function get_level
  ( p_obj in dbug_obj_t
  )
  return level_t
  is
  begin
    return p_obj.dbug_level;
  end get_level;

  procedure set_break_point_level
  ( p_obj in out nocopy dbug_obj_t
  , p_break_point_level_tab in break_point_level_t
  )
  is
    l_break_point break_point_t := p_break_point_level_tab.first;
  begin
    if p_obj.call_tab.count != 0
    then
      raise program_error;
    end if;

    while l_break_point is not null
    loop
      if p_break_point_level_tab(l_break_point) between c_level_debug and c_level_fatal
      then
        null;
      else
        raise value_error;
      end if;

      set_number
      ( p_str => l_break_point
      , p_num => p_break_point_level_tab(l_break_point)
      , p_str_tab => p_obj.break_point_level_str_tab
      , p_num_tab => p_obj.break_point_level_num_tab
      );
      p_obj.dirty := 1;

      l_break_point := p_break_point_level_tab.next(l_break_point);
    end loop;
  end set_break_point_level;

  function get_break_point_level
  ( p_obj in dbug_obj_t
  )
  return break_point_level_t
  is
    l_idx pls_integer := case when p_obj.break_point_level_str_tab is not null then p_obj.break_point_level_str_tab.first end;
    l_break_point_level_tab break_point_level_t;
  begin
    while l_idx is not null
    loop
      l_break_point_level_tab(p_obj.break_point_level_str_tab(l_idx)) :=
        p_obj.break_point_level_num_tab(l_idx);

      l_idx := p_obj.break_point_level_str_tab.next(l_idx);
    end loop;

    return l_break_point_level_tab;
  end get_break_point_level;

  function check_break_point
  ( p_obj in dbug_obj_t
  , p_break_point in varchar2
  )
  return boolean
  is
    l_level level_t;
  begin
    if p_obj.active_num_tab.count = 0
    then
      return false;
    else
      l_level :=
        nvl
        ( get_number
          ( p_str => p_break_point
          , p_str_tab => p_obj.break_point_level_str_tab
          , p_num_tab => p_obj.break_point_level_num_tab
          )
        , c_level_default
        );
      if l_level < p_obj.dbug_level
      then
        return false;
      end if;
    end if;
    return true;
  end check_break_point;

$if dbug.c_trace > 0 or dbug.c_trace_enter > 0 or dbug.c_trace_leave > 0 $then

  procedure show_call_stack
  ( p_obj in out nocopy dbug_obj_t
  , p_enter in boolean
  )
  is
    l_line_tab dbug.line_tab_t;
  begin
    trace('>show_call_stack' || case when p_enter then ' after entering ' else ' before leaving ' end || case when p_obj.call_tab.last is not null then p_obj.call_tab(p_obj.call_tab.last).module_name end);
    
    if p_obj is not null and p_obj.call_tab is not null and p_obj.call_tab.count > 0
    then
      for i_call_idx in p_obj.call_tab.first .. p_obj.call_tab.last
      loop
        trace('['||to_char(i_call_idx, 'fm00')||'] module name: '|| p_obj.call_tab(i_call_idx).module_name);
        trace('['||to_char(i_call_idx, 'fm00')||'] depth: '|| p_obj.call_tab(i_call_idx).depth);
        trace('['||to_char(i_call_idx, 'fm00')||'] called from: '|| p_obj.call_tab(i_call_idx).called_from);
      end loop;
    end if;

    trace('<show_call_stack');
  end show_call_stack;

$end

  procedure enter
  ( p_obj in out nocopy dbug_obj_t
  , p_module in module_name_t
  , p_depth in integer
  )
  is
    l_idx pls_integer;
    l_active_str method_t;
    l_cursor integer;
    l_dummy integer;
    l_module module_name_t;
  begin
    if not check_break_point(p_obj, "trace")
    then
      return;
    end if;

    -- GJP 21-04-2006 Store the location from which dbug.enter is called
    declare
      l_idx constant pls_integer := p_obj.call_tab.count + 1;
      l_call dbug_call_obj_t;
    begin
       p_obj.call_tab.extend(1);
       p_obj.call_tab(l_idx) := dbug_call_obj_t(null, null, null);

$if dbug.c_trace_enter > 0 $then
       trace('extended p_obj.call_tab with 1 to '||p_obj.call_tab.count||' elements');
$end

       get_called_from(p_depth, p_obj.call_tab(l_idx).called_from, l_module);
       p_obj.call_tab(l_idx).depth := p_depth;
       p_obj.call_tab(l_idx).module_name := nvl(p_module, l_module);
       if l_idx != 1
       then
         -- Same stack?
         -- See =head2 Restarting a PL/SQL block with dbug.leave calls missing due to an exception
         if ( p_obj.call_tab(p_obj.call_tab.first).module_name = p_obj.call_tab(l_idx).module_name
              and
              -- GJP 2023-04-02 Use depth to check that it is really restarting a PL/SQL block
              p_obj.call_tab(p_obj.call_tab.first).depth = p_obj.call_tab(l_idx).depth
              and
              -- use a trick with appending 'X' so circumvent checking ((x is null and y is null) or x = y)
              p_obj.call_tab(p_obj.call_tab.first).called_from || 'X' = p_obj.call_tab(l_idx).called_from || 'X'
            )
         then
           show_error
           ( 'Module name and other calls equal to the first one '
             ||'while the dbug call stack count is '
             ||p_obj.call_tab.count
           );

           -- this is probably a situation where an outermost PL/SQL block
           -- is called for another time and where the previous time did not
           -- not have all dbug.enter calls matched by a dbug.leave.

           -- save the called_from info before destroying p_obj.call_tab
           l_call := p_obj.call_tab(l_idx);

           p_obj.call_tab.trim; -- this one is moved to nr 1
           pop_call_stack(p_obj, 1, false); -- erase the complete stack (except index 0)
           p_obj.call_tab.extend(1);
           p_obj.call_tab(1) := l_call;

$if dbug.c_trace_enter > 0 $then
           trace('extended p_obj.call_tab with 1 to '||p_obj.call_tab.count||' elements');
$end

         end if;
       end if;
    end;

    l_idx := case when p_obj.active_num_tab is not null then p_obj.active_num_tab.first end;
    while l_idx is not null
    loop
      l_active_str := p_obj.active_str_tab(l_idx);

      if p_obj.active_num_tab(l_idx) = 0
      then
        null;
      else
        begin
          get_cursor
          ( 'dbug_'||l_active_str||'.enter'
          , 'begin dbug_'||l_active_str||'.enter(:0); end;'
          , l_cursor
          );
          dbms_sql.bind_variable(l_cursor, '0', p_obj.call_tab(p_obj.call_tab.last).module_name);
          l_dummy := dbms_sql.execute(l_cursor);
        exception
          when others
          then
            if not handle_error(p_obj, sqlcode, 'dbug_'||l_active_str||'.enter(:0): '||sqlerrm)
            then
              raise;
            end if;
        end;
      end if;

      l_idx := p_obj.active_num_tab.next(l_idx);
    end loop;

    -- [ 1677186 ] Enter/leave pairs are not displayed correctly
    -- Increment after all actions have been done.
    p_obj.indent_level := p_obj.indent_level + 1;
    p_obj.dirty := 1;

$if dbug.c_trace_enter > 0 $then
    show_call_stack(p_obj, true);
$end
  end enter;

  procedure print
  ( p_obj in dbug_obj_t
  , p_break_point in varchar2
  , p_fmt in varchar2
  , p_arg1 in varchar2
  )
  is
    l_idx pls_integer;
    l_active_str method_t;
    l_cursor integer;
    l_dummy integer;
  begin
    if not check_break_point(p_obj, p_break_point)
    then
      return;
    end if;

    l_idx := case when p_obj.active_num_tab is not null then p_obj.active_num_tab.first end;
    while l_idx is not null
    loop
      l_active_str := p_obj.active_str_tab(l_idx);

      if p_obj.active_num_tab(l_idx) = 0
      then
        null;
      else
        begin
          get_cursor
          ( 'dbug_'||l_active_str||'.print1'
          , 'begin dbug_'||l_active_str||'.print(:0, :1, :2); end;'
          , l_cursor
          );
          dbms_sql.bind_variable(l_cursor, '0', p_break_point);
          dbms_sql.bind_variable(l_cursor, '1', p_fmt);
          dbms_sql.bind_variable(l_cursor, '2', nvl(p_arg1, c_null));
          l_dummy := dbms_sql.execute(l_cursor);
        exception
          when others
          then
            if not handle_error(p_obj, sqlcode, 'dbug_'||l_active_str||'.print(:0, :1, :2): '||sqlerrm)
            then
              raise;
            end if;
        end;
      end if;

      l_idx := p_obj.active_num_tab.next(l_idx);
    end loop;
  end print;

  procedure print
  ( p_obj in dbug_obj_t
  , p_break_point in varchar2
  , p_fmt in varchar2
  , p_arg1 in varchar2
  , p_arg2 in varchar2
  )
  is
    l_idx pls_integer;
    l_active_str method_t;
    l_cursor integer;
    l_dummy integer;
  begin
    if not check_break_point(p_obj, p_break_point)
    then
      return;
    end if;

    l_idx := case when p_obj.active_num_tab is not null then p_obj.active_num_tab.first end;
    while l_idx is not null
    loop
      l_active_str := p_obj.active_str_tab(l_idx);

      if p_obj.active_num_tab(l_idx) = 0
      then
        null;
      else
        begin
          get_cursor
          ( 'dbug_'||l_active_str||'.print2'
          , 'begin dbug_'||l_active_str||'.print(:0, :1, :2, :3); end;'
          , l_cursor
          );
          dbms_sql.bind_variable(l_cursor, '0', p_break_point);
          dbms_sql.bind_variable(l_cursor, '1', p_fmt);
          dbms_sql.bind_variable(l_cursor, '2', nvl(p_arg1, c_null));
          dbms_sql.bind_variable(l_cursor, '3', nvl(p_arg2, c_null));
          l_dummy := dbms_sql.execute(l_cursor);
        exception
          when others
          then
            if not handle_error(p_obj, sqlcode, 'dbug_'||l_active_str||'.print(:0, :1, :2, :3): '||sqlerrm)
            then
              raise;
            end if;
        end;
      end if;

      l_idx := p_obj.active_num_tab.next(l_idx);
    end loop;
  end print;

  procedure print
  ( p_obj in dbug_obj_t
  , p_break_point in varchar2
  , p_fmt in varchar2
  , p_arg1 in varchar2
  , p_arg2 in varchar2
  , p_arg3 in varchar2
  )
  is
    l_idx pls_integer;
    l_active_str method_t;
    l_cursor integer;
    l_dummy integer;
  begin
    if not check_break_point(p_obj, p_break_point)
    then
      return;
    end if;

    l_idx := case when p_obj.active_num_tab is not null then p_obj.active_num_tab.first end;
    while l_idx is not null
    loop
      l_active_str := p_obj.active_str_tab(l_idx);

      if p_obj.active_num_tab(l_idx) = 0
      then
        null;
      else
        begin
          get_cursor
          ( 'dbug_'||l_active_str||'.print3'
          , 'begin dbug_'||l_active_str||'.print(:0, :1, :2, :3, :4); end;'
          , l_cursor
          );
          dbms_sql.bind_variable(l_cursor, '0', p_break_point);
          dbms_sql.bind_variable(l_cursor, '1', p_fmt);
          dbms_sql.bind_variable(l_cursor, '2', nvl(p_arg1, c_null));
          dbms_sql.bind_variable(l_cursor, '3', nvl(p_arg2, c_null));
          dbms_sql.bind_variable(l_cursor, '4', nvl(p_arg3, c_null));
          l_dummy := dbms_sql.execute(l_cursor);
        exception
          when others
          then
            if not handle_error(p_obj, sqlcode, 'dbug_'||l_active_str||'.print(:0, :1, :2, :3, :4): '||sqlerrm)
            then
              raise;
            end if;
        end;
      end if;

      l_idx := p_obj.active_num_tab.next(l_idx);
    end loop;
  end print;

  procedure print
  ( p_obj in dbug_obj_t
  , p_break_point in varchar2
  , p_fmt in varchar2
  , p_arg1 in varchar2
  , p_arg2 in varchar2
  , p_arg3 in varchar2
  , p_arg4 in varchar2
  )
  is
    l_idx pls_integer;
    l_active_str method_t;
    l_cursor integer;
    l_dummy integer;
  begin
    if not check_break_point(p_obj, p_break_point)
    then
      return;
    end if;

    l_idx := case when p_obj.active_num_tab is not null then p_obj.active_num_tab.first end;
    while l_idx is not null
    loop
      l_active_str := p_obj.active_str_tab(l_idx);

      if p_obj.active_num_tab(l_idx) = 0
      then
        null;
      else
        begin
          get_cursor
          ( 'dbug_'||l_active_str||'.print4'
          , 'begin dbug_'||l_active_str||'.print(:0, :1, :2, :3, :4, :5); end;'
          , l_cursor
          );
          dbms_sql.bind_variable(l_cursor, '0', p_break_point);
          dbms_sql.bind_variable(l_cursor, '1', p_fmt);
          dbms_sql.bind_variable(l_cursor, '2', nvl(p_arg1, c_null));
          dbms_sql.bind_variable(l_cursor, '3', nvl(p_arg2, c_null));
          dbms_sql.bind_variable(l_cursor, '4', nvl(p_arg3, c_null));
          dbms_sql.bind_variable(l_cursor, '5', nvl(p_arg4, c_null));
          l_dummy := dbms_sql.execute(l_cursor);
        exception
          when others
          then
            if not handle_error(p_obj, sqlcode, 'dbug_'||l_active_str||'.print(:0, :1, :2, :3, :4, :5): '||sqlerrm)
            then
              raise;
            end if;
        end;
      end if;

      l_idx := p_obj.active_num_tab.next(l_idx);
    end loop;
  end print;

  procedure print
  ( p_obj in dbug_obj_t
  , p_break_point in varchar2
  , p_fmt in varchar2
  , p_arg1 in varchar2
  , p_arg2 in varchar2
  , p_arg3 in varchar2
  , p_arg4 in varchar2
  , p_arg5 in varchar2
  )
  is
    l_idx pls_integer;
    l_active_str method_t;
    l_cursor integer;
    l_dummy integer;
  begin
    if not check_break_point(p_obj, p_break_point)
    then
      return;
    end if;

    l_idx := case when p_obj.active_num_tab is not null then p_obj.active_num_tab.first end;
    while l_idx is not null
    loop
      l_active_str := p_obj.active_str_tab(l_idx);

      if p_obj.active_num_tab(l_idx) = 0
      then
        null;
      else
        begin
          get_cursor
          ( 'dbug_'||l_active_str||'.print5'
          , 'begin dbug_'||l_active_str||'.print(:0, :1, :2, :3, :4, :5, :6); end;'
          , l_cursor
          );
          dbms_sql.bind_variable(l_cursor, '0', p_break_point);
          dbms_sql.bind_variable(l_cursor, '1', p_fmt);
          dbms_sql.bind_variable(l_cursor, '2', nvl(p_arg1, c_null));
          dbms_sql.bind_variable(l_cursor, '3', nvl(p_arg2, c_null));
          dbms_sql.bind_variable(l_cursor, '4', nvl(p_arg3, c_null));
          dbms_sql.bind_variable(l_cursor, '5', nvl(p_arg4, c_null));
          dbms_sql.bind_variable(l_cursor, '6', nvl(p_arg5, c_null));
          l_dummy := dbms_sql.execute(l_cursor);
        exception
          when others
          then
            if not handle_error(p_obj, sqlcode, 'dbug_'||l_active_str||'.print(:0, :1, :2, :3, :4, :5, :6): '||sqlerrm)
            then
              raise;
            end if;
        end;
      end if;

      l_idx := p_obj.active_num_tab.next(l_idx);
    end loop;
  end print;

  procedure leave
  ( p_obj in out nocopy dbug_obj_t
  , p_depth in pls_integer
  , p_leave_on_error in boolean
  )
  is
  begin
    if not check_break_point(p_obj, "trace")
    then
      return;
    end if;

$if dbug.c_trace_leave > 0 $then
    show_call_stack(p_obj, false);
$end

    -- GJP 21-04-2006
    -- When there is a mismatch in enter/leave pairs
    -- (for example caused by uncaught expections or program errors)
    -- we must pop from the call stack (p_obj.call_tab) all entries through
    -- the one which has the same called from location as this call.
    -- When there is no mismatch this means the top entry from p_obj.call_tab will be removed.

    declare
      l_idx pls_integer := p_obj.call_tab.last;
$if dbug.c_trace_leave > 0 $then
      l_obj dbug_obj_t := p_obj;
$end
    begin
$if dbug.c_trace_leave > 0 $then
      trace('p_depth: ' || p_depth);
$end
      -- adjust for mismatch in enter/leave pairs
      <<find_same_depth_loop>>
      loop
        if l_idx is null
        then
          -- called_from location for leave does not exist in p_obj.call_tab
$if dbug.c_trace_leave > 0 $then
          l_idx := l_obj.call_tab.last;
          while l_idx is not null
          loop
            trace('l_obj.call_tab(' || l_idx || ').called_from: "' || l_obj.call_tab(l_idx).called_from || '"');
            l_idx := l_obj.call_tab.prior(l_idx);
          end loop;
$end
          raise program_error;
        else
$if dbug.c_trace_leave > 0 $then
          trace('l_idx: ' || l_idx);
          trace('p_obj.call_tab(l_idx).called_from: "' || p_obj.call_tab(l_idx).called_from || '"');
          trace('p_obj.call_tab(l_idx).depth: ' || p_obj.call_tab(l_idx).depth);
$end

          if p_obj.call_tab(l_idx).depth = p_depth -- GJP 2023-02-11
          then
            pop_call_stack(p_obj, l_idx, p_leave_on_error);
            exit find_same_depth_loop;
          else
            l_idx := p_obj.call_tab.prior(l_idx);
          end if;
        end if;
      end loop find_same_depth_loop;
    end;
  end leave;

  procedure on_error
  ( p_obj in dbug_obj_t
  , p_function in varchar2
  , p_output in dbug.line_tab_t
  )
  is
    l_line varchar2(100) := null;
    l_line_no pls_integer;
    l_output dbug.line_tab_t;
  begin
    if not check_break_point(p_obj, "error")
    then
      return;
    end if;

    /* dbms_utility.format_error_backtrace may return something like:
     *
     * ORA-06512: at line 30
     * ORA-06512: at line 30
     * ORA-06512: at line 30
     * ORA-06512: at line 11
     * ORA-06512: at line 11
     * ORA-06512: at line 11
     * ORA-06512: at line 11
     *
     * We want to display just:
     *
     * ORA-06512: at line 30
     * ORA-06512: at line 11
     *
     * So unduplicate p_output.
     */

    if p_output.count > 0
    then
      for i_idx in p_output.first .. p_output.last
      loop
        if i_idx = p_output.first or p_output(i_idx) != p_output(i_idx-1)
        then
          l_output(l_output.count + 1) := p_output(i_idx);
        end if;
      end loop;
    end if;

    l_line_no := l_output.first;
    l_line := case when l_output.count > 1 then ' (' || l_line_no || ')' else null end;
    while l_line_no is not null
    loop
      print(p_obj, "error", '%s: %s', p_function || l_line, l_output(l_line_no));
      l_line_no := l_output.next(l_line_no);
      l_line := ' (' || l_line_no || ')';
    end loop;
  exception
    when others
    then
      split(dbms_utility.format_error_backtrace, chr(10), l_output);
      for i_idx in l_output.first .. l_output.last
      loop
        dbms_output.put_line(l_output(i_idx));
      end loop;
      raise;
  end on_error;

  procedure on_error
  ( p_obj in dbug_obj_t
  , p_function in varchar2
  , p_output in varchar2
  , p_sep in varchar2
  )
  is
    l_line_tab line_tab_t;
  begin
    split(p_output, p_sep, l_line_tab);
    on_error(p_obj, p_function, l_line_tab);
  end on_error;

  procedure on_error
  ( p_obj in dbug_obj_t
  )
  is
  begin
    /* Get error information from:
       - sqlerrm
       - dbms_utility.format_error_backtrace
    */   
    on_error(p_obj, 'sqlerrm', sqlerrm, chr(10));
    on_error
    ( p_obj => p_obj
    , p_function => 'dbms_utility.format_error_backtrace'
    , p_output => dbms_utility.format_error_backtrace
    , p_sep => chr(10)
    );
  end on_error;

  procedure leave_on_error
  ( p_obj in out nocopy dbug_obj_t
  , p_depth in integer
  )
  is
  begin
    on_error(p_obj);
    leave(p_obj => p_obj, p_depth => p_depth, p_leave_on_error => true);
  end leave_on_error;

  procedure get_state
  is
    l_dynamic_depth constant pls_integer := utl_call_stack.dynamic_depth;
  begin
$if dbug.c_trace > 1 $then
    trace('>get_state; dynamic depth: ' || l_dynamic_depth);
$end

    -- Re-initialize if session has changed
    init;
    if g_obj is not null
    then
      raise program_error;
    end if;
    g_obj := new dbug_obj_t();

$if dbug.c_trace > 1 $then
    g_obj.print();
    trace('<get_state');
$end
  end get_state;

  procedure set_state(p_print in boolean default false)
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>set_state');
$end

    -- g_obj.store() is intelligent and will store only if dirty has been set or the object has changed
    g_obj.store();

    if p_print
$if dbug.c_trace > 1 $then
       or true
$end    
    then
      g_obj.print();
    end if;
    g_obj := null;

$if dbug.c_trace > 1 $then
    trace('<set_state');
$end
  end set_state;

-- < private (DBUG)
/*
-- > private (DBUG2)

c_indent constant binary_integer := 2;

type t_call_stack_history_tab is table of module_name_t index by binary_integer;

g_call_stack_history_tab t_call_stack_history_tab;

g_prev_call_stack_tab dbug_call_stack.t_call_stack_tab;
g_last_call_stack_tab dbug_call_stack.t_call_stack_tab;

procedure pop_stack
( p_depth in simple_integer
)
is
begin
  for i_depth in reverse p_depth .. g_call_stack_history_tab.count
  loop
    if g_call_stack_history_tab.exists(i_depth)
    then
      dbms_output.put_line(lpad('<', i_depth * c_indent - 1, ' ') || g_call_stack_history_tab(i_depth));
    end if;
  end loop;
  g_call_stack_history_tab.delete(p_depth, g_call_stack_history_tab.count); -- remove entries after this enter call. TO DO: issue leave calls
end pop_stack;

procedure enter
( p_module in module_name_t
, p_depth in binary_integer
)
is
begin
  g_prev_call_stack_tab := g_last_call_stack_tab;
  g_last_call_stack_tab := dbug_call_stack.get_call_stack(p_start => 1, p_size => p_depth);
  pop_stack(p_depth);
  g_call_stack_history_tab(p_depth) := nvl(p_module, dbug_call_stack.repr(g_last_call_stack_tab(g_last_call_stack_tab.last), 1));
  dbms_output.put_line(lpad('>', p_depth * c_indent - 1, ' ') || g_call_stack_history_tab(p_depth));
end enter;

procedure leave
( p_depth in binary_integer
)
is
begin
  g_prev_call_stack_tab := g_last_call_stack_tab;
  g_last_call_stack_tab := dbug_call_stack.get_call_stack(p_start => 1, p_size => p_depth);
  pop_stack(p_depth);
end leave;

-- < private (DBUG2)
*/
-- > public (DBUG)

  procedure done
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>done');
$end

    get_state;
    begin
      done(g_obj);
    exception
      when others
      then
        set_state(p_print => true);
        raise;
    end;
    set_state;

$if dbug.c_trace > 1 $then
    trace('<done');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end done;

  procedure activate
  ( p_method in method_t
  , p_status in boolean
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>activate(''' || p_method || ''', ' || cast_to_varchar2(p_status) || ') (2)');
$end

    get_state;
    begin
      activate(g_obj, p_method, p_status);
    exception
      when others
      then
        set_state(p_print => true);
        raise;
    end;
    set_state;

$if dbug.c_trace > 1 $then
    trace('<activate (2)');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end activate;

  function active
  ( p_method in method_t
  )
  return boolean
  is
    l_result boolean;
  begin
$if dbug.c_trace > 1 $then
    trace('>active(''' || p_method || ''')');
$end

    get_state;
    begin
      l_result := active(g_obj, p_method);
    exception
      when others
      then
        set_state(p_print => true);
        raise;
    end;
    set_state;

$if dbug.c_trace > 1 $then
    trace('<active');
$end

    return l_result;

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      return null;
$end
  end active;

  procedure set_level
  ( p_level in level_t
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>set_level(' || p_level || ')');
$end

    get_state;
    begin
      set_level(g_obj, p_level);
    exception
      when others
      then
        set_state(p_print => true);
        raise;
    end;
    set_state;

$if dbug.c_trace > 1 $then
    trace('<set_level');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end set_level;

  function get_level
  return level_t
  is
    l_result level_t;
  begin
$if dbug.c_trace > 1 $then
    trace('>get_level');
$end

    get_state;
    begin
      l_result := get_level(g_obj);
    exception
      when others
      then
        set_state(p_print => true);
        raise;
    end;
    set_state;

$if dbug.c_trace > 1 $then
    trace('<get_level');
$end

    return l_result;

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      return null;
$end
  end get_level;

  procedure set_break_point_level
  ( p_break_point_level_tab in break_point_level_t
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>set_break_point_level');
$end

    get_state;
    begin
      set_break_point_level(g_obj, p_break_point_level_tab);
    exception
      when others
      then
        set_state(p_print => true);
        raise;
    end;
    set_state;

$if dbug.c_trace > 1 $then
    trace('<set_break_point_level');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end set_break_point_level;

  function get_break_point_level
  return break_point_level_t
  is
    l_result break_point_level_t;
  begin
$if dbug.c_trace > 1 $then
    trace('>get_break_point_level');
$end

    get_state;
    begin
      l_result := get_break_point_level(g_obj);
    exception
      when others
      then
        set_state(p_print => true);
        raise;
    end;
    set_state;

$if dbug.c_trace > 1 $then
    trace('<get_break_point_level');
$end

    return l_result;

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      return l_result; -- return value is a pl/sql array so can not return null
$end
  end get_break_point_level;

  procedure enter
  ( p_module in module_name_t
  , p_depth in integer
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>enter(''' || p_module || ''', ''' || p_depth || ''')');
$end

    get_state;
    begin
      enter(g_obj, p_module, p_depth);
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;

$if dbug.c_trace > 1 $then
    trace('<enter');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end enter;

  procedure leave
  ( p_depth in integer
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>leave(''' || p_depth || ''')');
$end

    get_state;
    begin
      leave(p_obj => g_obj, p_depth => p_depth, p_leave_on_error => false);
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;

$if dbug.c_trace > 1 $then
    trace('<leave');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end leave;

  procedure on_error
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>on_error (1)');
$end

    get_state;
    begin
      on_error(g_obj);
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;

$if dbug.c_trace > 1 $then
    trace('<on_error (1)');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end on_error;

  procedure on_error
  ( p_function in varchar2
  , p_output in varchar2
  , p_sep in varchar2
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>on_error(''' || p_function || ''', ''' || p_output || ''', ''' || p_sep || ''') (2)');
$end

    get_state;
    begin
      on_error
      ( p_obj => g_obj
      , p_function => p_function
      , p_output => p_output
      , p_sep => p_sep
      );
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;

$if dbug.c_trace > 1 $then
    trace('<on_error (2)');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end on_error;

  procedure on_error
  ( p_function in varchar2
  , p_output in dbug.line_tab_t
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>on_error(''' || p_function || ''') (3)');
$end
    get_state;
    begin
      on_error(p_obj => g_obj, p_function => p_function, p_output => p_output);
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;
    
$if dbug.c_trace > 1 $then
    trace('<on_error (3)');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end on_error;

  procedure leave_on_error
  ( p_depth in integer
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>leave_on_error');
$end

    get_state;
    begin
      leave_on_error(g_obj, p_depth);
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;

$if dbug.c_trace > 1 $then
    trace('<leave_on_error');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end leave_on_error;

  function cast_to_varchar2( p_value in boolean )
  return varchar2
  is
  begin
    if p_value then
      return 'TRUE';
    elsif not(p_value) then
      return 'FALSE';
    else
      return 'UNKNOWN';
    end if;
  end cast_to_varchar2;

  procedure print
  ( p_break_point in varchar2
  , p_str in varchar2
  ) is
  begin
$if dbug.c_trace > 1 $then
    trace('>print(''' || p_break_point || ''', ''' || p_str || ''') (1)');
$end

    get_state;
    begin
      print(p_obj => g_obj, p_break_point => p_break_point, p_fmt => '%s', p_arg1 => p_str);
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;
    
$if dbug.c_trace > 1 $then
    trace('<print (1)');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end print;

  procedure print
  ( p_break_point in varchar2
  , p_fmt in varchar2
  , p_arg1 in varchar2
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>print(''' || p_break_point || ''', ''' || p_fmt || ''', ''' || p_arg1 || ''') (2a)');
$end

    get_state;
    begin
      print(g_obj, p_break_point, p_fmt, p_arg1);
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;
    
$if dbug.c_trace > 1 $then
    trace('<print (2a)');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end print;

  procedure print
  ( p_break_point in varchar2
  , p_fmt in varchar2
  , p_arg1 in date
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>print(''' || p_break_point || ''', ''' || p_fmt || ''', ''' || to_char(p_arg1, 'YYYYMMDDHH24MISS') || ''') (2b)');
$end

    get_state;
    begin
      print(g_obj, p_break_point, p_fmt, to_char(p_arg1, 'YYYYMMDDHH24MISS'));
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;
    
$if dbug.c_trace > 1 $then
    trace('<print (2b)');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end print;

  procedure print
  ( p_break_point in varchar2
  , p_fmt in varchar2
  , p_arg1 in boolean
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>print(''' || p_break_point || ''', ''' || p_fmt || ''', ''' || cast_to_varchar2(p_arg1) || ''') (2c)');
$end

    get_state;
    begin
      print(g_obj, p_break_point, p_fmt, cast_to_varchar2(p_arg1));
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;
    
$if dbug.c_trace > 1 $then
    trace('<print (2c)');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end print;

  procedure print
  ( p_break_point in varchar2
  , p_fmt in varchar2
  , p_arg1 in varchar2
  , p_arg2 in varchar2
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>print(''' || p_break_point || ''', ''' || p_fmt || ''', ''' || p_arg1 || ''', ''' || p_arg2 || ''') (3)');
$end

    get_state;
    begin
      print(g_obj, p_break_point, p_fmt, p_arg1, p_arg2);
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;
    
$if dbug.c_trace > 1 $then
    trace('<print (3)');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end print;

  procedure print
  ( p_break_point in varchar2
  , p_fmt in varchar2
  , p_arg1 in varchar2
  , p_arg2 in varchar2
  , p_arg3 in varchar2
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>print(''' || p_break_point || ''', ''' || p_fmt || ''', ''' || p_arg1 || ''', ''' || p_arg2 || ''', ''' || p_arg3 || ''') (4)');
$end

    get_state;
    begin
      print(g_obj, p_break_point, p_fmt, p_arg1, p_arg2, p_arg3);
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;
    
$if dbug.c_trace > 1 $then
    trace('<print (4)');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end print;

  procedure print
  ( p_break_point in varchar2
  , p_fmt in varchar2
  , p_arg1 in varchar2
  , p_arg2 in varchar2
  , p_arg3 in varchar2
  , p_arg4 in varchar2
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>print(''' || p_break_point || ''', ''' || p_fmt || ''', ''' || p_arg1 || ''', ''' || p_arg2 || ''', ''' || p_arg3 || ''', ''' || p_arg4 || ''') (5)');
$end

    get_state;
    begin
      print(g_obj, p_break_point, p_fmt, p_arg1, p_arg2, p_arg3, p_arg4);
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;
    
$if dbug.c_trace > 1 $then
    trace('<print (5)');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end print;

  procedure print
  ( p_break_point in varchar2
  , p_fmt in varchar2
  , p_arg1 in varchar2
  , p_arg2 in varchar2
  , p_arg3 in varchar2
  , p_arg4 in varchar2
  , p_arg5 in varchar2
  )
  is
  begin
$if dbug.c_trace > 1 $then
    trace('>print(''' || p_break_point || ''', ''' || p_fmt || ''', ''' || p_arg1 || ''', ''' || p_arg2 || ''', ''' || p_arg3 || ''', ''' || p_arg4 || ''', ''' || p_arg5 || ''') (6)');
$end

    get_state;
    begin
      print(g_obj, p_break_point, p_fmt, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5);
    exception
      when others
      then
        set_state(p_print => false);
        raise;
    end;
    set_state;
    
$if dbug.c_trace > 1 $then
    trace('<print (6)');
$end

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end print;

  procedure split
  ( p_buf in varchar2
  , p_sep in varchar2
  , p_line_tab out nocopy line_tab_t
  )
  is
    l_pos pls_integer;
    l_prev_pos pls_integer := 1;
    l_length constant pls_integer := nvl(length(p_buf), 0);
  begin
    if p_sep is null
    then
      raise value_error;
    end if;
    
    loop
      exit when l_prev_pos > l_length;

      l_pos := instr(p_buf, p_sep, l_prev_pos);

      if l_pos is null -- p_sep null?
      then
        exit;
      elsif l_pos = 0
      then
        p_line_tab(p_line_tab.count+1) := substr(p_buf, l_prev_pos);
        exit;
      else
        p_line_tab(p_line_tab.count+1) := substr(p_buf, l_prev_pos, l_pos - l_prev_pos);
      end if;

      l_prev_pos := l_pos + length(p_sep);
    end loop;
  end split;

  procedure set_ignore_buffer_overflow
  ( p_value in boolean
  )
  is
  begin
    get_state;
    begin
      g_obj.ignore_buffer_overflow := case p_value when true then 1 when false then 0 else null end;
      g_obj.dirty := 1;
    exception
      when others
      then
        set_state(p_print => true);
        raise;
    end;
    set_state;

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      null;
$end
  end set_ignore_buffer_overflow;

  function get_ignore_buffer_overflow
  return boolean
  is
    l_result boolean := false;
  begin
    get_state;
    begin
      l_result := case g_obj.ignore_buffer_overflow when 1 then true when 0 then false else null end;
    exception
      when others
      then
        set_state(p_print => true);
        raise;
    end;
    set_state;

    return l_result;

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      return null;
$end
  end get_ignore_buffer_overflow;

  function get_depth
  return integer
  is
    l_dbug_obj dbug_obj_t;
  begin
    l_dbug_obj := new dbug_obj_t();
    return l_dbug_obj.call_tab.count;
  exception
    when others
    then return 0;
  end get_depth;

  function format_enter
  ( p_module in module_name_t
  )
  return varchar2
  is
    l_indent varchar2(32767) := null;
  begin
    -- g_obj must have been set by one of the enter/leave/print routines
    -- return rpad( c_indent, g_obj.indent_level*length(c_indent), c_indent ) || '>' || p_module;
    for i_idx in 1 .. g_obj.indent_level
    loop
      l_indent := l_indent || c_indent;
    end loop;
    
    return l_indent || '>' || p_module;

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      return null;
$end
  end format_enter;

  function format_leave
  return varchar2
  is
    l_indent varchar2(32767) := null;
  begin
    -- g_obj must have been set by one of the enter/leave/print routines.
    -- pop_call_stack will maintain the right call_tab even though some leaves have been missing.
    -- return rpad( c_indent, g_obj.indent_level*length(c_indent), c_indent ) || '<' || g_obj.call_tab(g_obj.call_tab.last).module_name;
    for i_idx in 1 .. g_obj.indent_level
    loop
      l_indent := l_indent || c_indent;
    end loop;
    
    return l_indent || '<' || g_obj.call_tab(g_obj.call_tab.last).module_name;

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      return null;
$end
  end format_leave;

  function format_print
  ( p_break_point in varchar2
  , p_fmt in varchar2
  , p_nr_arg in pls_integer
  , p_arg1 in varchar2
  , p_arg2 in varchar2 default null
  , p_arg3 in varchar2 default null
  , p_arg4 in varchar2 default null
  , p_arg5 in varchar2 default null
  )
  return varchar2
  is
    l_pos pls_integer;
    l_arg varchar2(32767);
    l_str varchar2(32767);
    l_arg_nr pls_integer;
  begin
    -- g_obj must have been set by one of the enter/leave/print routines
    l_pos := 1;
    l_str := p_fmt;
    l_arg_nr := 1;
    loop
      l_pos := instr(l_str, '%s', l_pos);

      /* stop if '%s' is not found or when the arguments have been exhausted */
      exit when l_pos is null or l_pos = 0 or l_arg_nr > p_nr_arg;

      l_arg :=
        case l_arg_nr
          when 1 then p_arg1
          when 2 then p_arg2
          when 3 then p_arg3
          when 4 then p_arg4
          when 5 then p_arg5
        end;

      if l_arg is null then l_arg := c_null; end if;

      /* '%s' is two characters long so replace substr from 1 till l_pos+1 */
      l_str :=
        replace( substr(l_str, 1, l_pos+1), '%s', l_arg ) ||
        substr( l_str, l_pos+2 );

      /* '%s' is replaced  by l_arg hence continue at position after
         substituted string */
      l_pos := l_pos + 1 + nvl(length(l_arg), 0) - 2 /* '%s' */;
      l_arg_nr := l_arg_nr + 1;
    end loop;

    l_str :=
      rpad( c_indent, g_obj.indent_level*length(c_indent), c_indent ) ||
      p_break_point ||
      ': ' ||
      l_str;

    return l_str;

$if dbug.c_ignore_errors != 0 $then
  exception
    when others
    then
      return null;
$end
  end format_print;

-- < public (DBUG)

/*
-- > public (DBUG2)

procedure enter
( p_module in module_name_t
)
is
begin
  enter(p_module => p_module, p_depth => utl_call_stack.dynamic_depth - 1);
end enter;

procedure leave
is
begin
  leave(p_depth => utl_call_stack.dynamic_depth - 1);
end leave;

procedure on_error
is
  l_error_stack_tab dbug_call_stack.t_error_stack_tab;
  l_backtrace_stack_tab dbug_call_stack.t_backtrace_stack_tab;
begin
  dbms_output.put_line('== error stack');
  l_error_stack_tab :=
    dbug_call_stack.get_error_stack
    ( p_start => 1 -- You can use -1 like the POSITION parameter in the SUBSTR() function
    , p_size => utl_call_stack.error_depth
    );
  if l_error_stack_tab.count > 0
  then
    for i_idx in l_error_stack_tab.first .. l_error_stack_tab.last
    loop
      dbms_output.put_line(dbug_call_stack.repr(l_error_stack_tab(i_idx)));
    end loop;
  end if;
  dbms_output.put_line('== backtrace stack');
  l_backtrace_stack_tab :=
    dbug_call_stack.get_backtrace_stack
    ( p_start => 1 -- You can use -1 like the POSITION parameter in the SUBSTR() function
    , p_size => utl_call_stack.backtrace_depth
    );
  if l_backtrace_stack_tab.count > 0
  then
    for i_idx in l_backtrace_stack_tab.first .. l_backtrace_stack_tab.last
    loop
      dbms_output.put_line(dbug_call_stack.repr(l_backtrace_stack_tab(i_idx)));
    end loop;
  end if;
end on_error;

procedure leave_on_error
is
begin
  on_error;
  leave(p_depth => utl_call_stack.dynamic_depth - 1);
end leave_on_error;

procedure print
( p_break_point in break_point_t
, p_str in varchar2
)
is
begin
  dbms_output.put_line(p_str);
end print;

-- < public (DBUG2)
*/

END DBUG;
/

