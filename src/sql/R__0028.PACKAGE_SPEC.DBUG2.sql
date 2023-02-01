CREATE OR REPLACE PACKAGE "DBUG2" AUTHID DEFINER IS

-- https://renenyffenegger.ch/notes/development/databases/Oracle/installed/packages/utl/call_stack/index

procedure ut_run;

procedure ut_show_stack(i_am in varchar2);
    
end dbug2;
/

