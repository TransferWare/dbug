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

noinst_PROGRAMS      = factorial
factorial_SOURCES    = main.c factorial.c
LDADD                = $(top_builddir)/src/lib/libdbug.la
AM_CPPFLAGS          = -I$(top_srcdir)/src/lib

EXTRA_DIST           = Imakefile test1.ref test2.ref test3.ref test4.ref test5.ref test6.ref dbug.pod dbug.html

## DOCUMENTATION section

dbug.html: dbug.pod
	@PERL@ -S pod2html --infile=$? --outfile=$@

all: dbug.html

## TEST section

FACTORIAL = ./factorial

DBUGRPT = $(top_builddir)/src/prog/dbugrpt

$(DBUGRPT): force
	cd `dirname $@` && make

force: ;

# Ignore whitespace
DIFF = diff -w

doc_srcdir = $(top_srcdir)/doc

test: test1 test2 test3 test4 test5 test6

test1:
	$(FACTORIAL) 1 2 3 4 5 > $@.log

diff1:	test1
	$(DIFF) test1.log $(doc_srcdir)/test1.ref

test2:	$(DBUGRPT)
	$(FACTORIAL) -#t 3 2 | @PERL@ $(DBUGRPT) > $@.log

diff2:	test2
	$(DIFF) test2.log $(doc_srcdir)/test2.ref

test3:  $(DBUGRPT)
	$(FACTORIAL) -#d,t 3 | @PERL@ $(DBUGRPT) > $@.log

diff3:	test3
	$(DIFF) test3.log $(doc_srcdir)/test3.ref

test4:  $(DBUGRPT)
	$(FACTORIAL) -#d 4 | @PERL@ $(DBUGRPT) -d result > $@.log

diff4:	test4
	$(DIFF) test4.log $(doc_srcdir)/test4.ref

test5:  $(DBUGRPT)
# GJP 19-3-2003 Ignore changes due to differences between source and build locations.
	$(FACTORIAL) -#d 3 | @PERL@ $(DBUGRPT) -t factorial -FL | sed -e 's!$(top_srcdir)/doc/!!g' > $@.log

diff5:	test5
	$(DIFF) test5.log $(doc_srcdir)/test5.ref

test6:  $(DBUGRPT)
	$(FACTORIAL) -#t,D=1000,g 3 | @PERL@ $(DBUGRPT) > $@.log

diff6:	test6
	$(DIFF) test6.log $(doc_srcdir)/test6.ref

