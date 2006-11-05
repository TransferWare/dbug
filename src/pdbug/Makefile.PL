# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use ExtUtils::MakeMaker;
use Carp;

sub MY::xs_c {
    package MY;
    my $inherited = shift->SUPER::xs_c(@_);

    $inherited =~ s/(.*) && (.*)/$1\n\t$2/;            
    $inherited;
}

my $libpth = "";
my $incpth = "";

if ( $^O eq 'MSWin32' ) {

    # LIB contains library search path (directories separated by a semi-colon)

    die "Library search path LIB undefined. Run vcvars32 for Microsoft Visual C++.\n"
	if $ENV{LIB} eq '';

    $libpth = '-L' . join( ' -L', split(/;/, $ENV{LIB}) );
}

$libpth .= ' -L../src -ldbug';

$incpth = '-I../src';

my $makefile = 'Makefile';

croak("Could not remove $makefile.old: $!")
    if (-e "$makefile.old" && unlink("$makefile.old") != 1);
croak("Could not rename $makefile into $makefile.old: $!")
    if (-e $makefile && !rename($makefile, "$makefile.old"));

WriteMakefile(
    'FIRST_MAKEFILE' => "$makefile.perl",
    'NAME'           => 'pdbug',
    'VERSION_FROM'   => 'pdbug.pm', # finds $VERSION
    'LIBS'	     => $libpth,   # e.g., '-lm' 
    'CCFLAGS'        => undef,
    'OPTIMIZE'       => undef,
    'DEFINE'	     => '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	     => $incpth,     # e.g., '-I/usr/include/other' 
);

croak("Could not rename $makefile into $makefile.perl: $!")
    if (!rename($makefile, "$makefile.perl"));
print STDOUT "Created $makefile.perl\n";
croak("Could not rename $makefile.old into $makefile: $!")
    if (-e "$makefile.old" && !rename("$makefile.old", $makefile));

