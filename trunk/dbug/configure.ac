# Process this file with autoconf to produce a configure script.

# Copyright (C) 2002 G.J. Paulissen
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

AC_INIT([dbug],[0.9],[g.paulissen@chello.nl])
AC_CONFIG_AUX_DIR([config])
AC_CONFIG_SRCDIR([src/lib/dbug.c])
AC_CONFIG_HEADER([config.h])
AM_INIT_AUTOMAKE
AM_C_PROTOTYPES

# Checks for programs.
AC_PROG_CC
AM_PROG_CC_STDC
AC_LIBTOOL_WIN32_DLL
AC_PROG_LIBTOOL

# Checks for libraries.

# Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS([stdlib.h string.h unistd.h errno.h assert.h])
# Header files needed for timing functions.
AC_CHECK_HEADERS([time.h sys/timeb.h sys/param.h sys/time.h sys/resource.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_SIZE_T
AC_STRUCT_TM

# Checks for library functions.
AC_CHECK_FUNCS(
  [vfprintf memcmp memset strchr strpbrk],
  ,
  [AC_MSG_ERROR([Functions vfprintf(), memcmp(), memset(), strchr() and strpbrk() must be available.])]
)
# Check for time related functions. One of them must be available.
AC_CHECK_FUNCS(
  [clock ftime getrusage Datestamp],
  [break],
  [AC_MSG_ERROR([One of the functions clock(), ftime(), getrusage(), Datestamp() must be available.])]
)

# This is necessary so that .o files in LIBOBJS are also built via
# the ANSI2KNR-filtering rules.
LIB@&t@OBJS=`echo "$LIB@&t@OBJS" |
             sed 's,\.[[^.]]* ,$U&,g;s,\.[[^.]]*$,$U&,'`
LTLIBOBJS=`echo "$LIB@&t@OBJS" |
           sed 's,\.[[^.]]* ,.lo ,g;s,\.[[^.]]*$,.lo,'`
AC_SUBST(LTLIBOBJS)


AC_SUBST(ac_aux_dir)

AC_CONFIG_FILES([Makefile config/Makefile doc/Makefile src/Makefile src/lib/Makefile test/Makefile])
AC_OUTPUT

echo \
"------------------------------------------------------------------------
Configuration:

  Source code location:       ${srcdir}
  Compiler:                   ${CC}
  Compiler flags:             ${CFLAGS}
  Host System Type:           ${host}
  Install path:               ${prefix}

  See config.h for further configuration information.
------------------------------------------------------------------------"
