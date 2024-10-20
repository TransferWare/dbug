begin
  oracle_tools.cfg_install_ddl_pkg.column_ddl
  ( p_operation => 'ADD'
  , p_table_name => 'TLOG'
  , p_column_name => 'UTC_TIMESTAMP'
  , p_extra => 'TIMESTAMP(6) DEFAULT SYS_EXTRACT_UTC(SYSTIMESTAMP)'
  );
end;
/
