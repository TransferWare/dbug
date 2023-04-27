/* perl generate_ddl.pl (version 2023-01-05) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=EPCAPP --strip-source-schema */

/*
-- JDBC url - username : jdbc:oracle:thin:@pato - EPCAPP
-- source schema       : 
-- source database link: 
-- target schema       : EPCAPP
-- target database link: 
-- object type         : 
-- object names include: 1
-- object names        : DBUG,
DBUG_CALL_OBJ_T,
DBUG_CALL_TAB_T,
DBUG_DBMS_APPLICATION_INFO,
DBUG_DBMS_OUTPUT,
DBUG_LOG4PLSQL,
DBUG_LOG4PLSQL_OBJ_T,
DBUG_OBJ_T,
DBUG_PROFILER,
DBUG_TRIGGER,
STD_OBJECT,
STD_OBJECT_MGR,
UT_DBUG
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v5
-- transform params    : -SEGMENT_ATTRIBUTES,-TABLESPACE
-- exclude objects     : 
-- include objects     : 
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v5
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;EPCAPP;PACKAGE_SPEC;DBUG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "DBUG" FROM "PUBLIC";

/* SQL statement 2 (REVOKE;;OBJECT_GRANT;;EPCAPP;PACKAGE_SPEC;DBUG_PROFILER;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 2');
REVOKE EXECUTE ON "DBUG_PROFILER" FROM "PUBLIC";

/* SQL statement 3 (REVOKE;;OBJECT_GRANT;;EPCAPP;PACKAGE_SPEC;DBUG_TRIGGER;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 3');
REVOKE EXECUTE ON "DBUG_TRIGGER" FROM "PUBLIC";

/* SQL statement 4 (DROP;EPCAPP;PACKAGE_BODY;DBUG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
DROP PACKAGE BODY DBUG;

/* SQL statement 5 (DROP;EPCAPP;PACKAGE_BODY;DBUG_DBMS_APPLICATION_INFO;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
DROP PACKAGE BODY DBUG_DBMS_APPLICATION_INFO;

/* SQL statement 6 (DROP;EPCAPP;PACKAGE_BODY;DBUG_DBMS_OUTPUT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
DROP PACKAGE BODY DBUG_DBMS_OUTPUT;

/* SQL statement 7 (DROP;EPCAPP;PACKAGE_BODY;DBUG_LOG4PLSQL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP PACKAGE BODY DBUG_LOG4PLSQL;

/* SQL statement 8 (DROP;EPCAPP;PACKAGE_BODY;DBUG_PROFILER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 8');
DROP PACKAGE BODY DBUG_PROFILER;

/* SQL statement 9 (DROP;EPCAPP;PACKAGE_BODY;DBUG_TRIGGER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 9');
DROP PACKAGE BODY DBUG_TRIGGER;

/* SQL statement 10 (DROP;EPCAPP;PACKAGE_BODY;STD_OBJECT_MGR;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 10');
DROP PACKAGE BODY STD_OBJECT_MGR;

/* SQL statement 11 (DROP;EPCAPP;PACKAGE_BODY;UT_DBUG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 11');
DROP PACKAGE BODY UT_DBUG;

/* SQL statement 12 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_DBMS_APPLICATION_INFO;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 12');
DROP PACKAGE DBUG_DBMS_APPLICATION_INFO;

/* SQL statement 13 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_DBMS_OUTPUT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 13');
DROP PACKAGE DBUG_DBMS_OUTPUT;

/* SQL statement 14 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_LOG4PLSQL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 14');
DROP PACKAGE DBUG_LOG4PLSQL;

/* SQL statement 15 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_PROFILER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 15');
DROP PACKAGE DBUG_PROFILER;

/* SQL statement 16 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_TRIGGER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 16');
DROP PACKAGE DBUG_TRIGGER;

/* SQL statement 17 (DROP;EPCAPP;PACKAGE_SPEC;UT_DBUG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 17');
DROP PACKAGE UT_DBUG;

/* SQL statement 18 (DROP;EPCAPP;TYPE_BODY;DBUG_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 18');
DROP TYPE BODY DBUG_OBJ_T;

/* SQL statement 19 (DROP;EPCAPP;PACKAGE_SPEC;DBUG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 19');
DROP PACKAGE DBUG;

/* SQL statement 20 (DROP;EPCAPP;TYPE_BODY;DBUG_LOG4PLSQL_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 20');
DROP TYPE BODY DBUG_LOG4PLSQL_OBJ_T;

/* SQL statement 21 (DROP;EPCAPP;TYPE_BODY;STD_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 21');
DROP TYPE BODY STD_OBJECT;

/* SQL statement 22 (DROP;EPCAPP;PACKAGE_SPEC;STD_OBJECT_MGR;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 22');
DROP PACKAGE STD_OBJECT_MGR;

/* SQL statement 23 (DROP;EPCAPP;TYPE_SPEC;DBUG_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 23');
DROP TYPE DBUG_OBJ_T FORCE;

/* SQL statement 24 (DROP;EPCAPP;TYPE_SPEC;DBUG_CALL_TAB_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 24');
DROP TYPE DBUG_CALL_TAB_T FORCE;

/* SQL statement 25 (DROP;EPCAPP;TYPE_SPEC;DBUG_CALL_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 25');
DROP TYPE DBUG_CALL_OBJ_T FORCE;

/* SQL statement 26 (DROP;EPCAPP;TYPE_SPEC;DBUG_LOG4PLSQL_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 26');
DROP TYPE DBUG_LOG4PLSQL_OBJ_T FORCE;

/* SQL statement 27 (DROP;EPCAPP;TYPE_SPEC;STD_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 27');
DROP TYPE STD_OBJECT FORCE;

