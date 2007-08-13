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

## Call the perl Makefile from this makefile but in another directory at the same level 
## (needed for finding files in the tree).

perlbuilddir         = ../pdbug.perl

CP                   = cp -f

MAKEFILE_PERL_ENV    = CPPFLAGS="-I${srcdir}/../lib"

$(perlbuilddir): $(srcdir)/Makefile.PL $(srcdir)/pdbug.pm $(srcdir)/pdbug.xs $(srcdir)/test.pl
	test -d $@ || mkdir $@
	$(CP) $? $@
	cd $(perlbuilddir) && $(MAKEFILE_PERL_ENV) $(PERL) Makefile.PL
# $(perlbuilddir)/Makefile is newer than the .o files in ${top_builddir}/src/lib, so it would try to rebuild without touch
	touch ${top_builddir}/src/lib/*.o

## The targets for the Perl makefile can be found in ExtUtils::MakeMaker documentation.

all: all.perl

all.perl: $(perlbuilddir)
	cd $(perlbuilddir) && $(MAKE)

# check is the automake target, test is the Perl make target
check: test.perl

test.perl: $(perlbuilddir)
	cd $(perlbuilddir) && $(MAKE) test

install: install.perl

install.perl: $(perlbuilddir)
	cd $(perlbuilddir) && $(MAKE) install

uninstall: uninstall.perl

uninstall.perl: $(perlbuilddir)
	-cd $(perlbuilddir) && $(MAKE) uninstall

config: config.perl

config.perl: $(perlbuilddir)
	cd $(perlbuilddir) && $(MAKE) config

clean: clean.perl

clean.perl: 
	rm -fr $(perlbuilddir)

realclean: realclean.perl

realclean.perl: $(perlbuilddir)
	cd $(perlbuilddir) && $(MAKE) realclean

ci: ci.perl

ci.perl: $(perlbuilddir)
	cd $(perlbuilddir) && $(MAKE) ci

#dist: dist.perl

#dist.perl: $(perlbuilddir)
#	cd $(perlbuilddir) && $(MAKE) dist

## DOCUMENTATION section

all: pdbug.html

pdbug.html: $(srcdir)/pdbug.pm
	$(PERL) -S pod2html --infile=$< --outfile=$@
	-@rm pod2htm*.tmp

dist-hook:
	-@rm -fr $(perlbuilddir)

