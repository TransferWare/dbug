# -*-fundamental-*-
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

AC_REVISION([$Revision$])
AC_INIT([dbug],[3.3.0],[g.paulissen@chello.nl])

# version check
if test -f "$srcdir/VERSION"
then
  read version < $srcdir/VERSION
else
  version=
fi

if test "$version" != "$PACKAGE_VERSION"
then
  echo "Updating file $srcdir/VERSION with package version $PACKAGE_VERSION." 1>&2
  echo "$PACKAGE_VERSION" > $srcdir/VERSION
fi

AC_CONFIG_AUX_DIR([config])
AH_BOTTOM(
[#if defined(STDC_HEADERS) && STDC_HEADERS
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#endif]
)
AC_SUBST([DBUGRPT_PREFIX_SEPARATOR],[:])
AC_CONFIG_SRCDIR([src/lib/dbug.c])
AM_CONFIG_HEADER([config.h])
AM_INIT_AUTOMAKE
AM_C_PROTOTYPES

# Checks for programs.
AC_PATH_PROG([PERL],[perl])
case x$PERL in
x)
	# No Perl avaliable: stop
	AC_MSG_ERROR([Perl must be available in \$PATH.])
	;;
esac
dnl AC_ARG_VAR(PERL,[The program name of Perl.])
AC_PROG_CC
AM_PROG_CC_STDC
AC_LIBTOOL_WIN32_DLL
AC_PROG_LIBTOOL

# Checks for libraries.

# Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS([stdarg.h stdlib.h string.h unistd.h errno.h assert.h stdio.h pthread.h])
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
  [ftime getrusage clock],
  [break],
  [AC_MSG_ERROR([One of the functions ftime(), getrusage() or clock() must be available.])]
)
# Check the Posix threads flockfile() function.
AC_CHECK_FUNCS([flockfile])

# Check sleep functions: stop if one is found. None found is allowed.
AC_CHECK_FUNCS([sleep Delay], [break])

# This is necessary so that .o files in LIBOBJS are also built via
# the ANSI2KNR-filtering rules.
LIB@&t@OBJS=`echo "$LIB@&t@OBJS" |
             sed 's,\.[[^.]]* ,$U&,g;s,\.[[^.]]*$,$U&,'`
LTLIBOBJS=`echo "$LIB@&t@OBJS" |
           sed 's,\.[[^.]]* ,.lo ,g;s,\.[[^.]]*$,.lo,'`
AC_SUBST(LTLIBOBJS)

AC_SUBST(ac_aux_dir)

AC_CONFIG_FILES([Makefile config/Makefile doc/Makefile src/Makefile src/lib/Makefile src/pdbug/Makefile src/prog/Makefile src/prog/dbugrpt test/Makefile])
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
