# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use ExtUtils::MakeMaker;

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

die "DBUG_HOME environment variable must be defined.\n"
    if $ENV{DBUG_HOME} eq '';

$libpth .= ' -L' . $ENV{DBUG_HOME} . '/lib' . ' -ldbug';

$incpth = '-I' . $ENV{DBUG_HOME} . '/include';

WriteMakefile(
    'NAME'	=> 'pdbug',
    'VERSION_FROM' => 'pdbug.pm', # finds $VERSION
    'LIBS'	=> $libpth,   # e.g., '-lm' 
    'CCFLAGS'   => undef,
    'OPTIMIZE'  => undef,
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> $incpth,     # e.g., '-I/usr/include/other' 
);

