## Makefile.am -- Process this file with automake to produce Makefile.in
## Copyright (C) 2002 G.J. Paulissen
##
## This library is free software; you can redistribute it and/or
## modify it under the terms of the GNU Lesser General Public
## License as published by the Free Software Foundation; either
## version 2.1 of the License, or (at your option) any later version.
##
## This library is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public
## License along with this library; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

MAINTAINERCLEANFILES = Makefile.in

AUTOMAKE_OPTIONS     = ansi2knr

AM_CPPFLAGS          = -I$(top_srcdir)/src/lib

include_HEADERS      = dbug.h

lib_LTLIBRARIES	     = libdbug.la
libdbug_la_SOURCES   = dbug.c Clock.c SleepMsec.c Clock.h SleepMsec.h vargs.h


##
## History of interface versions:
## - 0:0:0 start
## - 1:0:0 due to different format of timing info (in seconds) in the dbug output file

libdbug_la_LDFLAGS   = -no-undefined -version-info 1:0:0

EXTRA_DIST           = dbugtest.ref
