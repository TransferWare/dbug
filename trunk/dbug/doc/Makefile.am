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

AUTOMAKE_OPTIONS     = $(top_srcdir)/src/lib/ansi2knr

check_PROGRAMS       = factorial
factorial_SOURCES    = main.c factorial.c
factorial_LDADD      = $(top_builddir)/src/lib/libdbug.la
AM_CPPFLAGS          = -I$(top_srcdir)/src/lib

EXTRA_DIST           = Imakefile test1.ref test2.ref test3.ref test4.ref test5.ref test6.ref dbug.pod dbug.html

## DOCUMENTATION section

dbug.html: dbug.pod
	@PERL@ -S pod2html --infile=$? --outfile=$@

CLEANFILES = dbug.html pod2htm*

## TEST section

FACTORIAL = ./factorial

DBUGRPT = $(top_builddir)/src/prog/dbugrpt

# Ignore whitespace
DIFF = diff -w
GREP = grep

doc_srcdir = $(top_srcdir)/doc

TESTS = test1 test2 test3 test4 test5 test6

## Each test depends on this Makefile, because the code is here.
## Each test must be a program too, because of the test support by automake
## Therefore let each test be a script with a single true command (:).

$(TESTS): Makefile

CLEANFILES += $(TESTS) $(TESTS:=.log) test6.lis

test1:
	$(FACTORIAL) 1 2 3 4 5 > $@.log
	$(DIFF) $@.log $(doc_srcdir)/$@.ref
	@echo : > $@

test2:	$(DBUGRPT)
	$(FACTORIAL) -#t 3 2 | @PERL@ $(DBUGRPT) > $@.log
	$(DIFF) $@.log $(doc_srcdir)/$@.ref
	@echo : > $@

test3:  $(DBUGRPT)
	$(FACTORIAL) -#d,t 3 | @PERL@ $(DBUGRPT) > $@.log
	$(DIFF) $@.log $(doc_srcdir)/$@.ref
	@echo : > $@

test4:  $(DBUGRPT)
	$(FACTORIAL) -#d 4 | @PERL@ $(DBUGRPT) -d result > $@.log
	$(DIFF) $@.log $(doc_srcdir)/$@.ref
	@echo : > $@

test5:  $(DBUGRPT)
# GJP 19-3-2003 Ignore changes due to differences between source and build locations.
	$(FACTORIAL) -#d 3 | @PERL@ $(DBUGRPT) -t factorial -FL | sed -e 's!$(top_srcdir)/doc/!!g' > $@.log
	$(DIFF) $@.log $(doc_srcdir)/$@.ref
	@echo : > $@

test6:  $(DBUGRPT)
	$(FACTORIAL) -#t,D=1000,g 3 | @PERL@ $(DBUGRPT) > $@.log
# .ref file may be a DOS file, hence remove ^M
	sed "s/^M//g" $(doc_srcdir)/$@.ref > tmp.ref
	$(GREP) -f tmp.ref $@.log >$@.lis
	test "`cat $@.lis | wc -l`" -eq "`cat $@.log | wc -l`"
	@echo : > $@
