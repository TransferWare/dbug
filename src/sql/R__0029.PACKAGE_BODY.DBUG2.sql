CREATE OR REPLACE PACKAGE BODY "DBUG2" IS

-- private

type t_call_stack_history_tab is table of oracle_tools.api_call_stack_pkg.t_call_stack_tab index by binary_integer;

g_call_stack_history_tab t_call_stack_history_tab;

procedure pop_stack
( p_depth in simple_integer
)
is
begin
  for i_idx in reverse p_depth .. g_call_stack_history_tab.count
  loop
    dbms_output.put_line('== <'|| oracle_tools.api_call_stack_pkg.repr(g_call_stack_history_tab(i_idx)(g_call_stack_history_tab(i_idx).last)));
  end loop;
  g_call_stack_history_tab.delete(p_depth, g_call_stack_history_tab.count); -- remove entries after this enter call. TO DO: issue leave calls
end pop_stack;

procedure enter
( p_module in module_name_t
, p_size_decrement in pls_integer
)
is
  l_call_stack_tab oracle_tools.api_call_stack_pkg.t_call_stack_tab;
  l_depth constant simple_integer := utl_call_stack.dynamic_depth - p_size_decrement;
begin
  l_call_stack_tab := oracle_tools.api_call_stack_pkg.get_call_stack(p_start => 1, p_size => l_depth);
  g_call_stack_history_tab(l_depth) := l_call_stack_tab;
  pop_stack(l_depth + 1);
  dbms_output.put_line('>' || p_module || ':' || oracle_tools.api_call_stack_pkg.repr(l_call_stack_tab(l_call_stack_tab.last)));
end enter;

procedure leave
( p_size_decrement in pls_integer
)
is
  l_call_stack_tab oracle_tools.api_call_stack_pkg.t_call_stack_tab;
  l_depth simple_integer := utl_call_stack.dynamic_depth - p_size_decrement;
begin  
  l_call_stack_tab := oracle_tools.api_call_stack_pkg.get_call_stack(p_start => 1, p_size => l_depth);
  pop_stack(l_depth + 1);
  dbms_output.put_line('<' || oracle_tools.api_call_stack_pkg.repr(l_call_stack_tab(l_call_stack_tab.last)));
end leave;

-- public

procedure enter
( p_module in module_name_t
)
is
begin
  dbms_output.put_line('-- dbug2.enter' || '('|| p_module || ')');
  enter(p_module, 2);
end enter;

procedure leave
is
begin
  dbms_output.put_line('-- dbug2.leave');
  leave(2);
end leave;

procedure on_error
is
  l_error_stack_tab oracle_tools.api_call_stack_pkg.t_error_stack_tab;
  l_backtrace_stack_tab oracle_tools.api_call_stack_pkg.t_backtrace_stack_tab;
begin
  dbms_output.put_line('-- dbug2.on_error');
  dbms_output.put_line('== error stack');
  l_error_stack_tab :=
    oracle_tools.api_call_stack_pkg.get_error_stack
    ( p_start => 1 -- You can use -1 like the POSITION parameter in the SUBSTR() function
    , p_size => utl_call_stack.error_depth
    );
  if l_error_stack_tab.count > 0
  then
    for i_idx in l_error_stack_tab.first .. l_error_stack_tab.last
    loop
      dbms_output.put_line(oracle_tools.api_call_stack_pkg.repr(l_error_stack_tab(i_idx)));
    end loop;
  end if;
  dbms_output.put_line('== backtrace stack');
  l_backtrace_stack_tab :=
    oracle_tools.api_call_stack_pkg.get_backtrace_stack
    ( p_start => 1 -- You can use -1 like the POSITION parameter in the SUBSTR() function
    , p_size => utl_call_stack.backtrace_depth
    );
  if l_backtrace_stack_tab.count > 0
  then
    for i_idx in l_backtrace_stack_tab.first .. l_backtrace_stack_tab.last
    loop
      dbms_output.put_line(oracle_tools.api_call_stack_pkg.repr(l_backtrace_stack_tab(i_idx)));
    end loop;
  end if;
end on_error;

procedure leave_on_error
is
begin
  dbms_output.put_line('-- dbug2.leave_on_error');
  on_error;
  leave(2);
end leave_on_error;
    
procedure print
( p_break_point in break_point_t
, p_str in varchar2
)
is
begin
  dbms_output.put_line('-- dbug2.print');
  dbms_output.put_line(p_str);
end print;  
    
END DBUG2;
/

