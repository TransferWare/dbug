CREATE OR REPLACE PACKAGE BODY "UT_DBUG" IS

$if ut_dbug.c_testing $then

  procedure ut_setup
  is
    pragma autonomous_transaction;
  begin
    std_object_mgr.delete_std_objects
    ( p_group_name => 'TEST%'
    );
    commit;
  end;

  procedure ut_teardown
  is
    pragma autonomous_transaction;
  begin
    std_object_mgr.delete_std_objects
    ( p_group_name => 'TEST%'
    );
    commit;
  end;

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
  end;

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
    null;
  end;

  procedure ut_teardown
  is
  begin
    null;
  end;

  procedure ut_dbug
  is
  begin
    null;
  end;
  
  procedure ut_run
  is
  begin
    null;
  end;
  
  procedure ut_leave_on_error
  is
  begin
    null;
  end;

$end -- ut_dbug.c_testing $then

END UT_DBUG;
/

