# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $MAX_TESTCASES;
my $DEBUG = 0;

BEGIN { $MAX_TESTCASES = 27; $| = 1; print "1..$MAX_TESTCASES\n"; }
END {print "not ok 1\n" unless $loaded;}

use File::Spec;
use pdbug;

$loaded = 1;
print "ok 1\n";

close STDERR unless $DEBUG; # dbug prints warnings to stderr: disable them here

open(STDERR, ">" . File::Spec->devnull()) unless $DEBUG;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub main 
{
    &check_pdbug();
    &check_factorial();
}

sub check_pdbug {
    my ($testcase, $status, $dbug_ctx, $dbug_level) = 2;

    # Test whether dbug_init writes a line containing #I#
    $status = &pdbug::init('d,t,g,o=test.log', 'test'); 
    open(LOG, "<test.log") || die "Can not open test.log: $!\n";
    my $fh = select LOG;
    $| = 1;
    select $fh;


    #===========================================================================
    # Test the implicit pdbug functions (pdbug::init, pdbug::enter, ...)
    #===========================================================================

    $_ = <LOG>;
    # testcase 2 (first after load check)
    print $status == 0 && $_ =~ m/#I#/ ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_enter writes a line containing #E#
    $status = &pdbug::enter(\$dbug_level);
    $_ = <LOG>;
    # testcase 3
    print $status == 0 && $_ =~ m/#E#test.pl#main::check_pdbug#\d+/ && $dbug_level == 1 ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_enter writes a line containing #E#test.pl#main::check_pdbug#\d+ and increases the dbug level
    $status = &pdbug::enter(\$dbug_level);
    $_ = <LOG>;
    # testcase 4
    print $status == 0 && $_ =~ m/#E#test.pl#main::check_pdbug#\d+/ && $dbug_level == 2 ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether last dbug_print writes a line containing #P#test.pl#main::check_pdbug#\d+
    $status = &pdbug::print('info', 'Hello, world');
    $_ = <LOG>;
    # testcase 5
    print $status == 0 && $_ =~ m/#P#test.pl#main::check_pdbug#\d+/ ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_leave writes a line containing #L#test.pl#main::check_pdbug#\d+
    $status = &pdbug::leave($dbug_level);
    $_ = <LOG>;
    # testcase 6
    print $status == 0 && $_ =~ m/#L#test.pl#main::check_pdbug#\d+/ && $dbug_level == 2 ? "" : "not ", "ok ", $testcase++, "\n";

    $dbug_level--;

    # Test whether last dbug_leave writes a line containing #L#test.pl#main::check_pdbug#\d+
    $status = &pdbug::leave($dbug_level);
    $_ = <LOG>;
    # testcase 7
    print $status == 0 && $_ =~ m/#L#test.pl#main::check_pdbug#\d+/ && $dbug_level == 1 ? "" : "not ", "ok ", $testcase++, "\n";
    
    # Test whether one dbug_leave too many does not print a line
    $status = &pdbug::leave($dbug_level);
    $_ = <LOG>;
    # testcase 8
    print $status != 0 && !defined($_) ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_done writes a line containing #D#
    $status = &pdbug::done(); 
    $_ = <LOG>;
    close LOG;
    # testcase 9
    print $status == 0 && $_ =~ m/#D#/ ? "" : "not ", "ok ", $testcase++, "\n";

    #===========================================================================
    # Test the explicit pdbug functions (pdbug::init_ctx, pdbug::enter_ctx, ...)
    #===========================================================================

    # Test whether dbug_init_ctx writes a line containing #I# and returns a non-zero context
    $status = &pdbug::init_ctx('d,t,g,o=test.log', 'test', \$dbug_ctx); 
    open(LOG, "<test.log") || die "Can not open test.log: $!\n";
    $_ = <LOG>;
    # testcase 10
    print $status == 0 && $dbug_ctx != 0 && $_ =~ m/#I#/ ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_enter_ctx writes a line containing #E#test.pl#main::check_pdbug#\d+
    $status = &pdbug::enter_ctx($dbug_ctx, \$dbug_level);
    $_ = <LOG>;
    # testcase 11
    print $status == 0 && $_ =~ m/#E#test.pl#main::check_pdbug#\d+/ && $dbug_level == 1 ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_enter_ctx writes a line containing #E#test.pl#main::check_pdbug#\d+ and increases the dbug level
    $status = &pdbug::enter_ctx($dbug_ctx, \$dbug_level);
    $_ = <LOG>;
    # testcase 12
    print $status == 0 && $_ =~ m/#E#test.pl#main::check_pdbug#\d+/ && $dbug_level == 2 ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_leave_ctx writes a line containing #L#test.pl#main::check_pdbug#\d+
    $status = &pdbug::leave_ctx($dbug_ctx, $dbug_level);
    $_ = <LOG>;
    # testcase 13
    print $status == 0 && $_ =~ m/#L#test.pl#main::check_pdbug#\d+/ && $dbug_level == 2 ? "" : "not ", "ok ", $testcase++, "\n";
    
    $dbug_level--;

    # Test whether last dbug_print_ctx writes a line containing #P#test.pl#main::check_pdbug#\d+
    $status = &pdbug::print_ctx($dbug_ctx, 'info', 'Hello, world');
    $_ = <LOG>;
    # testcase 14
    print $status == 0 && $_ =~ m/#P#test.pl#main::check_pdbug#\d+/ ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether last dbug_leave_ctx writes a line containing #L#test.pl#main::check_pdbug#\d+
    $status = &pdbug::leave_ctx($dbug_ctx, $dbug_level);
    $_ = <LOG>;
    # testcase 15
    print $status == 0 && $_ =~ m/#L#test.pl#main::check_pdbug#\d+/ && $dbug_level == 1 ? "" : "not ", "ok ", $testcase++, "\n";
    
    # Test whether one dbug_leave_ctx too many does not print a line
    $status = &pdbug::leave_ctx($dbug_ctx, $dbug_level);
    $_ = <LOG>;
    # testcase 16
    print $status != 0 && !defined($_) ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_done_ctxt writes a line containing #D# and sets the context to zero
    $status = &pdbug::done_ctx(\$dbug_ctx);
    $_ = <LOG>;
    close LOG;
    # testcase 17
    print $status == 0 && $dbug_ctx == 0 && $_ =~ m/#D#/ ? "" : "not ", "ok ", $testcase++, "\n";
    
    #===========================================================================
    # Now check the OO interface
    #===========================================================================

    # Just initialize for enter/leave pairs
    $dbug_ctx = pdbug->new('d,t,g,o=test.log', 'test');
    open(LOG, "<test.log") || die "Can not open test.log: $!\n";
    $_ = <LOG>;
    # testcase 18
    print $$dbug_ctx != 0 && $_ =~ m/#I#/ ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_enter_ctx writes a line containing #E#test.pl#main::check_pdbug#\d+
    $status = $dbug_ctx->enter(\$dbug_level);
    $_ = <LOG>;
    # testcase 19
    print $status == 0 && $_ =~ m/#E#test.pl#main::check_pdbug#\d+/ && $dbug_level == 1 ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_enter_ctx writes a line containing #E#test.pl#main::check_pdbug#\d+ and increases the dbug level
    $status = $dbug_ctx->enter(\$dbug_level);
    $_ = <LOG>;
    # testcase 20
    print $status == 0 && $_ =~ m/#E#test.pl#main::check_pdbug#\d+/ && $dbug_level == 2 ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether dbug_leave_ctx writes a line containing #L#test.pl#main::check_pdbug#\d+
    $status = $dbug_ctx->leave($dbug_level);
    $_ = <LOG>;
    # testcase 21
    print $status == 0 && $_ =~ m/#L#test.pl#main::check_pdbug#\d+/ && $dbug_level == 2 ? "" : "not ", "ok ", $testcase++, "\n";
    
    $dbug_level--;

    # Test whether last dbug_print_ctx writes a line containing #P#test.pl#main::check_pdbug#\d+
    $status = $dbug_ctx->print('info', 'Hello, world');
    $_ = <LOG>;
    # testcase 22
    print $status == 0 && $_ =~ m/#P#test.pl#main::check_pdbug#\d+/ ? "" : "not ", "ok ", $testcase++, "\n";

    # Test whether last dbug_leave_ctx writes a line containing #L#test.pl#main::check_pdbug#\d+
    $status = $dbug_ctx->leave($dbug_level);
    $_ = <LOG>;
    # testcase 23
    print $status == 0 && $_ =~ m/#L#test.pl#main::check_pdbug#\d+/ && $dbug_level == 1 ? "" : "not ", "ok ", $testcase++, "\n";
    
    # Test whether one dbug_leave_ctx too many does not print a line
    $status = $dbug_ctx->leave($dbug_level);
    $_ = <LOG>;
    # testcase 24
    print $status != 0 && !defined($_) ? "" : "not ", "ok ", $testcase++, "\n";

    # Finished
    undef $dbug_ctx; # should call pdbug::DESTROY
    $_ = <LOG>;
    close LOG;
    # testcase 25
    print $_ =~ m/#D#/ ? "" : "not ", "ok ", $testcase++, "\n";

    # Is an empty dbug options string OK?
    $dbug_ctx = pdbug->new('', 'test');
    open(LOG, "<test.log") || die "Can not open test.log: $!\n";
    $_ = <LOG>;
    # testcase 26
    print $$dbug_ctx != 0 && $_ =~ m/#I#/ ? "" : "not ", "ok ", $testcase++, "\n";

    # clean up for distcheck
    unlink("test.log");

    # test actual number of testcases
    # testcase 27
    print $testcase == $MAX_TESTCASES ? "" : "not ", "ok ", $testcase++, "\n";
}

sub check_factorial {

    my ($result, $ix);
    my $options = "";
    my $argc = $#ARGV + 1;
        
    for ($ix = 0; $ix < $argc && $ARGV[$ix] =~ m/^-(#|D)/; $ix++) 
    {
        $options = substr($ARGV[$ix], 2);
    }

    &pdbug::init( $options, 'factorial' );
    &pdbug::enter(\$dbug_level);
    for (; $ix < $argc; $ix++) 
    {
        &pdbug::print( "args", sprintf( "argv[%d] = %d", $ix, $ARGV[$ix] ) );
        $result = &factorial ( $ARGV[$ix] );
        printf ("%d\n", $result);
    }
    &pdbug::leave( $dbug_level );
    &pdbug::done();
}

sub factorial 
{
    my $value = $_[0];
    my $dbug_level;

    &pdbug::enter(\$dbug_level);
    &pdbug::print( "find", sprintf( "find %d factorial" , $value ) );
    if ($value > 1) {
        $value *= &factorial ($value - 1);
    }
    &pdbug::print( "result", sprintf( "result is %d", $value ) );
    &pdbug::leave( $dbug_level );

    return $value;
}

&main;
