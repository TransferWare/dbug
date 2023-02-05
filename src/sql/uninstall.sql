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
DBUG2,
DBUG_CALL_OBJ_T,
DBUG_CALL_STACK,
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
STD_OBJECT_MGR,
UT_DBUG,
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v5
-- transform params    : 
-- exclude objects     : 
-- include objects     : 
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v5
call dbms_application_info.set_module('uninstall.sql', null);
/* SQL statement 1 (REVOKE;;OBJECT_GRANT;;EPCAPP;PACKAGE_SPEC;DBUG;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 1');
REVOKE EXECUTE ON "DBUG" FROM "PUBLIC";

/* SQL statement 2 (REVOKE;;OBJECT_GRANT;;EPCAPP;PACKAGE_SPEC;DBUG_TRIGGER;;PUBLIC;EXECUTE;NO;2) */
call dbms_application_info.set_action('SQL statement 2');
REVOKE EXECUTE ON "DBUG_TRIGGER" FROM "PUBLIC";

/* SQL statement 3 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_CHK1;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 3');
ALTER TABLE "STD_OBJECTS" DROP CONSTRAINT STD_OBJECTS_CHK1;

/* SQL statement 4 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_CHK2;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 4');
ALTER TABLE "STD_OBJECTS" DROP CONSTRAINT STD_OBJECTS_CHK2;

/* SQL statement 5 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_CHK3;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 5');
ALTER TABLE "STD_OBJECTS" DROP CONSTRAINT STD_OBJECTS_CHK3;

/* SQL statement 6 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_CHK4;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 6');
ALTER TABLE "STD_OBJECTS" DROP CONSTRAINT STD_OBJECTS_CHK4;

/* SQL statement 7 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_CHK5;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 7');
ALTER TABLE "STD_OBJECTS" DROP CONSTRAINT STD_OBJECTS_CHK5;

/* SQL statement 8 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_CHK6;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 8');
ALTER TABLE "STD_OBJECTS" DROP CONSTRAINT STD_OBJECTS_CHK6;

/* SQL statement 9 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_CHK7;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 9');
ALTER TABLE "STD_OBJECTS" DROP CONSTRAINT STD_OBJECTS_CHK7;

/* SQL statement 10 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_CHK8;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 10');
ALTER TABLE "STD_OBJECTS" DROP CONSTRAINT STD_OBJECTS_CHK8;

/* SQL statement 11 (ALTER;EPCAPP;CONSTRAINT;STD_OBJECTS_PK;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 11');
ALTER TABLE "STD_OBJECTS" DROP PRIMARY KEY KEEP INDEX;

/* SQL statement 12 (DROP;EPCAPP;INDEX;STD_OBJECTS_PK;EPCAPP;TABLE;STD_OBJECTS;;;;;2) */
call dbms_application_info.set_action('SQL statement 12');
DROP INDEX STD_OBJECTS_PK;

/* SQL statement 13 (DROP;EPCAPP;PACKAGE_BODY;DBUG2;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 13');
DROP PACKAGE BODY DBUG2;

/* SQL statement 14 (DROP;EPCAPP;PACKAGE_BODY;DBUG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 14');
DROP PACKAGE BODY DBUG;

/* SQL statement 15 (DROP;EPCAPP;PACKAGE_BODY;DBUG_CALL_STACK;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 15');
DROP PACKAGE BODY DBUG_CALL_STACK;

/* SQL statement 16 (DROP;EPCAPP;PACKAGE_BODY;DBUG_DBMS_APPLICATION_INFO;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 16');
DROP PACKAGE BODY DBUG_DBMS_APPLICATION_INFO;

/* SQL statement 17 (DROP;EPCAPP;PACKAGE_BODY;DBUG_DBMS_OUTPUT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 17');
DROP PACKAGE BODY DBUG_DBMS_OUTPUT;

/* SQL statement 18 (DROP;EPCAPP;PACKAGE_BODY;DBUG_LOG4PLSQL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 18');
DROP PACKAGE BODY DBUG_LOG4PLSQL;

/* SQL statement 19 (DROP;EPCAPP;PACKAGE_BODY;DBUG_PROFILER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 19');
DROP PACKAGE BODY DBUG_PROFILER;

/* SQL statement 20 (DROP;EPCAPP;PACKAGE_BODY;DBUG_TRIGGER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 20');
DROP PACKAGE BODY DBUG_TRIGGER;

/* SQL statement 21 (DROP;EPCAPP;PACKAGE_BODY;STD_OBJECT_MGR;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 21');
DROP PACKAGE BODY STD_OBJECT_MGR;

/* SQL statement 22 (DROP;EPCAPP;PACKAGE_BODY;UT_DBUG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 22');
DROP PACKAGE BODY UT_DBUG;

/* SQL statement 23 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_CALL_STACK;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 23');
DROP PACKAGE DBUG_CALL_STACK;

/* SQL statement 24 (DROP;EPCAPP;PACKAGE_SPEC;DBUG2;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 24');
DROP PACKAGE DBUG2;

/* SQL statement 25 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_DBMS_APPLICATION_INFO;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 25');
DROP PACKAGE DBUG_DBMS_APPLICATION_INFO;

/* SQL statement 26 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_DBMS_OUTPUT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 26');
DROP PACKAGE DBUG_DBMS_OUTPUT;

/* SQL statement 27 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_LOG4PLSQL;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 27');
DROP PACKAGE DBUG_LOG4PLSQL;

/* SQL statement 28 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_PROFILER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 28');
DROP PACKAGE DBUG_PROFILER;

/* SQL statement 29 (DROP;EPCAPP;PACKAGE_SPEC;DBUG_TRIGGER;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 29');
DROP PACKAGE DBUG_TRIGGER;

/* SQL statement 30 (DROP;EPCAPP;TYPE_BODY;DBUG_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 30');
DROP TYPE BODY DBUG_OBJ_T;

/* SQL statement 31 (DROP;EPCAPP;PACKAGE_SPEC;DBUG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 31');
DROP PACKAGE DBUG;

/* SQL statement 32 (DROP;EPCAPP;TYPE_BODY;DBUG_LOG4PLSQL_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 32');
DROP TYPE BODY DBUG_LOG4PLSQL_OBJ_T;

/* SQL statement 33 (DROP;EPCAPP;TYPE_BODY;STD_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 33');
DROP TYPE BODY STD_OBJECT;

/* SQL statement 34 (DROP;EPCAPP;PACKAGE_SPEC;STD_OBJECT_MGR;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 34');
DROP PACKAGE STD_OBJECT_MGR;

/* SQL statement 35 (DROP;EPCAPP;PACKAGE_SPEC;UT_DBUG;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 35');
DROP PACKAGE UT_DBUG;

/* SQL statement 36 (DROP;EPCAPP;TABLE;STD_OBJECTS;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 36');
DROP TABLE STD_OBJECTS PURGE;

/* SQL statement 37 (DROP;EPCAPP;TYPE_SPEC;DBUG_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 37');
DROP TYPE DBUG_OBJ_T FORCE;

/* SQL statement 38 (DROP;EPCAPP;TYPE_SPEC;DBUG_CALL_TAB_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 38');
DROP TYPE DBUG_CALL_TAB_T FORCE;

/* SQL statement 39 (DROP;EPCAPP;TYPE_SPEC;DBUG_CALL_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 39');
DROP TYPE DBUG_CALL_OBJ_T FORCE;

/* SQL statement 40 (DROP;EPCAPP;TYPE_SPEC;DBUG_LOG4PLSQL_OBJ_T;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 40');
DROP TYPE DBUG_LOG4PLSQL_OBJ_T FORCE;

/* SQL statement 41 (DROP;EPCAPP;TYPE_SPEC;STD_OBJECT;;;;;;;;2) */
call dbms_application_info.set_action('SQL statement 41');
DROP TYPE STD_OBJECT FORCE;

