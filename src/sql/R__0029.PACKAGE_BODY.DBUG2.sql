CREATE OR REPLACE PACKAGE BODY "DBUG2" IS

procedure ut_show_stack(i_am varchar2)
is
begin
    dbms_output.put_line('=== begin of show stack (' || i_am || ') ===');
    dbms_output.put_line('  dynamic depth:   ' || utl_call_stack.dynamic_depth);
    dbms_output.put_line('  error depth:     ' || utl_call_stack.error_depth);
    dbms_output.put_line('  backtrace depth: ' || utl_call_stack.backtrace_depth);
    dbms_output.new_line;

    dbms_output.put_line('--- call stack ---');
    for depth in /*reverse*/ 1 .. utl_call_stack.dynamic_depth
    loop
        dbms_output.put_line(
           to_char(UTL_CALL_STACK.lexical_depth(depth),    '90') || ' ' ||
           rpad   (UTL_CALL_STACK.unit_type    (depth),     30 ) || ' ' ||
           rpad   (UTL_CALL_STACK.subprogram   (depth)(1) , 30 ) || ' ' ||
           to_char(UTL_CALL_STACK.unit_line    (depth), '99990') || ' ' ||
                   UTL_CALL_STACK.concatenate_subprogram(
                   UTL_CALL_STACK.subprogram   (depth)
                   )
        );
    end loop;

    dbms_output.put_line('--- error stack ---');
    for error in 1 ..  utl_call_stack.error_depth
    loop

        dbms_output.put_line('   ' ||
           rpad   (utl_call_stack.error_msg   (error), 100)    || ' ' ||
           to_char(utl_call_stack.error_number(error), '99990')
        );

    end loop;

    dbms_output.put_line('--- backtrace stack ---');
    for backtrace in 1 ..  utl_call_stack.backtrace_depth
    loop

        dbms_output.put_line('   ' ||
           rpad   (utl_call_stack.backtrace_unit(backtrace), 61) || ' ' ||
           to_char(utl_call_stack.backtrace_line(backtrace), '99990')
        );

    end loop;
    dbms_output.put_line('=== end of show stack (' || i_am || ') ===');
end ut_show_stack;

procedure PROC
is
    procedure NESTED_PROC
    is
        i integer;
    begin
        ut_show_stack('NESTED_PPROC');

        i := 42/0;

    exception
        when others
        then
            ut_show_stack('exception PROC');
            raise;
    end NESTED_PROC;
begin
    ut_show_stack('PROC');
    NESTED_PROC;
end PROC;

procedure ut_run
is
begin
    ut_show_stack('ut_run');
    PROC;
exception
    when others
    then
        ut_show_stack('exception ut_run');
end ut_run;
    
END DBUG2;
/

