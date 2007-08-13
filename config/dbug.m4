## ----------------------------------- ##
## Check if --with-dbug was given.     ##
## From Gert-Jan Paulissen             ##
## ----------------------------------- ##

# Copyright 1996, 1998, 1999, 2000, 2001 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

AC_DEFUN([ACX_DBUG],
[AC_PREFIX_PROGRAM([dbugrpt])
AC_PATH_PROG([DBUGRPT],[dbugrpt])
acx_dbugrpt_dir=`dirname $DBUGRPT`
acx_dbugrpt_dir=`dirname $acx_dbugrpt_dir`
LDFLAGS="$LDFLAGS -L${acx_dbugrpt_dir}/lib"
CPPFLAGS="$CPPFLAGS -I${acx_dbugrpt_dir}/include"
])

AC_DEFUN([ACX_ENABLE_DBUG],
[ACX_DBUG
LIBS="$LIBS -ldbug"
AC_CHECK_FUNC([dbug_enter],[],[AC_MSG_ERROR(dbug_enter not found)])
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
