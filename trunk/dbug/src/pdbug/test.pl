# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use pdbug;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub main {
	my ($result, $ix, $handle);
	my $argc = $#ARGV + 1;
        
	pdbug::enter( "main", $handle );

	pdbug::process($ARGV[0]);

	for ($ix = 0; $ix < $argc; $ix++) {
                if ( $ARGV[$ix] =~ m/^-#/ ) {
			pdbug::push( substr($ARGV[$ix], 2) );
                } else {
	                pdbug::print ("args", "argv[%s] = %s", "$ix", $ARGV[$ix] );
        	        $result = &factorial ( $ARGV[$ix] );
                	printf ("%d\n", $result);
		}
	}
	pdbug::leave( $handle );
}

        
sub factorial {
	my $value = $_[0];
	my $handle;

	pdbug::enter ("factorial", $handle);
	pdbug::print ("find", "find %s factorial" , "$value" );
	if ($value > 1) {
		$value *= &factorial ($value - 1);
	}
	pdbug::print ("result", "result is %s", "$value" );
	pdbug::leave( $handle );
	$value;
}

&main;
