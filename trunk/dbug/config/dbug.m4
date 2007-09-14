## ----------------------------------------- ##
## DBUG M4 macros for use in other projects. ##
## From Gert-Jan Paulissen                   ##
## ----------------------------------------- ##

# This file is part of dbug.
#
# Dbug is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Dbug is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with dbug.  If not, see <http://www.gnu.org/licenses/>.

AC_DEFUN([ACX_DBUG],
[AC_PREFIX_PROGRAM([dbugrpt])
AC_PATH_PROG([DBUGRPT],[dbugrpt])
acx_dbugrpt_dir=`dirname $DBUGRPT`
acx_dbugrpt_dir=`dirname $acx_dbugrpt_dir`
AC_SUBST([DBUG_LIBADD],[${acx_dbugrpt_dir}/lib/libdbug.la])
AC_SUBST([DBUG_LDADD],[${acx_dbugrpt_dir}/lib/libdbug.la])
AC_SUBST([DBUG_CPPFLAGS],[-I${acx_dbugrpt_dir}/include])
])

AC_DEFUN([ACX_ENABLE_DBUG],
[ACX_DBUG
])

AC_DEFUN([ACX_DISABLE_DBUG],
[ACX_DBUG
AC_DEFINE([DBUG_OFF],[1],
          [Define if NOT using the debugging package dbug])
])

AC_DEFUN([ACX_WITH_DBUG],
[AC_MSG_CHECKING([if debugging package dbug is wanted])
AC_ARG_WITH(dbug,
[  --with-dbug             use dbug, as in
                          http://www.sourceforge.net/projects/transferware],
[if test "$withval" = yes; then
  AC_MSG_RESULT(yes)
  ACX_ENABLE_DBUG
else
  AC_MSG_RESULT(no)
  ACX_DISABLE_DBUG
fi], 
[AC_MSG_RESULT(yes)
ACX_ENABLE_DBUG
])
])
