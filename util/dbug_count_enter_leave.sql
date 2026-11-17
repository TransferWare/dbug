REMARK
REMARK Author    : Gert-Jan Paulissen
REMARK
REMARK Goal      : Check that each dbug.enter is followed by at least one dbug.leave/dbug.leave_on_error.
REMARK
REMARK Notes     : 
REMARK
REMARK Parameters:
PROMPT             1 - object name (defaults to wildcard %)
PROMPT             &&1
PROMPT             2 - object type (defaults to wildcard %)
PROMPT             &&2
PROMPT             3 - skip objects with an equal number of calls for dbug.enter/dbug.leave/dbug.leave_on_error (defaults to 1)
PROMPT             &&3

/*

The following documentation uses the Perl pod format. A html file
can be constructed by: 

  pod2html --infile=dbug_count_enter_leave.sql --outfile=dbug_count_enter_leave.html

=pod

=head1 NAME

dbug_count_enter_leave - Check that each dbug.enter is followed by at least one dbug.leave/dbug.leave_on_error.

=head1 SYNOPSIS

  sqlplus @dbug_count_enter_leave.sql [ <object name> ]

=head1 DESCRIPTION

Checks USER_SOURCE (type TRIGGER, TYPE BODY, FUNCTION, PROCEDURE, PACKAGE BODY) for dbug.enter, dbug.leave, dbug.leave_on_error in sequence (LINE).

=head1 NOTES

=head1 EXAMPLES

  In SQL*Plus:

  SQL> @dbug_count_enter_leave

=head1 AUTHOR

Gert-Jan Paulissen

=head1 HISTORY

=head1 BUGS

=head1 SEE ALSO

=cut

*/

set serveroutput on size unlimited format trunc

set feedback off verify off

declare
  c_skip_equal_number_of_calls constant boolean := nvl(to_number('&3'), 1) != 0;

  r_prev user_source%rowtype;

  l_dbug_enter_calls naturaln := 0;
  l_dbug_leave_calls naturaln := 0;
  l_dbug_leave_on_error_calls naturaln := 0;

  procedure new_object
  is
  begin
    if r_prev.name is null then return; end if;

    dbms_output.put_line(utl_lms.format_message('=== object %s (%s) ===', r_prev.name, r_prev.type));
    
    if c_skip_equal_number_of_calls
       and
       l_dbug_enter_calls = l_dbug_leave_calls
       and
       l_dbug_leave_calls = l_dbug_leave_on_error_calls
    then
      null;
    else
      dbms_output.put_line('# dbug.enter          calls: ' || l_dbug_enter_calls);
      dbms_output.put_line('# dbug.leave          calls: ' || l_dbug_leave_calls);
      dbms_output.put_line('# dbug.leave_on_error calls: ' || l_dbug_leave_on_error_calls);
    end if;  

    l_dbug_enter_calls := 0;
    l_dbug_leave_calls := 0;
    l_dbug_leave_on_error_calls := 0;
  end new_object;
begin
  for r in
  ( select  s.*
    from    user_source s
    where   s.name like nvl('&1', '%')
    and     s.type like nvl('&2', '%')
    and     s.type in ('TRIGGER', 'TYPE BODY', 'FUNCTION', 'PROCEDURE', 'PACKAGE BODY')
    order by
            s.name
    ,       s.type
    ,       s.line
  )
  loop
    if r.line = 1
    then
      new_object;
      r_prev := r;
    end if;

    r.text := lower(r.text);

    case
      when instr(r.text, 'dbug.enter') > 0
      then l_dbug_enter_calls := l_dbug_enter_calls + 1;      
      when instr(r.text, 'dbug.leave_on_error') > 0
      then l_dbug_leave_on_error_calls := l_dbug_leave_on_error_calls + 1;
      when instr(r.text, 'dbug.leave') > 0
      then l_dbug_leave_calls := l_dbug_leave_calls + 1;
      else null;
    end case;    
  end loop;

  -- close
  new_object;
end;
/
