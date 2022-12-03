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

# AUTOMAKE_OPTIONS     = $(top_srcdir)/src/lib/ansi2knr

check_PROGRAMS       = factorial
factorial_SOURCES    = main.c factorial.c
factorial_LDADD      = $(top_builddir)/src/lib/libdbug.la
AM_CPPFLAGS          = -I$(top_srcdir)/src/lib

EXTRA_DIST           = test1.ref test2.ref test3.ref test4.ref test5.ref test6.ref dbug.pod dbug.html diffrex.pl

POD2HTML             = pod2html

## DOCUMENTATION section
html: dbug.html

dbug.html: dbug.pod
	@PERL@ -S $(POD2HTML) --infile=$? --outfile=$@

CLEANFILES = dbug.html pod2htm* test?.out test?.txt

## TEST section

# GJP 15-12-2005
# The new libtoolize seems to create an empty factorial.exe in the build directory and ./factorial
# starts this dummy one. /bin/sh ./factorial starts the script though.
# FACTORIAL = $(SHELL) ./factorial

# GJP 02-01-2009
# Shell not needed anymore.

FACTORIAL = ./factorial

DBUGRPT = $(top_builddir)/src/prog/dbugrpt

# Ignore whitespace
DIFF = diff -w

FGREP = @FGREP@ -f

doc_srcdir = $(top_srcdir)/doc

TESTS = test1 test2 test3 test4 test5 test6

## Each test depends on this Makefile, because the code is here.
## Each test must be a program too, because of the test support by automake
## Therefore let each test be a script with a single true command (:).
## Ensure the test scripts are made executable (chmod +x).

$(TESTS): Makefile

CLEANFILES += $(TESTS) $(TESTS:=.log) test6.lis

test1:
	$(FACTORIAL) 1 2 3 4 5 > $@.txt
	$(DIFF) $@.txt $(doc_srcdir)/$@.ref
	@echo : > $@
	@chmod +x $@

test2:	$(DBUGRPT)
	$(FACTORIAL) -#t 3 2 > $@.out
	@PERL@ $(DBUGRPT) < $@.out > $@.txt
	$(DIFF) $@.txt $(doc_srcdir)/$@.ref
	@echo : > $@
	@chmod +x $@

test3:  $(DBUGRPT)
	$(FACTORIAL) -#d,t 3 > $@.out
	@PERL@ $(DBUGRPT) < $@.out > $@.txt
	$(DIFF) $@.txt $(doc_srcdir)/$@.ref
	@echo : > $@
	@chmod +x $@

test4:  $(DBUGRPT)
	$(FACTORIAL) -#d 4 > $@.out
	@PERL@ $(DBUGRPT) -d result < $@.out > $@.txt
	$(DIFF) $@.txt $(doc_srcdir)/$@.ref
	@echo : > $@
	@chmod +x $@

test5:  $(DBUGRPT)
# GJP 19-3-2003 Ignore changes due to differences between source and build locations.
	$(FACTORIAL) -#d 3 > $@.out
	cat $@.out | @PERL@ $(DBUGRPT) -t factorial -FL | sed -e 's!$(top_srcdir)/doc/!!g' > $@.txt
	$(DIFF) $@.txt $(doc_srcdir)/$@.ref
	@echo : > $@
	@chmod +x $@

test6:  $(DBUGRPT)
	$(FACTORIAL) -#t,D=1000,g 3 > $@.out
	@PERL@ $(DBUGRPT) < $@.out > $@.txt
	@PERL@ $(srcdir)/diffrex.pl $(srcdir)/test6.ref $@.txt
	@echo : > $@
	@chmod +x $@
