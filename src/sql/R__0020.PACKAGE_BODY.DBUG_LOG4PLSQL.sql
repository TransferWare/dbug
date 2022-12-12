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

$if dbug_log4plsql.c_testing $then 

  procedure ut_setup
  is
    pragma autonomous_transaction;
  begin
    std_object_mgr.delete_std_objects
    ( p_group_name => 'TEST%'
    );
    commit;
    dbms_output.put_line('ut_setup finished');
  end;

  procedure ut_teardown
  is
    pragma autonomous_transaction;
  begin
    std_object_mgr.delete_std_objects
    ( p_group_name => 'TEST%'
    );
    commit;
    dbms_output.put_line('ut_teardown finished');
  end;

  procedure ut_store_remove
  is    
    pragma autonomous_transaction;

    l_std_object std_object;
    l_dbug_log4plsql_obj dbug_log4plsql_obj_t;
    l_object_name_tab sys.odcivarchar2list;
    l_count_start pls_integer;   
    l_obj_act varchar2(32767);
    l_obj_exp constant varchar2(32767) := '{"DIRTY":0,"ISDEFAULTINIT":1,"LLEVEL":70,"LSECTION":"block-->UT3.UT_RUNNER.RUN-->UT3.UT_SUITE_ITEM.DO_EXECUTE-->UT3.UT_RUN.DO_EXECUTE-->UT3.UT_LOGICAL_SUITE.DO_EXECUTE-->UT3.UT_SUITE_ITEM.DO_EXECUTE-->UT3.UT_SUITE.DO_EXECUTE-->UT3.UT_SUITE_ITEM.DO_EXECUTE-->UT3.UT_TEST.DO_EXECUTE-->UT3.UT_EXECUTABLE_TEST.DO_EXECUTE-->UT3.UT_EXECUTABLE_TEST.DO_EXECUTE-->UT3.UT_EXECUTABLE.DO_EXECUTE-->UT3.UT_EXECUTABLE.DO_EXECUTE-->SYS.DBMS_SQL.EXECUTE-->block-->EPCAPP.DBUG_LOG4PLSQL.UT_STORE_REMOVE-->EPCAPP.DBUG_LOG4PLSQL_OBJ_T.DBUG_LOG4PLSQL_OBJ_T","LTEXT":null,"USE_LOG4J":0,"USE_OUT_TRANS":1,"USE_LOGTABLE":1,"USE_ALERT":0,"USE_TRACE":0,"USE_DBMS_OUTPUT":0,"INIT_LSECTION":null,"INIT_LLEVEL":70,"DBMS_OUTPUT_WRAP":100}';
  begin
    for i_try in 1..2
    loop
      dbms_output.put_line('i_try: ' || i_try);

      std_object_mgr.get_object_names(l_object_name_tab);

      l_count_start := l_object_name_tab.count;

      ut.expect(l_count_start, 'object count ' || i_try).to_equal(0);
      
      std_object_mgr.set_group_name(case i_try when 1 then 'TEST' else null end);
      l_dbug_log4plsql_obj := dbug_log4plsql_obj_t(); -- should store

      dbms_output.put_line('test stored');
      
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
          dbms_output.put_line('serialize');
          select  l_std_object.serialize()
          into    l_obj_act
          from    dual;

      end case;
      
      ut.expect(l_obj_act, 'store ' || i_try).to_equal(l_obj_exp);

      std_object_mgr.get_object_names(l_object_name_tab);

      ut.expect(l_object_name_tab.count, 'store ' || i_try).to_equal(l_count_start + 1);

      l_dbug_log4plsql_obj.remove();

      dbms_output.put_line('test removed');
      
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
      
      std_object_mgr.get_object_names(l_object_name_tab);

      ut.expect(l_object_name_tab.count, 'remove ' || i_try).to_equal(l_count_start);
    end loop;

    commit;
  end ut_store_remove;

$else -- dbug_log4plsql.c_testing $then

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

  procedure ut_store_remove
  is    
  begin
    null;
  end ut_store_remove;

$end -- dbug_log4plsql.c_testing $then

end dbug_log4plsql;
/

