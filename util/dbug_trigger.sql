REMARK
REMARK Author    : Gert-Jan Paulissen
REMARK
REMARK Goal      : Create after row triggers
REMARK
REMARK Notes     : 
REMARK
REMARK Parameters:
PROMPT             1 - table name (wildcard)
PROMPT             &&1
PROMPT             2 - file name
PROMPT             &&2

SET DOCUMENT OFF

DOCUMENT

The following documentation uses the Perl pod format. A html file
can be constructed by: 

  pod2html --infile=dbug_trigger.sql --outfile=dbug_trigger.html

=pod

=head1 NAME

dbug_trigger - Create after row triggers for selected tables.

=head1 SYNOPSIS

  sqlplus @dbug_trigger.sql <table name> <file name>

=head1 DESCRIPTION

The created triggers use the dbug_trigger package for debugging the column
values of selected tables. Output is sent to a file.

=head1 NOTES

=head1 EXAMPLES

  In SQL*Plus:

  SQL> @dbug_trigger % trigger.sql

=head1 AUTHOR

Gert-Jan Paulissen

=head1 HISTORY

=head1 BUGS

=head1 SEE ALSO

=cut

#

set serveroutput on size 1000000 format trunc
set pagesize 0
set linesize 1000
set trimspool on
set feedback off
set verify off
set termout on
set define on

define date_version = '2021-08-02'

variable table_name varchar2(100)

begin
  :table_name := upper('&&1');
end;
/

define file_name = '&&2'

set pagesize 0 trimspool on feedback off echo off

spool &&file_name

select  'REMARK Generated by dbug_trigger.sql (&&date_version)'
from    dual
/

prompt

begin
  for r_trg in
  ( select  *
    from    ( select  tab.object_name table_name
              ,       /* NOTE trigger name
                         When the table name is longer than 25 the trigger name (table name appended with _DBUG)
                         will become too long (>30). Hence use a substring of table name, an underscore and table id
                         to make it unique and not too long.
                      */
                      case
                        when length(tab.object_name) > 25
                        then substr(tab.object_name, 1, 25 - 1 - length(to_char(tab.object_id)))
                             ||'_'
                             ||to_char(tab.object_id)
                        else tab.object_name
                      end 
                      ||'_DBUG' as trigger_name
              ,       'begin' column_name
              ,       -1 as column_id
              ,       to_char(null) as data_type
              ,       -1 as key_position
              from    user_objects tab
              where   tab.object_name like :table_name
              and     tab.object_type = 'TABLE'
              union
              select  col.table_name
              ,       null as trigger_name /* trigger_name only used for column_name 'begin' */
              ,       col.column_name
              ,       col.column_id
              ,       col.data_type
              ,       case 
                        when con.table_name is null -- there is no primary key, so every column is a key
                        then 0
                        else ( select  max(key.position)
                               from    user_cons_columns key
                               where   key.table_name = con.table_name
                               and     key.constraint_name = con.constraint_name
                               and     key.column_name = col.column_name
                             )
                      end as key_position
              from    user_tab_columns col
                      inner join user_objects tab
                      on tab.object_name = col.table_name and tab.object_type = 'TABLE'
                      left outer join user_constraints con
                      on con.table_name = col.table_name and con.constraint_type = 'P'
              where   tab.object_name like :table_name
              and     col.data_type in ( 'BINARY_INTEGER',
                                         'DEC',
                                         'DECIMAL',
                                         'DOUBLE PRECISION',
                                         'FLOAT',
                                         'INT',
                                         'INTEGER',
                                         'NATURAL',
                                         'NATURALN',
                                         'NUMBER',
                                         'NUMERIC',
                                         'PLS_INTEGER',
                                         'POSITIVE',
                                         'POSITIVEN',
                                         'REAL',
                                         'SIGNTYPE',
                                         'SMALLINT',
                                         'CHAR',
                                         'CHARACTER',
                                         'STRING',
                                         'VARCHAR',
                                         'VARCHAR2',
                                         'DATE',
                                         'TIMESTAMP(6)')
              union
              select  tab.object_name table_name
              ,       null as trigger_name /* trigger_name only used for column_name 'begin' */
              ,       'end' column_name
              ,       to_number(null) as column_id
              ,       to_char(null) as data_type
              ,       to_number(null) as key_position
              from    user_objects tab
              where   tab.object_name like :table_name
              and     tab.object_type = 'TABLE'
              union
              select  tab.object_name table_name
              ,       /* NOTE trigger name
                         When the table name is longer than 22 the trigger name (table name appended with _BS_DBUG)
                         will become too long (>30). Hence use a substring of table name, an underscore and table id
                         to make it unique and not too long.
                      */
                      case
                        when length(tab.object_name) > 22
                        then substr(tab.object_name, 1, 22 - 1 - length(to_char(tab.object_id)))
                             ||'_'
                             ||to_char(tab.object_id)
                        else tab.object_name
                      end 
                      ||'_AS_DBUG' as trigger_name
              ,       'after' column_name
              ,       -1 column_id
              ,       to_char(null) as data_type
              ,       -1 as key_position
              from    user_objects tab
              where   tab.object_name like :table_name
              and     tab.object_type = 'TABLE'
            )
    order by
            table_name
    ,       case column_name
              when 'begin' then 1
              when 'after' then 3
              else 2
            end
    ,       key_position
    ,       column_id
  ) 
  loop
    case r_trg.column_name
      when 'after'
      then
        dbms_output.put_line('create or replace trigger ' || lower(r_trg.trigger_name));
        dbms_output.put_line('after insert or update or delete on ' || lower(r_trg.table_name));
        dbms_output.put_line('begin');
        dbms_output.put('  dbug_trigger.process_dml( ''' || r_trg.table_name || '''');
        dbms_output.put_line(', inserting, updating, deleting, true );');
        dbms_output.put_line('end;');
        dbms_output.put_line('/');

      when 'begin'
      then
        dbms_output.put_line('create or replace trigger ' || lower(r_trg.trigger_name));
        dbms_output.put_line('after insert or update or delete on ' || lower(r_trg.table_name));
        dbms_output.put_line('for each row');
        dbms_output.put_line('begin');
        dbms_output.put('  dbug_trigger.enter( ''' || r_trg.table_name || '''');
        dbms_output.put_line(', ''' || r_trg.trigger_name || '''' || ', inserting, updating, deleting );');
--        dbms_output.put_line('  dbug.print( ''info'', ''from remote: %s'', dbms_reputil.from_remote );');

      when 'end'
      then
        -- dbms_output.put_line(chr(10));
        dbms_output.put_line('  dbug_trigger.leave;');
        dbms_output.put_line('exception');
        dbms_output.put_line('  when others');
        dbms_output.put_line('  then');
        dbms_output.put_line('    dbug_trigger.leave;');
        dbms_output.put_line('    /* ignore the exception */');
        dbms_output.put_line('end;');
        dbms_output.put_line('/');

      else
        dbms_output.put_line
        ( '  dbug_trigger.print( ' 
          ||case when r_trg.key_position is null then 'false' else 'true' end
          ||', ''' || r_trg.column_name || '''' 
          ||', '
          ||case when r_trg.data_type = 'TIMESTAMP(6)' then 'cast(' end
          ||':old.' || r_trg.column_name 
          ||case when r_trg.data_type = 'TIMESTAMP(6)' then ' as date)' end
          ||', '
          ||case when r_trg.data_type = 'TIMESTAMP(6)' then 'cast(' end
          ||':new.' || r_trg.column_name 
          ||case when r_trg.data_type = 'TIMESTAMP(6)' then ' as date)' end
          || ' );'
        );
    end case;
  end loop;
end;
/

spool off

undefine 1 2 file_name