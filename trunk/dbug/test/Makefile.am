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

# AUTOMAKE_OPTIONS     = $(top_srcdir)/src/lib/ansi2knr dejagnu
AUTOMAKE_OPTIONS     = dejagnu

check_PROGRAMS       = dbugtest
dbugtest_SOURCES     = $(top_srcdir)/src/lib/dbug.c $(top_srcdir)/src/lib/Clock.c $(top_srcdir)/src/lib/SleepMsec.c
#dbugtest_LDADD       = $(top_builddir)/src/lib/libdbug.la
dbugtest_LDADD       = 
AM_CPPFLAGS          = -I$(top_srcdir)/src/lib -DDEBUG_DBUG=1 -DDBUGTEST
RUNTESTDEFAULTFLAGS  = --tool dbug DBUG=$$top_builddir/test/dbugtest --srcdir $$top_srcdir/test

EXTRA_DIST           = 

TESTS = test1 test2 test3 test4 test5 test6

## Each test depends on this Makefile, because the code is here.
## Each test must be a program too, because of the test support by automake
## Therefore let each test be a script with a single true command (:).

$(TESTS): Makefile

CLEANFILES           = $(TESTS)

DBUGTEST = ./dbugtest

STDOUT = /dev/null
STDERR = /dev/null

## Force each test to run again when make is invoked again.

FORCE = force

$(TESTS): $(FORCE)

$(FORCE): ;

# Create the test scripts which are run by dejagnu. The test scripts do nothing (:) but creating the test scripts
# is the actual test. Ensure the test scripts are made executable (chmod +x).

test1 test2 test3 test4 test5:
	$(DBUGTEST) $@ 1>$(STDOUT) 2>$(STDERR)
	@echo : > $@
	@chmod +x $@

test6:
	$(DBUGTEST) $@ d,t,g,D=1000 d:t:g:D,1000 b c a d 1>$(STDOUT) 2>$(STDERR)
	@echo : > $@
	@chmod +x $@

dist-hook:
	-@rm -f dbugtest.log
# GJP 2007-08-07 Do not where they come from
	-@test $(top_builddir) = $(top_srcdir) || rm -f $(top_builddir)/src/lib/Clock.c $(top_builddir)/src/lib/dbug.c $(top_builddir)/src/lib/SleepMsec.c
