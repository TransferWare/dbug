CREATE OR REPLACE PACKAGE BODY "UT_DBUG" IS

$if ut_dbug.c_testing $then

  -- DO NEVER CHANGE THE LOCATION OF THIS ROUTINE otherwise you have to check output of ut_leave_dbms_output/ut_leave_log4plsql
  /*
  -- This is the default behaviour for functions f1, f2, f3 and the main block:
  -- a) f2 does not handle exceptions
  -- b) in other funcions every dbug.enter is (eventually) followed by 
  --    a call to dbug.leave (or dbug.leave_on_error in an exception block)
  -- c) f1 raises an exception when :testcase is even because the recursion does not stop correctly

  -- These are the testcases:
  -- 1) all goes well
  -- 2) function f1 only leaves correctly when no exception occurs
  -- 3) function f1 only leaves correctly when an exception occurs
  -- 4) function f1 never leaves correctly
  -- 5) function f3 never leaves correctly
  -- 6) the main block only leaves correctly when no exception occurs
  -- 7) the main block only leaves correctly when an exception occurs
  -- 8) the main block never leaves correctly
  -- 9) all goes well but dbug.leave_on_error is called in main block (not in the exception block)
  */
  procedure leave
  ( p_testcase in positiven
  )
  is
    procedure f1(i_count natural := 5)
    is
    begin
      dbug.enter('f1');
      if mod(p_testcase, 2) = 1 and i_count = 0
      then
        null;
      else
        f1(i_count-1); -- since i_count is natural (>= 0) this will end in an exception
      end if;
      if p_testcase in (3, 4)
      then
        -- Oops, forgot to dbug.leave;
        null;
      else
        dbug.leave;
      end if;
    exception
      when others
      then
        if p_testcase in (2, 4)
        then
          -- Oops, forgot to dbug.leave_on_error;
          null;
        else
          dbug.leave_on_error;
        end if;
        raise;
    end f1;

    procedure f2
    is
    begin
      dbug.enter('f2');
      f1;
      dbug.leave;
    end f2;

    procedure f3
    is
    begin
      dbug.enter('f3');
      f2;
      if p_testcase in (5)
      then
        -- Oops, forgot to dbug.leave;
        null;
      else
        dbug.leave;
      end if;
    exception
      when others
      then
        if p_testcase in (5)
        then
          -- Oops, forgot to dbug.leave_on_error;
          null;
        else
          dbug.leave_on_error;
        end if;
        raise;
    end f3;
  begin
    dbug.enter('main');
    dbug.print('info', 'testcase: %s; log level: %s', p_testcase, dbug.get_level);
    f3;
    if p_testcase in (7, 8)
    then
      -- Oops, forgot to dbug.leave;
      null;
    elsif p_testcase in (9)
    then
      dbug.leave_on_error;
    else
      dbug.leave;
    end if;
  exception
    when others
    then
      if p_testcase in (6, 8)
      then
        -- Oops, forgot to dbug.leave_on_error;
        null;
      else
        dbug.leave_on_error;
      end if;
      raise;
  end leave;

  procedure init
  ( p_dbug_method in dbug.method_t
  , p_plsdbug_options in varchar2
  )
  is
  begin
    case upper(p_dbug_method)
      when 'PLSDBUG'
      then
        dbug.activate(p_dbug_method);
        dbug_plsdbug.init(p_plsdbug_options);

        execute immediate 'truncate table tlog';
        dbug.activate('LOG4PLSQL');
        
      when 'DBMS_OUTPUT'
      then
        dbms_output.disable; -- clear the buffer
        dbms_output.enable(200000);
        dbug.activate(p_dbug_method);

      when 'LOG4PLSQL'
      then
        execute immediate 'truncate table tlog';
        dbug.activate(p_dbug_method);

      else
        null;
    end case;
  end init;
  
  procedure done
  ( p_dbug_method in dbug.method_t
  , p_lines_exp in sys.odcivarchar2list
  , p_lines_act in out nocopy dbms_output.chararr
  , p_numlines in out nocopy integer
  )
  is
    l_idx_act pls_integer;
    l_idx_exp pls_integer;
  begin
    case upper(p_dbug_method)
      when 'PLSDBUG'
      then
        return; -- for PLSDBUG we need to check the plsdbug executable output
        
      when 'DBMS_OUTPUT'
      then
        p_numlines := power(2, 31); /* maximum nr of lines to retrieve */
        dbms_output.get_lines(lines => p_lines_act, numlines => p_numlines);
        
        -- p_lines_act contains error messages mixed with output: strip the error messages
        for i_idx in p_lines_act.first .. p_lines_act.last
        loop
          if substr(p_lines_act(i_idx), 1, 1) in ('>', '|', '<')
          then
            null; -- ok
          else
            p_lines_act.delete(i_idx);
          end if;
        end loop;
        p_numlines := p_lines_act.count;

      when 'LOG4PLSQL'
      then
        select  ltext
        bulk collect
        into    p_lines_act
        from    tlog
        order by
                id;
        p_numlines := p_lines_act.count;        
    end case;
    
    ut.expect(p_numlines, '# lines').to_equal(p_lines_exp.count);
    ut.expect(p_lines_act.first, 'lines first').to_equal(p_lines_exp.first);
    l_idx_act := p_lines_act.first;
    l_idx_exp := p_lines_exp.first;
    while l_idx_act is not null
    loop
      ut.expect(p_lines_act(l_idx_act), to_char(l_idx_exp)).to_equal(p_lines_exp(l_idx_exp));
      l_idx_act := p_lines_act.next(l_idx_act);
      l_idx_exp := l_idx_exp + 1;
    end loop;
    ut.expect(l_idx_exp).to_equal(p_lines_exp.last + 1);
  end done;  

  -- start of (help) test procedures from plsdbug
  
  procedure ut_leave
  ( p_dbug_method in dbug.method_t
  , p_plsdbug_options in varchar2
  )
  is
    l_lines_exp constant sys.odcivarchar2list :=
      sys.odcivarchar2list
      ( '>main'
      , '|   info: testcase: 9; log level: 2'
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
      , '|   error: sqlerrm: ORA-0000: normal, successful completion'
      , '<main'
      , '>main'
      , '|   info: testcase: 8; log level: 2'
      , '|   >f3'
      , '|   |   >f2'
      , '|   |   |   >f1'
      , '|   |   |   |   >f1'
      , '|   |   |   |   |   >f1'
      , '|   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace: ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   |   |   |   |   |   <f1'
      , '|   |   |   |   |   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   |   |   |   |   <f1'
      , '|   |   |   |   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   |   |   |   <f1'
      , '|   |   |   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   |   |   <f1'
      , '|   |   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   |   <f1'
      , '|   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   <f1'
      , '|   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   error: dbms_utility.format_error_backtrace (3): ORA-06512: at "EPCAPP.UT_DBUG", line 62'
      , '|   |   |   error: dbms_utility.format_error_backtrace (4): ORA-06512: at "EPCAPP.UT_DBUG", line 70'
      , '|   |   <f2'
      , '|   <f3'
      , '<main'
      , '>main'
      , '|   info: testcase: 7; log level: 2'
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
      , '>main'
      , '|   info: testcase: 6; log level: 2'
      , '|   >f3'
      , '|   |   >f2'
      , '|   |   |   >f1'
      , '|   |   |   |   >f1'
      , '|   |   |   |   |   >f1'
      , '|   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace: ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   |   |   |   |   |   <f1'
      , '|   |   |   |   |   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   |   |   |   |   <f1'
      , '|   |   |   |   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   |   |   |   <f1'
      , '|   |   |   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   |   |   <f1'
      , '|   |   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   |   <f1'
      , '|   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   <f1'
      , '|   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   error: dbms_utility.format_error_backtrace (3): ORA-06512: at "EPCAPP.UT_DBUG", line 62'
      , '|   |   |   error: dbms_utility.format_error_backtrace (4): ORA-06512: at "EPCAPP.UT_DBUG", line 70'
      , '|   |   <f2'
      , '|   <f3'
      , '<main'
      , '>main'
      , '|   info: testcase: 5; log level: 2'
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
      , '>main'
      , '|   info: testcase: 4; log level: 2'
      , '|   >f3'
      , '|   |   >f2'
      , '|   |   |   >f1'
      , '|   |   |   |   >f1'
      , '|   |   |   |   |   >f1'
      , '|   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (3): ORA-06512: at "EPCAPP.UT_DBUG", line 62'
      , '|   |   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (4): ORA-06512: at "EPCAPP.UT_DBUG", line 70'
      , '|   |   |   |   |   |   |   |   <f1'
      , '|   |   |   |   |   |   |   <f1'
      , '|   |   |   |   |   |   <f1'
      , '|   |   |   |   |   <f1'
      , '|   |   |   |   <f1'
      , '|   |   |   <f1'
      , '|   |   <f2'
      , '|   <f3'
      , '|   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 88'
      , '|   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   error: dbms_utility.format_error_backtrace (3): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   error: dbms_utility.format_error_backtrace (4): ORA-06512: at "EPCAPP.UT_DBUG", line 62'
      , '|   error: dbms_utility.format_error_backtrace (5): ORA-06512: at "EPCAPP.UT_DBUG", line 70'
      , '|   error: dbms_utility.format_error_backtrace (6): ORA-06512: at "EPCAPP.UT_DBUG", line 93'
      , '<main'
      , '>main'
      , '|   info: testcase: 3; log level: 2'
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
      , '>main'
      , '|   info: testcase: 2; log level: 2'
      , '|   >f3'
      , '|   |   >f2'
      , '|   |   |   >f1'
      , '|   |   |   |   >f1'
      , '|   |   |   |   |   >f1'
      , '|   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   |   >f1'
      , '|   |   |   |   |   |   |   |   |   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   |   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   |   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   |   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (3): ORA-06512: at "EPCAPP.UT_DBUG", line 62'
      , '|   |   |   |   |   |   |   |   |   error: dbms_utility.format_error_backtrace (4): ORA-06512: at "EPCAPP.UT_DBUG", line 70'
      , '|   |   |   |   |   |   |   |   <f1'
      , '|   |   |   |   |   |   |   <f1'
      , '|   |   |   |   |   |   <f1'
      , '|   |   |   |   |   <f1'
      , '|   |   |   |   <f1'
      , '|   |   |   <f1'
      , '|   |   <f2'
      , '|   <f3'
      , '|   error: sqlerrm: ORA-06502: PL/SQL: numeric or value error'
      , '|   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.UT_DBUG", line 88'
      , '|   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.UT_DBUG", line 55'
      , '|   error: dbms_utility.format_error_backtrace (3): ORA-06512: at "EPCAPP.UT_DBUG", line 36'
      , '|   error: dbms_utility.format_error_backtrace (4): ORA-06512: at "EPCAPP.UT_DBUG", line 62'
      , '|   error: dbms_utility.format_error_backtrace (5): ORA-06512: at "EPCAPP.UT_DBUG", line 70'
      , '|   error: dbms_utility.format_error_backtrace (6): ORA-06512: at "EPCAPP.UT_DBUG", line 93'
      , '<main'
      , '>main'
      , '|   info: testcase: 1; log level: 2'
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
    l_lines_act dbms_output.chararr;
    l_numlines integer;
  begin
    begin
      -- Try to use a persistent group    
      std_object_mgr.delete_std_objects(null);    
      std_object_mgr.set_group_name('leave.sql');
      std_object_mgr.delete_std_objects;
    exception
      when std_object_mgr.e_unimplemented_feature
      then null;
    end;

    init(p_dbug_method, p_plsdbug_options);

    for i_testcase in reverse 1..9
    loop
      begin
        /*
        case i_testcase
          when 4
          then
            dbug.set_level(dbug.c_level_error);
            leave(i_testcase);
            dbug.set_level(dbug.c_level_all);
            leave(i_testcase);
          when 1
          then
            leave(i_testcase);
            dbug.set_level(dbug.c_level_off);
            leave(i_testcase);
          else
            null;
        end case;
        */
        leave(i_testcase);
      exception
        when value_error
        then
          /*
          if i_testcase in (3, 5)
          then 
            dbug.leave;
          end if;
          */
          null; -- DBUG should solve missing dbug.leave calls when it restarts
          
        when others
        then        
          ut.expect(sqlcode, 'test case: ' || i_testcase).to_equal(0);
      end;
    end loop;
    std_object_mgr.delete_std_objects;

    done(p_dbug_method, l_lines_exp, l_lines_act, l_numlines);
  end ut_leave;

  procedure ut_benchmark
  ( p_count in positiven
  , p_dbug_method in dbug.method_t
  , p_plsdbug_options in varchar2
  )
  is
    l_lines_exp sys.odcivarchar2list := sys.odcivarchar2list();
    l_lines_act dbms_output.chararr;
    l_numlines integer;
      
    procedure doit
    is
    begin
      dbug.enter('doit');
      dbug.leave;
    end;
  begin
    init(p_dbug_method, p_plsdbug_options);
    l_lines_exp.extend(1);
    l_lines_exp(l_lines_exp.last) := '>main';
    dbug.enter('main');
    for i_idx in 1..p_count
    loop
      l_lines_exp.extend(1);
      l_lines_exp(l_lines_exp.last) := '|   >doit';
      l_lines_exp.extend(1);
      l_lines_exp(l_lines_exp.last) := '|   <doit';
      doit;
    end loop;
    l_lines_exp.extend(1);
    l_lines_exp(l_lines_exp.last) := '<main';
    dbug.leave;
    dbug.done;
    done(p_dbug_method, l_lines_exp, l_lines_act, l_numlines);
  end ut_benchmark;

  procedure ut_factorial
  ( p_dbug_method in dbug.method_t
  , p_plsdbug_options in varchar2
  )
  is
    l_lines_exp constant sys.odcivarchar2list :=
      sys.odcivarchar2list
      ( '>factorial'
      , '|   input: p_value: 10'
      , '|   >factorial'
      , '|   |   input: p_value: 9'
      , '|   |   >factorial'
      , '|   |   |   input: p_value: 8'
      , '|   |   |   >factorial'
      , '|   |   |   |   input: p_value: 7'
      , '|   |   |   |   >factorial'
      , '|   |   |   |   |   input: p_value: 6'
      , '|   |   |   |   |   >factorial'
      , '|   |   |   |   |   |   input: p_value: 5'
      , '|   |   |   |   |   |   >factorial'
      , '|   |   |   |   |   |   |   input: p_value: 4'
      , '|   |   |   |   |   |   |   >factorial'
      , '|   |   |   |   |   |   |   |   input: p_value: 3'
      , '|   |   |   |   |   |   |   |   >factorial'
      , '|   |   |   |   |   |   |   |   |   input: p_value: 2'
      , '|   |   |   |   |   |   |   |   |   >factorial'
      , '|   |   |   |   |   |   |   |   |   |   input: p_value: 1'
      , '|   |   |   |   |   |   |   |   |   |   output: return: 1'
      , '|   |   |   |   |   |   |   |   |   <factorial'
      , '|   |   |   |   |   |   |   |   |   output: return: 2'
      , '|   |   |   |   |   |   |   |   <factorial'
      , '|   |   |   |   |   |   |   |   output: return: 6'
      , '|   |   |   |   |   |   |   <factorial'
      , '|   |   |   |   |   |   |   output: return: 24'
      , '|   |   |   |   |   |   <factorial'
      , '|   |   |   |   |   |   output: return: 120'
      , '|   |   |   |   |   <factorial'
      , '|   |   |   |   |   output: return: 720'
      , '|   |   |   |   <factorial'
      , '|   |   |   |   output: return: 5040'
      , '|   |   |   <factorial'
      , '|   |   |   output: return: 40320'
      , '|   |   <factorial'
      , '|   |   output: return: 362880'
      , '|   <factorial'
      , '|   output: return: 3628800'
      , '<factorial'
      );
    l_lines_act dbms_output.chararr;
    l_numlines integer;
      
    function factorial (p_value in integer)
    return  integer
    is
      l_value integer := p_value;
    begin
      dbug.enter('factorial');
      dbug.print(dbug."input", 'p_value: %s', l_value);
      if (l_value > 1) 
      then
        l_value := l_value * factorial(l_value-1);
      end if;
      dbug.print(dbug."output", 'return: %s', l_value);
      dbug.leave;
      return l_value;
    end factorial;
  begin
    init(p_dbug_method, p_plsdbug_options);
    ut.expect(factorial(10), 'factorial(10)').to_equal(3628800);
    done(p_dbug_method, l_lines_exp, l_lines_act, l_numlines);
  end ut_factorial; 

  -- end of (help) test procedures from plsdbug

  procedure ut_run
  is
    procedure proc
    is
      procedure nested_proc
      is
        i integer;
      begin
        dbug.enter('NESTED_PROC');

        i := 42/0;

        dbug.leave;
      exception
        when others
        then
          dbug.on_error;
          raise;
      end nested_proc;
    begin
      dbug.enter('PROC');
      nested_proc;
      dbug.leave;
    end proc;
  begin
    dbug.enter('UT_RUN');
    proc;
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
  end ut_run;

  -- test (help) procedures

  procedure ut_setup
  is
    pragma autonomous_transaction;
  begin
    execute immediate q'[ALTER SESSION SET NLS_LANGUAGE = 'AMERICAN']';

    std_object_mgr.delete_std_objects
    ( p_group_name => 'TEST%'
    );
    commit;
  end ut_setup;

  procedure ut_teardown
  is
    pragma autonomous_transaction;
  begin
    std_object_mgr.delete_std_objects
    ( p_group_name => 'TEST%'
    );
    commit;
  end ut_teardown;

  procedure ut_dbug
  is
    pragma autonomous_transaction;

    l_std_object std_object;
    l_dbug_obj dbug_obj_t;
    l_obj_act varchar2(32767);
    l_obj_exp constant varchar2(32767) := '{"DIRTY":0,"INDENT_LEVEL":0,"DBUG_LEVEL":2,"BREAK_POINT_LEVEL_STR_TAB":["debug","error","fatal","info","input","output","trace","warning"],"BREAK_POINT_LEVEL_NUM_TAB":[2,5,6,3,2,2,2,4],"IGNORE_BUFFER_OVERFLOW":0}';
  begin
    for i_try in 1..2
    loop
      std_object_mgr.set_group_name(case i_try when 1 then 'TEST' else null end);

      l_dbug_obj := dbug_obj_t();
      l_dbug_obj.store();
      case i_try
        when 1
        then
          select  t.obj
          into    l_obj_act
          from    std_objects t
          where   group_name = 'TEST'
          and     object_name = 'DBUG';

        when 2
        then
          std_object_mgr.get_std_object
          ( p_object_name => 'DBUG'
          , p_std_object => l_std_object
          );
          select  l_std_object.serialize()
          into    l_obj_act
          from    dual;

      end case;
      ut.expect(l_obj_act).to_equal(l_obj_exp);
    end loop;
    commit;
  exception
    when std_object_mgr.e_unimplemented_feature
    then commit;
  end ut_dbug;

  procedure ut_leave_on_error
  is
    l_lines_exp constant sys.odcivarchar2list :=
      sys.odcivarchar2list
      ( '>main'
      , '|   >UT_RUN'
      , '|   |   >PROC'
      , '|   |   |   >NESTED_PROC'
      , '|   |   |   |   error: sqlerrm: ORA-01476: divisor is equal to zero'
      , '|   |   |   |   error: dbms_utility.format_error_backtrace: ORA-06512: at "%.UT_DBUG", line %'
      , '|   |   |   |   error: sqlerrm: ORA-01476: divisor is equal to zero'
      , '|   |   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "%.UT_DBUG", line %'
      , '|   |   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "%.UT_DBUG", line %'
      , '|   |   |   |   error: dbms_utility.format_error_backtrace (3): ORA-06512: at "%.UT_DBUG", line %'
      , '|   |   |   |   error: dbms_utility.format_error_backtrace (4): ORA-06512: at "%.UT_DBUG", line %'
      , '|   |   |   <NESTED_PROC'
      , '|   |   <PROC'
      , '|   <UT_RUN'
      , '|   error: sqlerrm: ORA-01476: divisor is equal to zero'
      , '|   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "%.UT_DBUG", line %'
      , '|   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "%.UT_DBUG", line %'
      , '|   error: dbms_utility.format_error_backtrace (3): ORA-06512: at "%.UT_DBUG", line %'
      , '|   error: dbms_utility.format_error_backtrace (4): ORA-06512: at "%.UT_DBUG", line %'
      , '|   error: dbms_utility.format_error_backtrace (5): ORA-06512: at "%.UT_DBUG", line %'
      , '|   error: dbms_utility.format_error_backtrace (6): ORA-06512: at "%.UT_DBUG", line %'
      , '<main'
      );

    l_lines_act dbms_output.chararr;
    l_numlines integer := l_lines_exp.count; -- the number of lines to retrieve
  begin
    dbms_output.disable; -- clear the buffer
    dbms_output.enable;
    dbug.activate('DBMS_OUTPUT');

    begin
      dbug.enter('main');
      ut_run;
      dbug.leave;
    exception
      when others
      then
        dbug.leave_on_error;
    end;

    dbms_output.get_lines(lines => l_lines_act, numlines => l_numlines);
    ut.expect(l_numlines, '# lines').to_equal(l_lines_exp.count);
    ut.expect(l_lines_act.first, 'lines first').to_equal(l_lines_exp.first);
    for i_idx in l_lines_exp.first .. l_lines_exp.last
    loop
      ut.expect
      ( case when l_lines_act.exists(i_idx) then l_lines_act(i_idx) end
      , to_char(i_idx)).to_be_like(l_lines_exp(i_idx)
      );
    end loop;
    /*
    for i_idx in l_lines_act.first .. l_lines_act.last
    loop
      dbms_output.put_line(l_lines_act(i_idx));
    end loop;
    */
  end ut_leave_on_error;

$else -- ut_dbug.c_testing $then

  -- some dummy stubs

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

  procedure ut_dbug
  is
  begin
    raise program_error;
  end;

  procedure ut_run
  is
  begin
    raise program_error;
  end;

  procedure ut_leave_on_error
  is
  begin
    raise program_error;
  end;

  procedure ut_leave
  ( p_dbug_method in dbug.method_t
  , p_plsdbug_options in varchar2
  )
  is
  begin
    raise program_error;
  end;

$end -- ut_dbug.c_testing $then

  procedure ut_leave_dbms_output
  is
  begin
    ut_leave('DBMS_OUTPUT');
  end ut_leave_dbms_output;

  procedure ut_leave_log4plsql
  is
  begin
    ut_leave('LOG4PLSQL');
  end ut_leave_log4plsql;

  procedure ut_benchmark_dbms_output
  is
  begin
    ut_benchmark(100, 'DBMS_OUTPUT');
  end ut_benchmark_dbms_output;

  procedure ut_benchmark_log4plsql
  is
  begin
    ut_benchmark(100, 'LOG4PLSQL');
  end ut_benchmark_log4plsql;

  procedure ut_factorial_dbms_output
  is
  begin
    ut_factorial('DBMS_OUTPUT');
  end ut_factorial_dbms_output;

  procedure ut_factorial_log4plsql
  is
  begin
    ut_factorial('LOG4PLSQL');
  end ut_factorial_log4plsql;

END UT_DBUG;
/

