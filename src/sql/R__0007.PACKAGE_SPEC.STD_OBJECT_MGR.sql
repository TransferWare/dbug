CREATE OR REPLACE PACKAGE "STD_OBJECT_MGR" AUTHID DEFINER IS
/**
--
-- This package is used to manage standard objects. Standard objects can be
-- used for package state. Since package state by definition is attached to an
-- Oracle session, some applications which are stateless (i.e. Apex) can not
-- use normal package state. But the standard objects can be used to implement
-- normal or stateless package state. First create an object type under
-- std_object. As an example see object type epc_clnt_object. Instead of
-- package variables an object must be created which contains the information
-- needed. This object is set and get by std_object_mgr.set_std_object()
-- respectively std_object_mgr.get_std_object(). Again see package epc_clnt
-- for examples.
--
-- Normal package state is implemented by leaving the group name null, i.e.
-- never call std_object_mgr.set_group_name() or call
-- std_object_mgr.set_group_name(null).  Now the objects will be retrieved
-- from a PL/SQL table indexed by the object name.
--
-- Stateless package state is implemented by setting the group name, a group
-- of associated objects.  Now the objects will be retrieved from the database
-- table std_objects using group name and object name.
--
-- An Apex session acts as a group. So the Apex session id can be used as the
-- group name. It is required to call std_object_mgr.set_group_name every time
-- another Oracle session may be used, which is while entering an Apex HTML
-- page.
--
-- @headcom
*/

c_debugging constant boolean := true; -- can only use dbms_output, not dbug
c_testing constant boolean := $if $$Testing $then true $else false $end;

/**
-- Set the group name.
--
-- Setting the group name to a non-NULL value will force the objects to use
-- table std_objects.
--
-- @param p_group_name  The group name
*/
procedure set_group_name
( p_group_name in std_objects.group_name%type
);

/**
-- Get the group name.
--
-- @return The group name set by set_group_name()
*/
function get_group_name
return std_objects.group_name%type;

/**
-- Get a standard object.
--
-- Retrieve an object from persistent storage (table std_objects) or from an
-- internal PL/SQL table. The dirty column will be set to 0.
--
-- @param p_object_name  The object name
-- @param p_std_object   The object
--
-- @throws no_data_found  No object found
*/
procedure get_std_object
( p_object_name in std_objects.object_name%type
, p_std_object out nocopy std_object
);

/**
-- Set a standard object.
--
-- Store an object in persistent storage (table std_objects) or into an
-- internal PL/SQL table unless the dirty column is equal to 0 AND the object
-- is already stored.
--
-- @param p_object_name  The object name
-- @param p_std_object   The object
*/
procedure set_std_object
( p_object_name in std_objects.object_name%type
, p_std_object in std_object
);

/**
-- Delete a standard object.
--
-- Deletes an object from persistent storage (table std_objects) or from an
-- internal PL/SQL table.
--
-- @param p_object_name  The object name.
--
-- @throws value_error  p_object_name is NULL
*/
procedure del_std_object
( p_object_name in std_objects.object_name%type
);

/**
-- Get object names.
--
-- Get the object names from persistent storage (table std_objects) or from an
-- internal PL/SQL table.
--
-- @param p_object_name_tab  The list of object names found.
--
-- @throws value_error  p_object_name is NULL
*/
procedure get_object_names
( p_object_name_tab out nocopy sys.odcivarchar2list
);

/**
-- Delete objects.
--
-- Delete objects from persistent storage (table std_objects) or from an
-- internal PL/SQL table.
--
-- @param p_group_name   The group name (wildcards allowed, escape character is '\').
--                       If null the PL/SQL table will be used to delete from.
-- @param p_object_name  The object name (wildcards allowed, escape character is '\').
--
-- @throws value_error  p_object_name is NULL
*/
procedure delete_std_objects
( p_group_name in std_objects.group_name%type default '%'
, p_object_name in std_objects.object_name%type default '%'
);


--%suitepath(DBUG)
--%suite
--%rollback(manual)

--%beforeall
procedure ut_setup;

--%afterall
procedure ut_teardown;

--%test
procedure ut_set_group_name;

--%test
procedure ut_get_group_name;

--%test
procedure ut_store_remove;

end;
/

