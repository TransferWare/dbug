/* perl generate_ddl.pl (version 2022-09-28) --nodynamic-sql --force-view --group-constraints --skip-install-sql --source-schema=EPCAPP --strip-source-schema */

/*
-- JDBC url            : jdbc:oracle:thin:EPCAPP@//localhost:1521/orcl
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
STD_OBJECTS,
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v5
-- transform params    : 
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v5
call dbms_application_info.set_module('uninstall.sql', null);

drop package STD_OBJECT_MGR;

/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;EPCAPP;PACKAGE_SPEC;DBUG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "DBUG" FROM "PUBLIC";

/* SQL statement 2 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_CHK1;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 2');
ALTER TABLE "STD_OBJECTS" DROP CONSTRAINT STD_OBJECTS_CHK1;

/* SQL statement 3 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_CHK2;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
ALTER TABLE "STD_OBJECTS" DROP CONSTRAINT STD_OBJECTS_CHK2;

/* SQL statement 4 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_CHK3;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
ALTER TABLE "STD_OBJECTS" DROP CONSTRAINT STD_OBJECTS_CHK3;

/* SQL statement 5 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_CHK4;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
ALTER TABLE "STD_OBJECTS" DROP CONSTRAINT STD_OBJECTS_CHK4;

/* SQL statement 6 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_PK;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
ALTER TABLE "STD_OBJECTS" DROP PRIMARY KEY KEEP INDEX;

/* SQL statement 7 (DROP;EPCAPP;INDEX;STD_OBJECTS_PK;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
DROP INDEX STD_OBJECTS_PK;

/* SQL statement 8 (DROP;EPCAPP;PACKAGE_BODY;DBUG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 8');
DROP PACKAGE BODY DBUG;

/* SQL statement 9 (DROP;EPCAPP;PACKAGE_BODY;DBUG_DBMS_APPLICATION_INFO;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 9');
DROP PACKAGE BODY DBUG_DBMS_APPLICATION_INFO;

/* SQL statement 10 (DROP;EPCAPP;PACKAGE_BODY;DBUG_DBMS_OUTPUT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 10');
DROP PACKAGE BODY DBUG_DBMS_OUTPUT;

/* SQL statement 11 (DROP;EPCAPP;PACKAGE_BODY;DBUG_LOG4PLSQL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 11');
DROP PACKAGE BODY DBUG_LOG4PLSQL;

/* SQL statement 12 (DROP;EPCAPP;PACKAGE_BODY;DBUG_PROFILER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 12');
DROP PACKAGE BODY DBUG_PROFILER;

/* SQL statement 13 (DROP;EPCAPP;PACKAGE_BODY;DBUG_TRIGGER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 13');
DROP PACKAGE BODY DBUG_TRIGGER;

/* SQL statement 14 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_DBMS_APPLICATION_INFO;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 14');
DROP PACKAGE DBUG_DBMS_APPLICATION_INFO;

/* SQL statement 15 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_DBMS_OUTPUT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 15');
DROP PACKAGE DBUG_DBMS_OUTPUT;

/* SQL statement 16 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_LOG4PLSQL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 16');
DROP PACKAGE DBUG_LOG4PLSQL;

/* SQL statement 17 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_PROFILER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 17');
DROP PACKAGE DBUG_PROFILER;

/* SQL statement 18 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_TRIGGER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 18');
DROP PACKAGE DBUG_TRIGGER;

/* SQL statement 19 (DROP;EPCAPP;TYPE_BODY;DBUG_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 19');
DROP TYPE BODY DBUG_OBJ_T;

/* SQL statement 20 (DROP;EPCAPP;PACKAGE_SPEC;DBUG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 20');
DROP PACKAGE DBUG;

/* SQL statement 21 (DROP;EPCAPP;TYPE_BODY;DBUG_LOG4PLSQL_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 21');
DROP TYPE BODY DBUG_LOG4PLSQL_OBJ_T;

/* SQL statement 22 (DROP;EPCAPP;TABLE;STD_OBJECTS;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 22');
DROP TABLE STD_OBJECTS PURGE;

/* SQL statement 23 (DROP;EPCAPP;TYPE_BODY;STD_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 23');
DROP TYPE BODY STD_OBJECT;

/* SQL statement 24 (DROP;EPCAPP;TYPE_SPEC;DBUG_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 24');
DROP TYPE DBUG_OBJ_T;

/* SQL statement 25 (DROP;EPCAPP;TYPE_SPEC;DBUG_CALL_TAB_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 25');
DROP TYPE DBUG_CALL_TAB_T;

/* SQL statement 26 (DROP;EPCAPP;TYPE_SPEC;DBUG_CALL_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 26');
DROP TYPE DBUG_CALL_OBJ_T;

/* SQL statement 27 (DROP;EPCAPP;TYPE_SPEC;DBUG_LOG4PLSQL_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 27');
DROP TYPE DBUG_LOG4PLSQL_OBJ_T;

/* SQL statement 28 (DROP;EPCAPP;TYPE_SPEC;STD_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 28');
DROP TYPE STD_OBJECT;

