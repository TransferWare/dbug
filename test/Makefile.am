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

AUTOMAKE_OPTIONS     = $(top_srcdir)/src/lib/ansi2knr

noinst_PROGRAMS      = dbugtest
LDADD                = $(top_builddir)/src/lib/libdbug.la
AM_CPPFLAGS          = -I$(top_srcdir)/src/lib

EXTRA_DIST           = Imakefile

DIFFS = diff1 diff2 diff3 diff4 diff5 

$(DIFFS) diff6:
	$(SHELL) -c "cd $(top_builddir)/doc && $(MAKE) -f $(top_builddir)/doc/Makefile $@"

TESTS = test1 test2 test3 test4 test5

test: $(DIFFS) $(TESTS)

DBUGTEST = ./dbugtest

$(TESTS):
	$(DBUGTEST) $@ 1>/dev/null


