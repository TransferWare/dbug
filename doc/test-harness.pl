#!/usr/bin/env perl

sub test1() {
# $(FACTORIAL) 1 2 3 4 5 > $@.log
# $(DIFF) $@.log $(doc_srcdir)/$@.ref
# @echo : > $@
# @chmod +x $@
}

sub test2() {
# $(FACTORIAL) -#t 3 2 | @PERL@ $(DBUGRPT) > $@.log
# $(DIFF) $@.log $(doc_srcdir)/$@.ref
# @echo : > $@
# @chmod +x $@
}

sub test3() {
# $(FACTORIAL) -#d,t 3 | @PERL@ $(DBUGRPT) > $@.log
# $(DIFF) $@.log $(doc_srcdir)/$@.ref
# @echo : > $@
# @chmod +x $@
}

sub test4() {
# $(FACTORIAL) -#d 4 | @PERL@ $(DBUGRPT) -d result > $@.log
# $(DIFF) $@.log $(doc_srcdir)/$@.ref
# @echo : > $@
# @chmod +x $@
}

sub test5() {
## GJP 19-3-2003 Ignore changes due to differences between source and build locations.
# $(FACTORIAL) -#d 3 | @PERL@ $(DBUGRPT) -t factorial -FL | sed -e 's!$(top_srcdir)/doc/!!g' > $@.log
# $(DIFF) $@.log $(doc_srcdir)/$@.ref
# @echo : > $@
# @chmod +x $@
}

sub test6() {
# $(FACTORIAL) -#t,D=1000,g 3 | @PERL@ $(DBUGRPT) > $@.log
# @PERL@ $(srcdir)/diffrex.pl $(srcdir)/test6.ref $@.log
# @echo : > $@
# @chmod +x $@
}

eval "$ARGV[0]";
