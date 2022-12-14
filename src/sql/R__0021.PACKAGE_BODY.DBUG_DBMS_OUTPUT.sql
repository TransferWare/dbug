CREATE OR REPLACE PACKAGE BODY "DBUG_DBMS_OUTPUT" IS

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
    dbms_output.put_line( dbug.format_enter(p_module) ); -- dbms_output.put_line supports 32767 bytes
  end enter;

  procedure leave
  is
  begin
    dbms_output.put_line( dbug.format_leave ); -- dbms_output.put_line supports 32767 bytes
  end leave;

  procedure print( p_str in varchar2 )
  is
    l_line_tab dbug.line_tab_t;
    l_line_no pls_integer;
  begin
    dbug.split(p_str, chr(10), l_line_tab);

    l_line_no := l_line_tab.first;
    while l_line_no is not null
    loop
      begin
        dbms_output.put_line( l_line_tab(l_line_no) ); -- dbms_output.put_line supports 32767 bytes
      end;
      l_line_no := l_line_tab.next(l_line_no);
    end loop;
  end print;

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2
  ) is
  begin
    print( dbug.format_print(p_break_point, p_fmt, 1, p_arg1) );
  end print;

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2,
    p_arg2 in varchar2
  ) is
  begin
    print( dbug.format_print(p_break_point, p_fmt, 2, p_arg1, p_arg2) );
  end print;

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2,
    p_arg2 in varchar2,
    p_arg3 in varchar2
  ) is
  begin
    print( dbug.format_print(p_break_point, p_fmt, 3, p_arg1, p_arg2, p_arg3) );
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
    print( dbug.format_print(p_break_point, p_fmt, 4, p_arg1, p_arg2, p_arg3, p_arg4) );
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
    print( dbug.format_print(p_break_point, p_fmt, 5, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5) );
  end print;

  procedure ut_store_remove
  is
  begin
    null;
  end;

  procedure ut_dbug_dbms_output
  is
    l_lines_exp constant sys.odcivarchar2list :=
      sys.odcivarchar2list
      ( '>main'
      , '|   >f3'
      , '|   |   >f2'
      , '|   |   |   >f1'
      , '|   |   |   |   >f1'
      , '|   |   |   |   |   >f1'
      , '|   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   |   <f1'
      , '|   |   |   |   |   |   |   <f1'
      , '|   |   |   |   |   |   <f1'
      , '|   |   |   |   |   <f1'
      , '|   |   |   |   <f1'
      , '|   |   |   <f1'
      , '|   |   <f2'
      , '|   <f3'
      , '<main'
      );

    procedure chk
    is
      l_lines_act dbms_output.chararr;
      l_numlines integer := l_lines_exp.count; -- the number of lines to retrieve
    begin
      dbms_output.get_lines(lines => l_lines_act, numlines => l_numlines);
      ut.expect(l_numlines, '# lines').to_equal(l_lines_exp.count);
      ut.expect(l_lines_act.first, 'lines first').to_equal(l_lines_exp.first);
      for i_idx in l_lines_exp.first .. l_lines_exp.last
      loop
        ut.expect(l_lines_act(i_idx), to_char(i_idx)).to_equal(l_lines_exp(i_idx));
      end loop;
    end chk;
  begin
    dbms_output.disable; -- clear the buffer
    dbms_output.enable;
    
    for i_idx in l_lines_exp.first .. l_lines_exp.last
    loop
      dbms_output.put_line(l_lines_exp(i_idx));
    end loop;    
    chk;
  end ut_dbug_dbms_output;

end dbug_dbms_output;
/

