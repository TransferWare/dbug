CREATE OR REPLACE PACKAGE BODY "DBUG_LOG4PLSQL" IS

  /* global modules */

  procedure log_ctx2dbug_log4plsql_obj
  ( p_ctx in plogparam.log_ctx
  , p_obj in out nocopy dbug_log4plsql_obj_t
  )
  is
    function bool2int(p_bool in boolean)
    return integer
    is
    begin
      return case p_bool when true then 1 when false then 0 else null end;
    end bool2int;
  begin
    p_obj.isdefaultinit := bool2int(p_ctx.isdefaultinit);
    p_obj.llevel := p_ctx.llevel;
    p_obj.lsection := p_ctx.lsection;
    p_obj.ltext := p_ctx.ltext;
    p_obj.use_log4j := bool2int(p_ctx.use_log4j);
    p_obj.use_out_trans := bool2int(p_ctx.use_out_trans);
    p_obj.use_logtable := bool2int(p_ctx.use_logtable);
    p_obj.use_alert := bool2int(p_ctx.use_alert);
    p_obj.use_trace := bool2int(p_ctx.use_trace);
    p_obj.use_dbms_output := bool2int(p_ctx.use_dbms_output);
    p_obj.init_lsection := p_ctx.init_lsection;
    p_obj.init_llevel := p_ctx.init_llevel;
    p_obj.dbms_output_wrap := p_ctx.dbms_output_wrap;
  end;

  procedure dbug_log4plsql_obj2log_ctx
  ( p_obj in dbug_log4plsql_obj_t
  , p_ctx in out nocopy plogparam.log_ctx
  )
  is
    function int2bool(p_int in integer)
    return boolean
    is
    begin
      return case p_int when 1 then true when 0 then false else null end;
    end int2bool;
  begin
    p_ctx.isdefaultinit := int2bool(p_obj.isdefaultinit);
    p_ctx.llevel := p_obj.llevel;
    p_ctx.lsection := p_obj.lsection;
    p_ctx.ltext := p_obj.ltext;
    p_ctx.use_log4j := int2bool(p_obj.use_log4j);
    p_ctx.use_out_trans := int2bool(p_obj.use_out_trans);
    p_ctx.use_logtable := int2bool(p_obj.use_logtable);
    p_ctx.use_alert := int2bool(p_obj.use_alert);
    p_ctx.use_trace := int2bool(p_obj.use_trace);
    p_ctx.use_dbms_output := int2bool(p_obj.use_dbms_output);
    p_ctx.init_lsection := p_obj.init_lsection;
    p_ctx.init_llevel := p_obj.init_llevel;
    p_ctx.dbms_output_wrap := p_obj.dbms_output_wrap;
  end;

  procedure get_log_ctx
  ( p_ctx out nocopy plogparam.log_ctx
  )
  is
    l_obj dbug_log4plsql_obj_t;
  begin
    l_obj := new dbug_log4plsql_obj_t();

    dbug_log4plsql_obj2log_ctx
    ( p_obj => l_obj
    , p_ctx => p_ctx
    );
  end get_log_ctx;

  procedure set_log_ctx
  ( p_ctx in plogparam.log_ctx
  )
  is
    l_obj dbug_log4plsql_obj_t;
  begin
    l_obj := new dbug_log4plsql_obj_t();

    log_ctx2dbug_log4plsql_obj
    ( p_ctx => p_ctx
    , p_obj => l_obj
    );
    l_obj.store();
  end set_log_ctx;

  /* global modules */

  procedure done
  is
    l_obj dbug_log4plsql_obj_t;
  begin
    l_obj := new dbug_log4plsql_obj_t();
    l_obj.remove();
  end done;

  procedure enter(
    p_module in dbug.module_name_t
  )
  is
    l_ctx plogparam.log_ctx;
  begin
    get_log_ctx(l_ctx);
    plog.debug
    ( l_ctx
    , dbug.format_enter(p_module)
    );
    set_log_ctx(l_ctx);
  end enter;

  procedure leave
  is
    l_ctx plogparam.log_ctx;
  begin
    get_log_ctx(l_ctx);
    plog.debug
    ( l_ctx
    , dbug.format_leave
    );
    set_log_ctx(l_ctx);
  end leave;

  procedure print( p_str in varchar2 )
  is
    l_pos pls_integer;
    l_prev_pos pls_integer;
    l_str varchar2(32767) := p_str;
    l_ctx plogparam.log_ctx;
  begin
$if std_object_mgr.c_debugging $then
    dbms_output.put_line
    ( utl_lms.format_message
      ( '[%s.%s] p_str: %s'
      , $$PLSQL_UNIT
      , 'PRINT0'
      , p_str
      )
    );
$end
    get_log_ctx(l_ctx);
    l_prev_pos := 1;
    loop
      exit when l_prev_pos > nvl(length(l_str), 0);

      l_pos := instr(l_str, chr(10), l_prev_pos);

      if l_pos = 0
      then
        plog.debug
        ( l_ctx
        , substr(l_str, l_prev_pos)
        );
        exit;
      else
        plog.debug
        ( l_ctx
        , substr(l_str, l_prev_pos, l_pos - l_prev_pos)
        );
      end if;

      l_prev_pos := l_pos + 1;
    end loop;
    set_log_ctx(l_ctx);
  end print;

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2
  ) is
  begin
$if std_object_mgr.c_debugging $then
    dbms_output.put_line
    ( utl_lms.format_message
      ( '[%s.%s] p_fmt: %s; p_arg1: %s'
      , $$PLSQL_UNIT
      , 'PRINT1'
      , p_fmt
      , p_arg1
      )
    );
$end
    print( dbug.format_print(p_break_point, p_fmt, 1, p_arg1) );
  end print;

  procedure print(
    p_break_point in varchar2,
    p_fmt in varchar2,
    p_arg1 in varchar2,
    p_arg2 in varchar2
  ) is
  begin
$if std_object_mgr.c_debugging $then
    dbms_output.put_line
    ( utl_lms.format_message
      ( '[%s.%s] p_fmt: %s; p_arg1: %s; p_arg2: %s'
      , $$PLSQL_UNIT
      , 'PRINT2'
      , p_fmt
      , p_arg1
      , p_arg2
      )
    );
$end
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
$if std_object_mgr.c_debugging $then
    dbms_output.put_line
    ( utl_lms.format_message
      ( '[%s.%s] p_fmt: %s; p_arg1: %s; p_arg2: %s; p_arg3: %s'
      , $$PLSQL_UNIT
      , 'PRINT3'
      , p_fmt
      , p_arg1
      , p_arg2
      , p_arg3
      )
    );
$end
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
$if std_object_mgr.c_debugging $then
    dbms_output.put_line
    ( utl_lms.format_message
      ( '[%s.%s] p_fmt: %s; p_arg1: %s; p_arg2: %s; p_arg3: %s; p_arg4: %s'
      , $$PLSQL_UNIT
      , 'PRINT4'
      , p_fmt
      , p_arg1
      , p_arg2
      , p_arg3
      , p_arg4
      )
    );
$end
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
$if std_object_mgr.c_debugging $then
    dbms_output.put_line
    ( utl_lms.format_message
      ( '[%s.%s] p_fmt: %s; p_arg1: %s; p_arg2: %s; p_arg3: %s; p_arg4: %s; p_arg5: %s'
      , $$PLSQL_UNIT
      , 'PRINT5'
      , p_fmt
      , p_arg1
      , p_arg2
      , p_arg3
      , p_arg4
      , p_arg5
      )
    );
$end
    print( dbug.format_print(p_break_point, p_fmt, 5, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5) );
  end print;

$if dbug_log4plsql.c_testing $then 

  procedure ut_setup
  is
    pragma autonomous_transaction;
  begin
    std_object_mgr.set_group_name(null);
    std_object_mgr.delete_std_objects
    ( p_group_name => 'TEST%'
    );
    commit;
$if std_object_mgr.c_debugging $then    
    dbms_output.put_line('ut_setup finished');
$end    
  end;

  procedure ut_teardown
  is
    pragma autonomous_transaction;
  begin
    std_object_mgr.set_group_name(null);
    std_object_mgr.delete_std_objects
    ( p_group_name => 'TEST%'
    );
    commit;
$if std_object_mgr.c_debugging $then
    dbms_output.put_line('ut_teardown finished');
$end    
  end;

  procedure ut_store_remove
  is    
    pragma autonomous_transaction;

    l_std_object std_object;
    l_dbug_log4plsql_obj dbug_log4plsql_obj_t;
    l_object_name_tab sys.odcivarchar2list;
    l_count pls_integer;   
    l_obj_act varchar2(32767);
    l_obj_exp constant varchar2(32767) := '{"DIRTY":0,"ISDEFAULTINIT":1,"LLEVEL":70,"LSECTION":"block-->UT3.UT_RUNNER.RUN-->UT3.UT_SUITE_ITEM.DO_EXECUTE-->UT3.UT_RUN.DO_EXECUTE-->UT3.UT_LOGICAL_SUITE.DO_EXECUTE-->UT3.UT_SUITE_ITEM.DO_EXECUTE-->UT3.UT_SUITE.DO_EXECUTE-->UT3.UT_SUITE_ITEM.DO_EXECUTE-->UT3.UT_TEST.DO_EXECUTE-->UT3.UT_EXECUTABLE_TEST.DO_EXECUTE-->UT3.UT_EXECUTABLE_TEST.DO_EXECUTE-->UT3.UT_EXECUTABLE.DO_EXECUTE-->UT3.UT_EXECUTABLE.DO_EXECUTE-->SYS.DBMS_SQL.EXECUTE-->block-->EPCAPP.DBUG_LOG4PLSQL.UT_STORE_REMOVE-->EPCAPP.DBUG_LOG4PLSQL_OBJ_T.DBUG_LOG4PLSQL_OBJ_T","LTEXT":null,"USE_LOG4J":0,"USE_OUT_TRANS":1,"USE_LOGTABLE":1,"USE_ALERT":0,"USE_TRACE":0,"USE_DBMS_OUTPUT":0,"INIT_LSECTION":null,"INIT_LLEVEL":70,"DBMS_OUTPUT_WRAP":100}';

    procedure get_object_names
    is
    begin
      std_object_mgr.get_object_names(l_object_name_tab);
$if std_object_mgr.c_debugging $then
      if l_object_name_tab.count > 0
      then
        for i_idx in l_object_name_tab.first .. l_object_name_tab.last
        loop
          dbms_output.put_line('l_object_name_tab[' || i_idx || '] = ' || l_object_name_tab(i_idx));        
        end loop;
      end if;
$end
    end get_object_names;
  begin
    for i_try in 1..2
    loop
      std_object_mgr.set_group_name(case i_try when 1 then 'TEST' else null end);
      
      -- before store
$if std_object_mgr.c_debugging $then
      dbms_output.put_line('count before store ' || i_try);
$end     
      get_object_names;
      l_count := l_object_name_tab.count;
      
      l_dbug_log4plsql_obj := new dbug_log4plsql_obj_t(); -- should store

      case i_try
        when 1
        then
          select  t.obj
          into    l_obj_act
          from    std_objects t
          where   group_name = 'TEST'
          and     object_name = 'DBUG_LOG4PLSQL';
          
        when 2
        then
          std_object_mgr.get_std_object
          ( p_object_name => 'DBUG_LOG4PLSQL'
          , p_std_object => l_std_object
          );
          select  l_std_object.serialize()
          into    l_obj_act
          from    dual;

      end case;
      
$if std_object_mgr.c_debugging $then
      dbms_output.put_line('count after store ' || i_try);
$end     
      get_object_names;
      ut.expect(l_object_name_tab.count, 'count after store ' || i_try).to_equal(l_count + 1);
      ut.expect(l_obj_act, 'compare ' || i_try).to_equal(l_obj_exp);

      -- after store
      l_count := l_object_name_tab.count;
      
      l_dbug_log4plsql_obj.remove();

$if std_object_mgr.c_debugging $then
      dbms_output.put_line('test removed');
$end
      
      begin
        case i_try
          when 1
          then
            select  t.obj
            into    l_obj_act
            from    std_objects t
            where   group_name = 'TEST'
            and     object_name = 'DBUG_LOG4PLSQL';
            
          when 2
          then
            std_object_mgr.get_std_object
            ( p_object_name => 'DBUG_LOG4PLSQL'
            , p_std_object => l_std_object
            );

        end case;
        raise program_error;
      exception
        when others
        then
          ut.expect(sqlcode, 'remove ' || i_try).to_equal(100);
      end;
      
$if std_object_mgr.c_debugging $then
      dbms_output.put_line('count after remove ' || i_try);
$end     
      get_object_names;

      ut.expect(l_object_name_tab.count, 'count after remove ' || i_try).to_equal(l_count - 1);
    end loop;

    commit;
  end ut_store_remove;

  procedure ut_dbug_log4plsql
  is    
    pragma autonomous_transaction;

    l_id tlog.id%type;
    l_act sys_refcursor;
    l_exp sys_refcursor;

    procedure test(p_try in integer)
    is
    begin
      dbug.enter('test');
      dbug.print(dbug."info", 'p_try: %s %s %s %s %s', p_try, p_try+1, p_try+2, p_try+3, p_try+4);
      if p_try = 2
      then
        raise program_error;
      else
        test(p_try + 1);
      end if;
      dbug.leave;
    end test;

    procedure main
    is
    begin
      dbug.enter('main');
      test(1);
      dbug.leave;
    exception
      when others
      then
        dbug.leave_on_error;
    end main;
    
    procedure cleanup
    is
    begin
      dbug.activate('plsdbug', false);
      dbug.done;
      -- clean local storage up
      std_object_mgr.delete_std_objects
      ( p_group_name => null
      , p_object_name => '%'
      );
    end;
  begin
    std_object_mgr.set_group_name(null);
    
    select nvl(max(id), 0) into l_id from tlog;

    dbug.activate('plsdbug', true);

    main;

    open l_act for
      select rownum as nr, ltext from (select substr(ltext, 1, 104) as ltext from tlog where id > l_id and luser = user order by id asc);
    open l_exp for
      select  1 as nr, '>main' as ltext from dual union all
      select  2      , '|   >test' as ltext from dual union all
      select  3      , '|   |   info: p_try: 1 2 3 4 5' as ltext from dual union all
      select  4      , '|   |   >test' as ltext from dual union all
      select  5      , '|   |   |   info: p_try: 2 3 4 5 6' as ltext from dual union all
      select  6      , '|   |   |   error: sqlerrm: ORA-06501: PL/SQL: program error' as ltext from dual union all
      select  7      , '|   |   |   error: dbms_utility.format_error_backtrace (1): ORA-06512: at "EPCAPP.DBUG_LOG4PLSQL", line ' /*441*/ as ltext from dual union all
      select  8      , '|   |   |   error: dbms_utility.format_error_backtrace (2): ORA-06512: at "EPCAPP.DBUG_LOG4PLSQL", line ' /*443*/ as ltext from dual union all
      select  9      , '|   |   |   error: dbms_utility.format_error_backtrace (3): ORA-06512: at "EPCAPP.DBUG_LOG4PLSQL", line ' /*452*/ as ltext from dual union all
      select 10      , '|   |   <test' as ltext from dual union all
      select 11      , '|   <test' as ltext from dual union all
      select 12      , '<main' as ltext from dual;     

    ut.expect(l_act, 'tlog').to_equal(l_exp);

    cleanup;

    commit;
  exception
    when others
    then
      rollback;
      cleanup;
      commit;
      raise;
  end ut_dbug_log4plsql;

$else -- dbug_log4plsql.c_testing $then

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

  procedure ut_store_remove
  is    
  begin
    raise program_error;
  end ut_store_remove;
  
  procedure ut_dbug_log4plsql
  is
  begin
    raise program_error;
  end ut_dbug_log4plsql;
  
$end -- dbug_log4plsql.c_testing $then

end dbug_log4plsql;
/

