CREATE OR REPLACE PACKAGE BODY "DBUG_PROFILER" AS

$if dbms_db_version.ver_le_10 $then

subtype simple_integer is pls_integer;

$end

-- implementation details
subtype t_time_ms is simple_integer; -- elapsed time in milliseconds

subtype t_count is simple_integer;

type t_count_tab is table of t_count index by dbug.module_name_t;

type t_time_ms_tab is table of t_time_ms index by dbug.module_name_t;

type t_module_name_stack is table of dbug.module_name_t index by pls_integer;

g_count_tab t_count_tab;
g_time_ms_tab t_time_ms_tab;
g_module_name_stack t_module_name_stack;
g_timestamp t_timestamp := null;

-- LOCAL ROUTINES
$if dbug_profiler.c_testing $then

procedure sleep(p_seconds in number)
is
begin
$if dbms_db_version.version >= 18 $then
  dbms_session.sleep(p_seconds);
$else
  dbms_lock.sleep(p_seconds);
$end
end;

$end -- $if dbug_profiler.c_testing $then

procedure start_timer
( p_timestamp in t_timestamp
)
is
begin
/*DBUG
  dbms_output.put_line('>start_timer');
  dbms_output.put_line('p_timestamp: ' || to_char(p_timestamp, 'yyyy-mm-dd hh24:mi:ss.ff'));
/*DBUG*/  
  if g_timestamp is not null
  then
    raise program_error;
  end if;
  g_timestamp := p_timestamp;
/*DBUG
  dbms_output.put_line('<start_timer');
/*DBUG*/
end start_timer;

function end_timer
( p_timestamp in t_timestamp
)
return t_time_ms
is
  l_diff_timestamp constant interval day to second := p_timestamp - g_timestamp;
  l_time_ms constant t_time_ms :=
    1000 * extract(day    from l_diff_timestamp) * 24 * 60 * 60 +
    1000 * extract(hour   from l_diff_timestamp) * 60 * 60 +
    1000 * extract(minute from l_diff_timestamp) * 60 +
    round(1000 * extract(second from l_diff_timestamp));
begin
/*DBUG
  dbms_output.put_line('>end_timer');
  dbms_output.put_line('g_timestamp: ' || to_char(g_timestamp, 'yyyy-mm-dd hh24:mi:ss.ff'));
  dbms_output.put_line('p_timestamp: ' || to_char(p_timestamp, 'yyyy-mm-dd hh24:mi:ss.ff'));
  dbms_output.put_line('l_time_ms: ' || l_time_ms);
  dbms_output.put_line('<end_timer');
/*DBUG*/  
  g_timestamp := null;
  return l_time_ms;
end end_timer;

-- GLOBAL ROUTINES
procedure enter(
  p_module in dbug.module_name_t
, p_timestamp in t_timestamp
)
is
begin
/*DBUG
  dbms_output.put_line('>enter');
  dbms_output.put_line('p_module: ' || p_module);
  dbms_output.put_line('p_timestamp: ' || to_char(p_timestamp, 'yyyy-mm-dd hh24:mi:ss.ff'));
/*DBUG*/
  
  -- stop timing for the previous module and add the elapsed time to it
  if g_module_name_stack.last is not null
  then
    begin
      g_time_ms_tab(g_module_name_stack(g_module_name_stack.last)) := g_time_ms_tab(g_module_name_stack(g_module_name_stack.last)) + end_timer(p_timestamp);
    exception
      when no_data_found
      then
/*DBUG
        dbms_output.put_line('no_data_found');
/*DBUG*/        
        g_time_ms_tab(g_module_name_stack(g_module_name_stack.last)) := 0;
    end;
  end if;

  -- add this module to the stack
  g_module_name_stack(g_module_name_stack.count+1) := p_module;

  -- initialise this module if necessary
  if not g_count_tab.exists(p_module)
  then
    g_count_tab(p_module) := 0;
    g_time_ms_tab(p_module) := 0;
  end if;

  -- start the timer for this module
  start_timer(p_timestamp);
/*DBUG
  dbms_output.put_line('<enter');
/*DBUG*/  
end enter;

procedure leave
( p_timestamp in t_timestamp
)
is
begin
/*DBUG
  dbms_output.put_line('>leave');
  dbms_output.put_line('p_timestamp: ' || to_char(p_timestamp, 'yyyy-mm-dd hh24:mi:ss.ff'));
/*DBUG*/
  if g_module_name_stack.last is not null
  then
    -- stop the timer and add the elapsed time to the current module
    begin
      g_time_ms_tab(g_module_name_stack(g_module_name_stack.last)) := g_time_ms_tab(g_module_name_stack(g_module_name_stack.last)) + end_timer(p_timestamp);
    exception
      when no_data_found
      then
/*DBUG
        dbms_output.put_line('no_data_found');
/*DBUG*/      
        g_time_ms_tab(g_module_name_stack(g_module_name_stack.last)) := 0;
    end;
    -- increase the count as well
    g_count_tab(g_module_name_stack(g_module_name_stack.last)) := g_count_tab(g_module_name_stack(g_module_name_stack.last)) + 1;
    -- delete the module from the stack
    g_module_name_stack.delete(g_module_name_stack.last);
    -- if there was a previous module start the timer again for that module
    if g_module_name_stack.last is not null
    then
      start_timer(p_timestamp);
    end if;
  end if;    
/*DBUG
  dbms_output.put_line('<leave');
/*DBUG*/  
end leave;

procedure done
is
begin
  g_count_tab.delete;
  g_time_ms_tab.delete;
  g_module_name_stack.delete;
  g_timestamp := null;
end done;

function show
return t_profiler_tab pipelined
is
  l_profiler_rec t_profiler_rec;
  l_line_tab dbug.line_tab_t;
begin
  l_profiler_rec.module_name := g_time_ms_tab.first;
  while l_profiler_rec.module_name is not null
  loop
    l_profiler_rec.module_name_part1 := null;
    l_profiler_rec.module_name_part2 := null;
    l_profiler_rec.module_name_part3 := null;
    l_profiler_rec.module_name_rest  := null;
    
    dbug.split
    ( p_buf => l_profiler_rec.module_name
    , p_sep => '.'
    , p_line_tab => l_line_tab
    );
    if l_line_tab.count > 0
    then
      for i_idx in l_line_tab.first .. l_line_tab.last
      loop
        case i_idx
          when l_line_tab.first+0
          then l_profiler_rec.module_name_part1 := l_line_tab(i_idx);
          when l_line_tab.first+1
          then l_profiler_rec.module_name_part2 := l_line_tab(i_idx);
          when l_line_tab.first+2
          then l_profiler_rec.module_name_part3 := l_line_tab(i_idx);
          when l_line_tab.first+3
          then l_profiler_rec.module_name_rest  := l_line_tab(i_idx);
          else l_profiler_rec.module_name_rest  := l_profiler_rec.module_name_rest || '.' || l_line_tab(i_idx);
        end case;
      end loop;
    end if;
    l_profiler_rec.nr_calls := g_count_tab(l_profiler_rec.module_name);
    l_profiler_rec.elapsed_time := round(g_time_ms_tab(l_profiler_rec.module_name) / 1000, 3);
    l_profiler_rec.avg_time := case when l_profiler_rec.nr_calls <> 0 then round(l_profiler_rec.elapsed_time / l_profiler_rec.nr_calls, 3) end;
    pipe row (l_profiler_rec);
    l_profiler_rec.module_name := g_time_ms_tab.next(l_profiler_rec.module_name);
  end loop;
  return;
end show;

function show
( p_module_name_part1 in varchar2
, p_module_name_part2 in varchar2
, p_module_name_part3 in varchar2
)
return varchar2
sql_macro
is
begin
  return q'[
with src as (
  select  t.module_name_part1
  ,       t.module_name_part2
  ,       t.module_name_part3
  ,       t.module_name_rest
  ,       sum(t.nr_calls) as nr_calls
  ,       round(sum(t.elapsed_time), 3) as elapsed_time
  ,       round(avg(t.elapsed_time), 3) as avg_time
  ,       grouping_id(t.module_name_part1, t.module_name_part2, t.module_name_part3, t.module_name_rest) as grouping
  from    table(dbug_profiler.show) t
  group by
          rollup
          ( t.module_name_part1
          , t.module_name_part2
          , t.module_name_part3
          , t.module_name_rest
          )
), totals_different as (
  select  t.module_name_part1
  ,       t.module_name_part2
  ,       t.module_name_part3
  ,       t.module_name_rest
  ,       t.nr_calls
  ,       t.elapsed_time
  ,       t.avg_time 
  from    src t
  where   t.grouping > 0
  minus
  select  t.module_name_part1
  ,       t.module_name_part2
  ,       t.module_name_part3
  ,       t.module_name_rest
  ,       t.nr_calls
  ,       t.elapsed_time
  ,       t.avg_time 
  from    src t
  where   t.grouping = 0
)
select  t.module_name_part1
,       t.module_name_part2
,       t.module_name_part3
,       t.module_name_rest
,       '' as total
,       t.nr_calls
,       t.elapsed_time
,       t.avg_time 
from    src t
where   grouping = 0
and     ( show.p_module_name_part1 is null or t.module_name_part1 like show.p_module_name_part1 escape '\' )
and     ( show.p_module_name_part2 is null or t.module_name_part2 like show.p_module_name_part2 escape '\' )
and     ( show.p_module_name_part3 is null or t.module_name_part3 like show.p_module_name_part3 escape '\' )
union
select  t.module_name_part1
,       t.module_name_part2
,       t.module_name_part3
,       t.module_name_rest
,       '*** total ***' as total
,       t.nr_calls
,       t.elapsed_time
,       t.avg_time
from    totals_different t
where   ( show.p_module_name_part1 is null or t.module_name_part1 is null or t.module_name_part1 like show.p_module_name_part1 escape '\' )
and     ( show.p_module_name_part2 is null or t.module_name_part2 is null or t.module_name_part2 like show.p_module_name_part2 escape '\' )
and     ( show.p_module_name_part3 is null or t.module_name_part3 is null or t.module_name_part3 like show.p_module_name_part3 escape '\' )
order by
        module_name_part1
,       module_name_part2
,       module_name_part3
,       module_name_rest
,       total nulls first
  ]';
end show;

procedure show
is
  l_profiler_rec t_profiler_rec;
begin
  dbms_output.put_line('>show');
  
  l_profiler_rec.module_name := g_time_ms_tab.first;
  while l_profiler_rec.module_name is not null
  loop
    l_profiler_rec.nr_calls := g_count_tab(l_profiler_rec.module_name);
    l_profiler_rec.elapsed_time := round(g_time_ms_tab(l_profiler_rec.module_name) / 1000, 3);
    l_profiler_rec.avg_time := case when l_profiler_rec.nr_calls <> 0 then round(l_profiler_rec.elapsed_time / l_profiler_rec.nr_calls, 3) end;

    dbms_output.put_line('=== ' || l_profiler_rec.module_name || ' ===');
    dbms_output.put_line('nr_calls: ' || l_profiler_rec.nr_calls);
    dbms_output.put_line('elapsed_time: ' || l_profiler_rec.elapsed_time);
    dbms_output.put_line('avg_time: ' || l_profiler_rec.avg_time);

    l_profiler_rec.module_name := g_time_ms_tab.next(l_profiler_rec.module_name);
  end loop;

  dbms_output.put_line('<show');
end show;

-- necessary functions for the dbug interface but they do nothing
procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2
)
is
begin
  null;
end print;

procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2,
  p_arg2 in varchar2
)
is
begin
  null;
end print;

procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2,
  p_arg2 in varchar2,
  p_arg3 in varchar2
)
is
begin
  null;
end print;

procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2,
  p_arg2 in varchar2,
  p_arg3 in varchar2,
  p_arg4 in varchar2
)
is
begin
  null;
end print;

procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2,
  p_arg2 in varchar2,
  p_arg3 in varchar2,
  p_arg4 in varchar2,
  p_arg5 in varchar2
)
is
begin
  null;
end print;

$if dbug_profiler.c_testing $then

-- test procedures
procedure ut_setup
is
begin
  null;
end ut_setup;

procedure ut_teardown
is
begin
  show;
  done;
end ut_teardown;

procedure ut_test
is
  procedure p1
  is
  begin
    dbug.enter('p1');
    sleep(0);
    dbug.leave;
  end p1;

  procedure p2
  is
  begin
    dbug.enter('p2');
    sleep(1);
    p1;
    sleep(2);
    raise value_error;
    dbug.leave;
  exception
    when value_error
    then dbug.leave_on_error; -- no reraise, just to show that this invokes dbug_profiler.leave too
  end p2;

  procedure p3
  is
  begin
    dbug.enter('p3');
    sleep(3);
    p2;
    sleep(4);
    dbug.leave;
  end p3;
begin
  dbug.activate('dbms_output');
  dbug.activate('profiler');

  p3;
  sleep(5); -- should not count
  p3;

  for r in (select * from table(dbug_profiler.show))
  loop
    dbms_output.put_line('module_name: ' || r.module_name);
    dbms_output.put_line('nr_calls: ' || r.nr_calls);
    dbms_output.put_line('elapsed_time: ' || r.elapsed_time);
    dbms_output.put_line('avg_time: ' || r.avg_time);

    ut.expect(r.nr_calls, r.module_name).to_equal(2);
    ut.expect(trunc(r.avg_time), r.module_name).to_equal(case r.module_name when 'p1' then 0 when 'p2' then 3 when 'p3' then 7 end);
    ut.expect(trunc(r.elapsed_time, 3), r.module_name).to_equal(trunc(r.nr_calls * r.avg_time, 3));
  end loop;
end ut_test;

$else

procedure ut_setup
is
begin
  null;
end;

procedure ut_teardown
is
begin
  null;
end;

procedure ut_test
is
begin
  null;
end;

$end -- $if dbug_profiler.c_testing $then

end dbug_profiler;
/

