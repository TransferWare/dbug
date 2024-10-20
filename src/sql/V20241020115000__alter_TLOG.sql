begin
  oracle_tools.cfg_install_ddl_pkg.column_ddl
  ( p_operation => 'ADD'
  , p_table_name => 'TLOG'
  , p_column_name => 'LSESSION'
  , p_extra => q'[VARCHAR2(100 byte) DEFAULT case
  when sys_context('ONBOARDING', 'TOKEN') is not null
  then 'ONBOARDING-' || sys_context('ONBOARDING', 'TOKEN') 
  when sys_context('APEX$SESSION', 'APP_SESSION') is not null
  then 'APEX-' || sys_context('APEX$SESSION', 'APP_SESSION')
  else 'ORCL-' || sys_context('USERENV', 'SESSIONID')
end]'
  );
  oracle_tools.cfg_install_ddl_pkg.column_ddl
  ( p_operation => 'ADD'
  , p_table_name => 'TLOG'
  , p_column_name => 'UTC_TIMESTAMP'
  , p_extra => 'TIMESTAMP(6) DEFAULT SYS_EXTRACT_UTC(SYSTIMESTAMP)'
  );
end;
/
