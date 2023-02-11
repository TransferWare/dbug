CREATE OR REPLACE PACKAGE BODY "DBUG2" IS

-- private

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

-- public

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

END DBUG2;
/

