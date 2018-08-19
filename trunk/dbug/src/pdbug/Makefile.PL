# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Carp;
use ExtUtils::MakeMaker;
use File::Basename;

# GJP 16-12-2006  Change Windows && command by two commands?
# Temporarily comment it out
=pod
sub MY::xs_c {
    package MY;
    my $inherited = shift->SUPER::xs_c(@_);

    $inherited =~ s/(.*) && (.*)/$1\n\t$2/;            
    $inherited;
}
=cut

foreach my $var ('CPPFLAGS') {
    die "Environment variable $var undefined.\n" unless exists($ENV{$var});
}

my $incpth = "$ENV{'CPPFLAGS'}";

my $makefile = 'Makefile';

my $libdir = '../lib';

WriteMakefile(
    'NAME'           => 'pdbug',
    'VERSION_FROM'   => 'pdbug.pm', # finds $VERSION
#    'LIBS'          => $libpth,   # e.g., '-lm' 
#    'OBJECT'         => "$libdir/dbug.o $libdir/Clock.o $libdir/SleepMsec.o " . '$(BASEEXT)$(OBJ_EXT)',
    'OBJECT'         => "$libdir/.libs/libdbug.a " . '$(BASEEXT)$(OBJ_EXT)',
    'CCFLAGS'        => undef,
    'OPTIMIZE'       => undef,
    'DEFINE'         => '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'            => $incpth     # e.g., '-I/usr/include/other' 
);


