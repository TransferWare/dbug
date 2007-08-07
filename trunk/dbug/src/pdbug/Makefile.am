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

EXTRA_DIST           = Makefile.PL pdbug.html pdbug.pm pdbug.xs test.pl

## Call the perl makefile from this makefile
## Copy the sources first

builddir             = .

MAKEFILE_PERL        = $(builddir)/Makefile.perl

CP                   = cp -f

MAKEFILE_PERL_ENV    = CPPFLAGS="-I${srcdir}/../lib"

$(MAKEFILE_PERL): copy_sources
	$(MAKEFILE_PERL_ENV) $(PERL) Makefile.PL

copy_sources: Makefile_PL pdbug_pm pdbug_xs test_pl

Makefile_PL: $(srcdir)/Makefile.PL
	test $(builddir) = $(srcdir) || $(CP) $< $(builddir)

pdbug_pm: $(srcdir)/pdbug.pm
	test $(builddir) = $(srcdir) || $(CP) $< $(builddir)

pdbug_xs: $(srcdir)/pdbug.xs
	test $(builddir) = $(srcdir) || $(CP) $< $(builddir)

test_pl: $(srcdir)/test.pl
	test $(builddir) = $(srcdir) || $(CP) $< $(builddir)

## The targets for the Perl makefile can be found in ExtUtils::MakeMaker documentation.

all: all.perl

all.perl: $(MAKEFILE_PERL)
	$(MAKE) -f $< all

# check is the automake target, test is the Perl make target
check: test.perl

test.perl: $(MAKEFILE_PERL)
	$(MAKE) -f $< test

install: install.perl

install.perl: $(MAKEFILE_PERL)
	$(MAKE) -f $< install

config: config.perl

config.perl: $(MAKEFILE_PERL)
	$(MAKE) -f $< config

clean: clean.perl

clean.perl: $(MAKEFILE_PERL)
	$(MAKE) -f $< clean

realclean: realclean.perl

realclean.perl: $(MAKEFILE_PERL)
	$(MAKE) -f $< realclean

ci: ci.perl

ci.perl: $(MAKEFILE_PERL)
	$(MAKE) -f $< ci

dist: dist.perl

dist.perl: $(MAKEFILE_PERL)
	$(MAKE) -f $< dist

## DOCUMENTATION section

all: pdbug.html

pdbug.html: pdbug.pm
	$(PERL) -S pod2html --infile=$? --outfile=$@
	-@rm pod2htm*.tmp

dist-hook:
	-@rm -fr $(builddir)/blib
	-@rm $(MAKEFILE_PERL) $(builddir)/pdbug.bs $(builddir)/pdbug.c $(builddir)/pdbug.o $(builddir)/pm_to_blib $(builddir)/pdbug.html
	-@test $(builddir) = $(srcdir) || rm -f $(builddir)/Makefile.PL $(builddir)/pdbug.pm $(builddir)/pdbug.xs $(builddir)/test.pl

