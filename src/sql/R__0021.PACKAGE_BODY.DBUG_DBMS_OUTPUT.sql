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

$if ut_dbug.c_testing $then

  procedure ut_setup
  is
  begin
    dbms_output.disable; -- clear the buffer
    dbms_output.enable(5000);

    dbug.activate('dbms_output');
  end ut_setup;
  
  procedure ut_teardown
  is
  begin
    dbug.activate('dbms_output', false);
  end ut_teardown;

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
      -- l_numlines integer := l_lines_exp.count; -- the number of lines to retrieve
      l_numlines integer := power(2, 31); /* maximum nr of lines to retrieve */
    begin
      dbms_output.get_lines(lines => l_lines_act, numlines => l_numlines);
      ut.expect(l_numlines, '# lines').to_equal(l_lines_exp.count);
      ut.expect(l_lines_act.first, 'lines first').to_equal(l_lines_exp.first);
      for i_idx in l_lines_exp.first .. l_lines_exp.last
      loop
        ut.expect(l_lines_act(i_idx), to_char(i_idx)).to_equal(l_lines_exp(i_idx));
      end loop;
    end chk;

    procedure main
    is
      procedure f3
      is
        procedure f2
        is
          procedure f1
          ( p_count in positiven
          )
          is
          begin
            dbug.enter('f1');
            begin
              f1(p_count - 1);
            exception
              when value_error
              then null;
            end;
            dbug.leave;        
          end f1;
        begin
          dbug.enter('f2');
          f1(6);
          dbug.leave;        
        end f2;
      begin
        dbug.enter('f3');
        f2;
        dbug.leave;        
      end f3;
    begin
      dbug.enter('main');
      f3;
      dbug.leave;
    end main;
  begin
    for i_idx in l_lines_exp.first .. l_lines_exp.last
    loop
      dbms_output.put_line(l_lines_exp(i_idx));
    end loop;
    chk;
    
    dbms_output.disable; -- clear the buffer
    dbms_output.enable;
    main;
    chk;
  end ut_dbug_dbms_output;

  procedure ut_set_ignore_buffer_overflow
  is
  begin
    for i_case in -1 .. 1
    loop
      dbug.set_ignore_buffer_overflow(case i_case when -1 then null when 0 then false when 1 then true end);
      case i_case
        when -1 then ut.expect(dbug.get_ignore_buffer_overflow, i_case).to_be_null();
        when  0 then ut.expect(dbug.get_ignore_buffer_overflow, i_case).to_be_false();
        when +1 then ut.expect(dbug.get_ignore_buffer_overflow, i_case).to_be_true();
      end case;
    end loop;
  end ut_set_ignore_buffer_overflow;

  procedure ut_ignore_buffer_overflow
  is
    l_lines_exp sys.odcivarchar2list := null;

    -- when buffer is ignored the buffer is emptied, error and format call stack printed and then printing will continue

    procedure chk(p_case in positiven)
    is
      l_lines_act dbms_output.chararr;
      -- l_numlines integer := l_lines_exp.count; -- the number of lines to retrieve
      l_numlines integer := power(2, 31); /* maximum nr of lines to retrieve */
    begin
      dbms_output.get_lines(lines => l_lines_act, numlines => l_numlines);
      ut.expect(l_numlines, '# lines; case: ' || p_case).to_equal(case p_case when 1 then 25 else 54 end);
      ut.expect(l_lines_act.first, 'lines first; case: ' || p_case).to_equal(l_lines_exp.first);
      if dbug.get_ignore_buffer_overflow
      then
        ut.expect(l_lines_act(1), 'case: ' || p_case)
        .to_equal('ERROR: dbug_dbms_output.print(:0, :1, :2): ORA-20000: ORU-10027: buffer overflow, limit of 5000 bytes');
        for i_idx in 1 .. l_numlines - 1
        loop
          if substr(l_lines_act(i_idx), 1, 1) in ('|') -- printing continued
          then
            ut.expect(l_lines_act(i_idx), 'idx: ' || i_idx || '; case: ' || p_case).to_equal(l_lines_exp(l_lines_exp.last - (l_numlines - i_idx)));
          end if;
        end loop;
      else
        for i_idx in 1 .. l_numlines - 1
        loop
          ut.expect(l_lines_act(i_idx), 'idx: ' || i_idx || '; case: ' || p_case).to_equal(l_lines_exp(i_idx));
        end loop;
      end if;
      ut.expect(l_lines_act(l_numlines), 'idx: ' || l_numlines || '; case: ' || p_case).to_equal('<main');
    end chk;
  begin
    for i_case in 1..2
    loop
      begin
        dbms_output.disable; -- clear the buffer
        dbms_output.enable(5000);
        dbug.set_ignore_buffer_overflow(i_case = 1); -- ignore buffer overflow true / false
        dbug.enter('main');
        l_lines_exp := sys.odcivarchar2list();
        l_lines_exp.extend(1);
        l_lines_exp(l_lines_exp.last) := '>main';
        for i_idx in 1..1000
        loop
          l_lines_exp.extend(1);
          l_lines_exp(l_lines_exp.last) := utl_lms.format_message('%s:%s:%s', to_char(i_case), rpad('x', 80, 'x'), to_char(i_idx));
          dbug.print('info', l_lines_exp(l_lines_exp.last));
          l_lines_exp(l_lines_exp.last) := '|   info: ' || l_lines_exp(l_lines_exp.last);
        end loop;
        dbug.leave;
        l_lines_exp.extend(1);
        l_lines_exp(l_lines_exp.last) := '<main';
      end;
      
      chk(i_case);
    end loop;  
  end ut_ignore_buffer_overflow;

$end

end dbug_dbms_output;
/

