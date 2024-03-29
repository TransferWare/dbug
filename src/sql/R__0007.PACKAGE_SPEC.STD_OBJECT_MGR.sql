CREATE OR REPLACE PACKAGE "STD_OBJECT_MGR" AUTHID DEFINER IS

c_debugging constant boolean := false; -- can only use dbms_output, not dbug
c_testing constant boolean := $if $$Testing $then true $else false $end;

/**

Since package state by definition is attached to an Oracle session, some
applications which are stateless (i.e. Apex) can not use normal package state
since that is bound to the APEX session id and username, not the Oracle
session id and username.

This package is used to centrally manage package state for several application
sessions during the lifetime of an Oracle session. An application session may
for instance be an APEX session or a Java web-app session but it can also be
just an Oracle session. Application sessions may share the same Oracle session
but for a different application user and/or application session.

The solution is to use object types (based on object type STD_OBJECT) for
storing the package state. Then this package will store the package state
objects in a PL/SQL lookup table of STD_OBJECTs indexed by the application
session information and a name for the package state object (for instance the
package you use to get/set this package state). So instead of managing your
own package state in each package where it is needed for several application
sessions at the same time you just need to:
1. create an object type based on STD_OBJECT
   (look at DBUG_OBJ_T and DBUG_LOG4PLSQL_OBJ_T for inspiration)
2. create a constructor that:
   - first tries to get the object (STD_OBJECT_MGR.GET_STD_OBJECT) AND
   - if that fails creates an object and stores it (STD_OBJECT_MGR.SET_STD_OBJECT)
3. override the member function NAME
4. override the member procedure SERIALIZE
5. anytime you CHANGE the object you have to:
   - set the DIRTY attribute to 1 (true) AND
   - store it (via STD_OBJECT_MGR.SET_STD_OBJECT)

So since the APEX Oracle session may serve several APEX sessions, you must
store local package state in a lookup table indexed by application session
info. The same is true for other type of applications like Java web-apps. The
convention prescribed by Oracle is that they set the client identifier (the
session's client id) by DBMS_SESSION.SET_IDENTIFIER. The client identifier set
can be returned by SYS_CONTEXT('USERENV','CLIENT_IDENTIFIER').

The application session (info) includes:
1. the database session id (SYS_CONTEXT('USERENV', 'SESSIONID'))
2. the database session username (SYS_CONTEXT('USERENV', 'SESSION_USER'))
3. the application session id (SYS_CONTEXT('APEX$SESSION', 'APP_SESSION'))
4. the application session username:
   - sys_context('APEX$SESSION', 'APP_USER') OR
   - regexp_substr(sys_context('USERENV', 'CLIENT_IDENTIFIER'), '^[^:]*')

The most important package that uses this STD_OBJECT_MGR functionality is
DBUG. DBUG needs package state to display the flow of a program with output
displaying entering or leaving a routine, based on UTL_CALL_STACK. And when
you want to use DBUG with APEX, you do not want to bother about package state
shared between different APEX sessions.

There are several plugins that can be used with DBUG like DBUG_LOG4PLSQL. They
too use this solution.

**/

subtype object_name_t is all_objects.object_name%type;

procedure get_std_object
( p_object_name in object_name_t -- The object name (usually STD_OBJECT.NAME)
, p_std_object out nocopy std_object -- The object
);
/**
Get a standard object (for the current application session).

The dirty column will be set to 0.
**/

procedure set_std_object
( p_object_name in object_name_t -- The object name (usually STD_OBJECT.NAME)
, p_std_object in out nocopy std_object -- The object
);
/**
Set a standard object (for the current application session).

Store an object in the following cases:
1. first when dirty equals 1
2. then if the object is not stored yet

The dirty column will be set to 0 at the end.
**/

procedure del_std_object
( p_object_name in object_name_t -- The object name (usually STD_OBJECT.NAME)
);
/**
Delete a standard object (for the current application session).

Throws a VALUE_ERROR when p_object_name is NULL.
**/

procedure get_object_names
( p_object_name_tab out nocopy sys.odcivarchar2list -- The list of object names found.
);
/**
Get object names (for the current application session).
**/

procedure delete_std_objects
( p_object_name in object_name_t default '%' -- The object name (wildcards allowed, escape character is '\')
);
/**
Delete objects (for the current application session).

So STD_OBJECT_MSG.DELETE_STD_OBJECTS will remove all objects for the current application session.

Throws a VALUE_ERROR when p_object_name is NULL.
**/

--%suitepath(DBUG)
--%suite

--%beforeeach
procedure ut_setup;

--%aftereach
procedure ut_teardown;

--%test
procedure ut_store_remove;

end;
/

