# -*-fundamental-*-
# Process this file with autoconf to produce a configure script.

# Copyright (C) 2002-2021 G.J. Paulissen
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

AC_REVISION([2022-11-24])
AC_INIT([dbug],[6.1.0],[gert.jan.paulissen@gmail.com])

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

AC_CONFIG_MACRO_DIR([config])
AC_CONFIG_AUX_DIR([config])
AH_BOTTOM(
[#if defined(STDC_HEADERS) && STDC_HEADERS
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#endif]
)
AC_SUBST([DBUGRPT_PREFIX_SEPARATOR],[:])
AC_CONFIG_SRCDIR([src/lib/dbug.c])
AC_CONFIG_HEADERS([config.h])

AC_CANONICAL_HOST

darwin=false

case ${host} in
*-cygwin)
  if gcc --version | grep -E "gcc \(GCC\) [1-3]\." 1>/dev/null 2>&1
  then
    # gcc (GCC) 1.x or 2.x or 3.x: use -mno-cygwin
    test "$CC" = "" && CC="gcc -mno-cygwin" && export CC
  fi
  ;;
*darwin*)
  darwin=true
  ;;
?*)
  ;;
*)
  AC_MSG_ERROR([Host not set])
	;;
esac

AM_CONDITIONAL([DARWIN], [test x$darwin = xtrue])

AM_INIT_AUTOMAKE([subdir-objects])

# AM_C_PROTOTYPES

# Checks for programs.
AC_PATH_PROG([PERL],[perl])
case x$PERL in
x)
	# No Perl avaliable: stop
	AC_MSG_ERROR([Perl must be available in \$PATH.])
	;;
esac
dnl AC_ARG_VAR(PERL,[The program name of Perl.])

# Checks for programs.
AC_PATH_PROG([PYTHON],[python3 python])
case x$PYTHON in
x)
	# No Python avaliable: stop
	AC_MSG_ERROR([Python must be available in \$PATH.])
	;;
esac
dnl AC_ARG_VAR(PYTHON,[The program name of Python.])

AC_PROG_CC

AC_LIBTOOL_WIN32_DLL
AC_PROG_LIBTOOL
AC_PROG_FGREP

LT_INIT
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
# Check for time related functions. One of them must be available (check clock first since it conforms to ISO C90)
AC_CHECK_FUNCS(
  [clock_gettime gettimeofday clock ftime getrusage],
  [break]
)
# Check the Posix threads pthread_key_create() and flockfile() function.
AC_SEARCH_LIBS([pthread_key_create], [pthread]) 
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

#AC_ARG_ENABLE([pdbug],
#              AS_HELP_STRING([--enable-pdbug],
#                             [install dbug for perl [default=no]]),
#              [case "$enableval" in
#                 yes) acx_cv_use_pdbug=true ;;
#                 no)  acx_cv_use_pdbug=false ;;
#                 *)   AC_MSG_ERROR([bad value ${enableval} for --enable-pdbug]) ;;
#               esac],
#              [acx_cv_use_pdbug=no])

# https://github.com/TransferWare/dbug/issues/2 - The perl module can not be built. 
acx_cv_use_pdbug=no

AM_CONDITIONAL([PDBUG], [test x$acx_cv_use_pdbug = xtrue])

AC_CONFIG_FILES([Makefile doc/Makefile src/Makefile src/lib/Makefile src/pdbug/Makefile src/prog/Makefile src/prog/dbugrpt src/prog/rf2dbug test/Makefile])

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
