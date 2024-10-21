begin
  oracle_tools.cfg_install_ddl_pkg.column_ddl
  ( p_operation => 'MODIFY'
  , p_table_name => 'TLOG'
  , p_column_name => 'LSESSION'
  , p_extra => q'[DEFAULT case
  when sys_context('APEX$SESSION', 'APP_SESSION') is not null
  then 'APEX-' || sys_context('APEX$SESSION', 'APP_SESSION')
  else 'ORCL-' || sys_context('USERENV', 'SESSIONID')
end]'
  );
end;
/
