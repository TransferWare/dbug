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

AUTOMAKE_OPTIONS     = $(top_srcdir)/src/lib/ansi2knr dejagnu

check_PROGRAMS       = dbugtest
dbugtest_SOURCES     = $(top_srcdir)/src/lib/dbug.c
dbugtest_LDADD       = $(top_builddir)/src/lib/libdbug.la
AM_CPPFLAGS          = -I$(top_srcdir)/src/lib -DDEBUG_DBUG=1 -DDBUGTEST
RUNTESTDEFAULTFLAGS  = --tool dbug DBUG=$$top_builddir/test/dbugtest --srcdir $$top_srcdir/test

EXTRA_DIST           = Imakefile

TESTS = test1 test2 test3 test4 test5

## Each test depends on this Makefile, because the code is here.
## Each test must be a program too, because of the test support by automake
## Therefore let each test be a script with a single true command (:).

$(TESTS): Makefile

CLEANFILES           = $(TESTS)

DBUGTEST = ./dbugtest

STDOUT = /dev/null
STDERR = /dev/null

test1 test2 test3 test4 test5:
	$(DBUGTEST) $@ 1>$(STDOUT) 2>$(STDERR)
	@echo : > $@
