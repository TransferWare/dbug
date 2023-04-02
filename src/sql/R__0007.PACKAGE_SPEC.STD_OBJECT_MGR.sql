CREATE OR REPLACE PACKAGE "STD_OBJECT_MGR" AUTHID DEFINER IS

c_debugging constant boolean := false; -- can only use dbms_output, not dbug
c_testing constant boolean := $if $$Testing $then true $else false $end;

-- ORA-03001: unimplemented feature
e_unimplemented_feature exception;
pragma exception_init(e_unimplemented_feature, -3001);

-- ORA-
c_change_group_local_storage constant simple_integer := -20900;
e_change_group_local_storage exception;
pragma exception_init(e_change_group_local_storage, -20900);

/**

This package is used to manage standard objects. Standard objects can be used
for package state. Since package state by definition is attached to an Oracle
session, some applications which are stateless (i.e. Apex) can not use normal
package state since they may switch session between subsequent database
calls. But the standard objects can be used to implement normal or stateless
package state. First create an object type under std_object. As an example see
object type epc_clnt_object. Instead of package variables an object must be
created which contains the information needed. This object is set and get by
`STD_OBJECT_MGR.set_std_object()` respectively
`STD_OBJECT_MGR.get_std_object()`. Again see package `EPC_CLNT` for examples.

Normal package state is implemented by leaving the group name null, i.e.
never call `STD_OBJECT_MGR.set_group_name()` or call
`STD_OBJECT_MGR.set_group_name(null)`.  Now the objects will be retrieved
from a PL/SQL table indexed by the object name.

Stateless package state is implemented by setting the group name, a group
of associated objects.  Now the objects will be retrieved from the database
table std_objects using group name and object name.

An Apex session acts as a group. So the Apex session id can be used as the
group name. It is required to call `STD_OBJECT_MGR.set_group_name` every time
another Oracle session may be used, which is while entering an Apex HTML
page.

NOTE: currently (2023-04-02) there is an error when using `DBUG` with a
non-empty group so using a non-empty group will raise the
`e_unimplemented_feature` exception.

**/

procedure set_group_name
( p_group_name in std_objects.group_name%type -- The group name
);
/**
Set the group name.

Setting the group name to a non-NULL value will force the objects to use
table STD_OBJECTS.

Throws:
- e_change_group_local_storage: when changing from empty group to non-empty group (or vice versa) having local storage
- e_unimplemented_feature: otherwise when the new group is not empty
**/

function get_group_name
return std_objects.group_name%type; -- The group name set by set_group_name()
/** Get the group name. **/

procedure get_std_object
( p_object_name in std_objects.object_name%type -- The object name
, p_std_object out nocopy std_object -- The object
);
/**
Get a standard object.

Retrieve an object from persistent storage (table std_objects) or from an
internal PL/SQL table. The dirty column will be set to 0.
**/

procedure set_std_object
( p_object_name in std_objects.object_name%type -- The object name
, p_std_object in out nocopy std_object -- The object
);
/**
Set a standard object.

Store an object in persistent storage (table std_objects) or into an
internal PL/SQL table in the following three cases:
1. first when dirty equals 1
2. then if the object is not stored yet
3. else when the object stored is not equal to the input object (ignoring the dirty attribute)

The dirty column will be set to 0 at the end.
**/

procedure del_std_object
( p_object_name in std_objects.object_name%type -- The object name.
);
/**
Delete a standard object.

Deletes an object from persistent storage (table std_objects) or from an
internal PL/SQL table.

Throws a VALUE_ERROR when p_object_name is NULL.
**/

procedure get_object_names
( p_object_name_tab out nocopy sys.odcivarchar2list -- The list of object names found.
);
/**
Get object names.

Get the object names from persistent storage (table std_objects) or from an
internal PL/SQL table.
**/

procedure delete_std_objects
( p_group_name in std_objects.group_name%type default '%' -- The group name (wildcards allowed, escape character is '\'): if null the PL/SQL table will be used to delete from
, p_object_name in std_objects.object_name%type default '%' -- The object name (wildcards allowed, escape character is '\')
);
/**
Delete objects.

Delete objects from persistent storage (table std_objects) or from an
internal PL/SQL table.

Throws a VALUE_ERROR when p_object_name is NULL.
**/

--%suitepath(DBUG)
--%suite
--%rollback(manual)

--%beforeall
procedure ut_setup;

--%afterall
procedure ut_teardown;

--%test
--%throws(std_object_mgr.e_unimplemented_feature)
procedure ut_set_group_name;

--%test
--%throws(std_object_mgr.e_unimplemented_feature)
procedure ut_get_group_name;

--%test
procedure ut_store_remove;

end;
/

