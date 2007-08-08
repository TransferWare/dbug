# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use ExtUtils::MakeMaker;
use Carp;

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

print STDERR "incpth: $incpth\n";

my $makefile = 'Makefile';

BEGIN {
    foreach my $ext ('old', 'perl') {
        croak("Could not remove $makefile.$ext: $!")
            if (-e "$makefile.$ext" && unlink("$makefile.$ext") != 1);
    }
    croak("Could not rename $makefile into $makefile.old: $!")
        if (-e $makefile && !rename($makefile, "$makefile.old"));
}

WriteMakefile(
    'FIRST_MAKEFILE' => "$makefile.perl",
    'NAME'           => 'pdbug',
    'VERSION_FROM'   => 'pdbug.pm', # finds $VERSION
#    'LIBS'          => $libpth,   # e.g., '-lm' 
    'OBJECT'         => '../lib/dbug.o ../lib/Clock.o ../lib/SleepMsec.o $(BASEEXT)$(OBJ_EXT)',
    'CCFLAGS'        => undef,
    'OPTIMIZE'       => undef,
    'DEFINE'         => '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'            => $incpth     # e.g., '-I/usr/include/other' 
);

croak("Could not rename $makefile into $makefile.perl: $!")
    if (-e $makefile && !rename($makefile, "$makefile.perl"));
croak("File $makefile.perl does not exists")
    unless (-e "$makefile.perl");

print STDOUT "Created $makefile.perl\n";

END {
    croak("Could not rename $makefile.old into $makefile: $!")
        if (-e "$makefile.old" && !rename("$makefile.old", $makefile));
}

