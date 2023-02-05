CREATE OR REPLACE PACKAGE "DBUG2" AUTHID DEFINER IS

c_testing constant boolean := $if $$Testing $then true $else false $end;

subtype module_name_t is varchar2(4000);

-- Break points
subtype break_point_t is varchar2(100);

-- Some double quoted identifiers which you can use instead of literals.
-- Note that double quoted identifiers are case sensitive.
"debug"   constant break_point_t := 'debug';
"trace"   constant break_point_t := 'trace';
"input"   constant break_point_t := 'input';
"output"  constant break_point_t := 'output';
"info"    constant break_point_t := 'info';
"warning" constant break_point_t := 'warning';
"error"   constant break_point_t := 'error';
"fatal"   constant break_point_t := 'fatal';

procedure enter
( p_module in module_name_t
);

procedure leave;

procedure on_error;

procedure leave_on_error;

procedure print
( p_break_point in break_point_t
, p_str in varchar2
);

end dbug2;
/

