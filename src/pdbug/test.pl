# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $MAX_TESTCASES;

BEGIN { $MAX_TESTCASES = 18; $| = 1; print "1..$MAX_TESTCASES\n"; }
END {print "not ok 1\n" unless $loaded;}

use File::Spec;
use pdbug;

$loaded = 1;
print "ok 1\n";

close STDERR; # dbug prints warnings to stderr: disable them here

open(STDERR, ">" . File::Spec->devnull());

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub main 
{
    my ($testcase, $dbug_ctx, $dbug_level) = 2;

    # Test whether dbug_init writes a line containing #I#
    &pdbug::init('d,t,g,o=test.log', 'test'); 
    open(LOG, "<test.log") || die "Can not open test.log: $!\n";
    $_ = <LOG>;
    print $_ =~ m/#I#/ ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_init writes a line containing #D#
    &pdbug::done(); 
    $_ = <LOG>;
    close LOG;
    print $_ =~ m/#D#/ ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_init_ctx writes a line containing #I# and returns a non-zero context
    $dbug_ctx = &pdbug::init_ctx('d,t,g,o=test.log', 'test'); 
    open(LOG, "<test.log") || die "Can not open test.log: $!\n";
    $_ = <LOG>;
    print $_ =~ m/#I#/ && $dbug_ctx != 0 ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_done_ctxt writes a line containing #D# and sets the context to zero
    &pdbug::done_ctx($dbug_ctx);
    $_ = <LOG>;
    close LOG;
    print $_ =~ m/#D#/ && $dbug_ctx == 0 ? "" : "not ", "ok ", $testcase++, "\n";
    
    # Just initialize for enter/leave pairs
    &pdbug::init('d,t,g,o=test.log', 'test');
    open(LOG, "<test.log") || die "Can not open test.log: $!\n";
    $_ = <LOG>;

    # Test whether dbug_enter writes a line containing #E#
    $dbug_level = &pdbug::enter();
    $_ = <LOG>;
    print $_ =~ m/#E#/ && $dbug_level == 1 ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_enter writes a line containing #E# and increases the dbug level
    $dbug_level = &pdbug::enter();
    $_ = <LOG>;
    print $_ =~ m/#E#/ && $dbug_level == 2 ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_leave writes a line containing #L#
    &pdbug::leave($dbug_level);
    $_ = <LOG>;
    print $_ =~ m/#L#/ && $dbug_level == 2 ? "" : "not ", "ok ", $testcase++, "\n";

    $dbug_level--;

    # Test whether last dbug_print writes a line containing #P#
    &pdbug::print('info', 'Hello, world');
    $_ = <LOG>;
    print  $_ =~ m/#P#/ ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether last dbug_leave writes a line containing #L#
    &pdbug::leave($dbug_level);
    $_ = <LOG>;
    print $_ =~ m/#L#/ && $dbug_level == 1 ? "" : "not ", "ok ", $testcase++, "\n";
    
    # Test whether one dbug_leave too many does not print a line
    &pdbug::leave($dbug_level);
    $_ = <LOG>;
    print !defined($_) ? "" : "not ", "ok ", $testcase++, "\n";

    # Finished
    &pdbug::done();
    $_ = <LOG>;
    close LOG;

    exit 0;

    #
    # Now check the _ctx functions
    #

    # Just initialize for enter/leave pairs
    my $dbug_ctx = &pdbug::init_ctx('d,t,g,o=test.log', 'test');
    open(LOG, "<test.log") || die "Can not open test.log: $!\n";
    $_ = <LOG>;

    # Test whether dbug_enter_ctx writes a line containing #E#
    $dbug_level = &pdbug::enter_ctx($dbug_ctx);
    $_ = <LOG>;
    print $_ =~ m/#E#/ && $dbug_level == 1 ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_enter_ctx writes a line containing #E# and increases the dbug level
    $dbug_level = &pdbug::enter_ctx($dbug_ctx);
    $_ = <LOG>;
    print $_ =~ m/#E#/ && $dbug_level == 2 ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_leave_ctx writes a line containing #L#
    &pdbug::leave_ctx($dbug_ctx, $dbug_level);
    $_ = <LOG>;
    print $_ =~ m/#L#/ && $dbug_level == 2 ? "" : "not ", "ok ", $testcase++, "\n";
    
    $dbug_level--;

    # Test whether last dbug_print_ctx writes a line containing #P#
    &pdbug::print_ctx($dbug_ctx, 'info', 'Hello, world');
    $_ = <LOG>;
    print  $_ =~ m/#P#/ ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether last dbug_leave_ctx writes a line containing #L#
    &pdbug::leave_ctx($dbug_ctx, $dbug_level);
    $_ = <LOG>;
    print $_ =~ m/#L#/ && $dbug_level == 1 ? "" : "not ", "ok ", $testcase++, "\n";
    
    # Test whether one dbug_leave_ctx too many does not print a line
    &pdbug::leave_ctx($dbug_ctx, $dbug_level);
    $_ = <LOG>;
    print !defined($_) ? "" : "not ", "ok ", $testcase++, "\n";

    # Finished
    &pdbug::done_ctx($dbug_ctx);
    $_ = <LOG>;
    close LOG;

    # test actual number of testcases
    print $testcase == $MAX_TESTCASES ? "" : "not ", "ok ", $testcase++, "\n";

    my ($result, $ix);
    my $options = "";
    my $argc = $#ARGV + 1;
        
    for ($ix = 0; $ix < $argc && $ARGV[$ix] =~ m/^-(#|D)/; $ix++) 
    {
	$options = substr($ARGV[$ix], 2);
    }

    pdbug::init( $options, __FILE__ );
    $dbug_level = pdbug::enter();
    for (; $ix < $argc; $ix++) 
    {
	pdbug::print( "args", sprintf( "argv[%d] = %d", $ix, $ARGV[$ix] ) );
	$result = &factorial ( $ARGV[$ix] );
	printf ("%d\n", $result);
    }
    pdbug::leave( $dbug_level );
    pdbug::done( );
}


sub factorial 
{
    my $value = $_[0];
    my $dbug_level;

    $dbug_level = pdbug::enter( "factorial", 4 );
    pdbug::print( "find", sprintf( "find %d factorial" , $value ) );
    if ($value > 1) {
	$value *= &factorial ($value - 1);
    }
    pdbug::print( "result", sprintf( "result is %d", $value ) );
    pdbug::leave( $dbug_level );

    return $value;
}

&main;
