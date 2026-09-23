CREATE OR REPLACE PACKAGE BODY "DBUG_LOGGER" IS

  procedure print(
    p_break_point in varchar2,
    p_str in varchar2
  ) is
    l_line_tab dbug.line_tab_t;
    l_line_no pls_integer;
  begin
    dbug.split(p_str, chr(10), l_line_tab);

    l_line_no := l_line_tab.first;
    while l_line_no is not null
    loop
      begin
        case p_break_point
          when dbug."debug"
          then logger.log( l_line_tab(l_line_no) );
          when dbug."trace"
          then logger.log( l_line_tab(l_line_no) );
          when dbug."input"
          then logger.log( l_line_tab(l_line_no) );
          when dbug."output"
          then logger.log( l_line_tab(l_line_no) );
          when dbug."info"
          then logger.log_info( l_line_tab(l_line_no) );
          when dbug."warning"
          then logger.log_warn( l_line_tab(l_line_no) );
          when dbug."error"
          then logger.log_error( l_line_tab(l_line_no) );
          when dbug."fatal"
          then logger.log_permanent( l_line_tab(l_line_no) );
          else logger.log( l_line_tab(l_line_no) );
        end case;
      end;
      l_line_no := l_line_tab.next(l_line_no);
    end loop;
  end print;

  /* global modules */

  procedure done
  is
  begin
    null;
  end done;

  procedure enter(
    p_module in dbug.module_name_t
  ) is
  begin
    print( dbug."info", dbug.format_enter(p_module) ); -- dbms_output.put_line supports 32767 bytes
  end enter;

  procedure leave
  is
  begin
    print( dbug."info", dbug.format_leave ); -- dbms_output.put_line supports 32767 bytes
  end leave;

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2
  ) is
  begin
    print( p_break_point, dbug.format_print(p_break_point, p_fmt, 1, p_arg1) );
  end print;

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2,
    p_arg2 in varchar2
  ) is
  begin
    print( p_break_point, dbug.format_print(p_break_point, p_fmt, 2, p_arg1, p_arg2) );
  end print;

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2,
    p_arg2 in varchar2,
    p_arg3 in varchar2
  ) is
  begin
    print( p_break_point, dbug.format_print(p_break_point, p_fmt, 3, p_arg1, p_arg2, p_arg3) );
  end print;

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2,
    p_arg2 in varchar2,
    p_arg3 in varchar2,
    p_arg4 in varchar2
  ) is
  begin
    print( p_break_point, dbug.format_print(p_break_point, p_fmt, 4, p_arg1, p_arg2, p_arg3, p_arg4) );
  end print;

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2,
    p_arg2 in varchar2,
    p_arg3 in varchar2,
    p_arg4 in varchar2,
    p_arg5 in varchar2
  ) is
  begin
    print( p_break_point, dbug.format_print(p_break_point, p_fmt, 5, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5) );
  end print;

end dbug_logger;
/

