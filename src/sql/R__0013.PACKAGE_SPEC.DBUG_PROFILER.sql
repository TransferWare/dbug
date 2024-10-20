CREATE OR REPLACE PACKAGE "DBUG_PROFILER" AUTHID DEFINER AS

-- SYSTIMESTAMP
subtype t_timestamp is timestamp(6);

type t_profile_rec is record (
  /* see dbugrpt */
  module_name dbug.module_name_t -- varchar2(4000)
, nr_calls integer
--  perc_calls number
, elapsed_time number
--  perc_time number
, avg_time number
--, min_time number
--, max_time number
--, weight integer
);

type t_profile_tab is table of t_profile_rec;

procedure enter(
  p_module in dbug.module_name_t
, p_timestamp in t_timestamp default sys_extract_utc(systimestamp) -- https://github.com/TransferWare/dbug/issues/10
);

procedure leave
( p_timestamp in t_timestamp default sys_extract_utc(systimestamp) -- https://github.com/TransferWare/dbug/issues/10
);

procedure done;

function show
return t_profile_tab pipelined;

-- necessary functions for the dbug interface but they do nothing
procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2
);

procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2,
  p_arg2 in varchar2
);

procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2,
  p_arg2 in varchar2,
  p_arg3 in varchar2
);

procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2,
  p_arg2 in varchar2,
  p_arg3 in varchar2,
  p_arg4 in varchar2
);

procedure print(
  p_break_point in varchar2,
  p_fmt in varchar2,
  p_arg1 in varchar2,
  p_arg2 in varchar2,
  p_arg3 in varchar2,
  p_arg4 in varchar2,
  p_arg5 in varchar2
);

$if oracle_tools.cfg_pkg.c_testing $then

-- test functions

--%suitepath(DBUG)
--%suite

--%beforeall
procedure ut_setup;

--%afterall
procedure ut_teardown;

--%test
procedure ut_test;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

end dbug_profiler;
/

