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

AUTOMAKE_OPTIONS     = ../src/lib/ansi2knr

INCLUDES	     = -I$(top_builddir) -I$(top_srcdir)

noinst_PROGRAMS      = factorial
                     = main.c factorial.c
LDADD                = ../src/lib/libulib.la
AM_CPPFLAGS          = -I../src/lib

EXTRA_DIST           = Imakefile test1.ref test2.ref test3.ref test4.ref test5.ref dbug.pod dbug.html

## DOCUMENTATION section

dbug.html: dbug.pod
	@PERL@ -S pod2html --infile=$? --outfile=$@

all: dbug.html

## TEST section

test: test1 test2 test3 test4 test5 test6

test1:
	$(FACTORIAL) 1 2 3 4 5 > $@.log

diff1:	test1
	$(DIFF) test1.log test1.ref

test2:
	$(FACTORIAL) -#t 3 2 | perl -S dbugrpt > $@.log

diff2:	test2
	$(DIFF) test2.log test2.ref

test3:
	$(FACTORIAL) -#d,t 3 | perl -S dbugrpt > $@.log

diff3:	test3
	$(DIFF) test3.log test3.ref

test4:
	$(FACTORIAL) -#d 4 | perl -S dbugrpt -d result > $@.log

diff4:	test4
	$(DIFF) test4.log test4.ref

test5:
	$(FACTORIAL) -#d 3 | perl -S dbugrpt -t factorial -FL > $@.log

diff5:	test5
	$(DIFF) test5.log test5.ref

test6:
	$(FACTORIAL) -#t,D=1000,g 3 | perl -S dbugrpt > $@.log

diff6:	test6
	$(DIFF) test6.log test6.ref

