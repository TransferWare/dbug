## Makefile.am -- Process this file with automake to produce Makefile.in
## Copyright (C) 2002 G.J. Paulissen
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2, or (at your option)
## any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

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

EXTRA_DIST           = .lclintrc Imakefile dbug-def.msub dbugtest.ref
