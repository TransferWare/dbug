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

sub main 
{
  my ($result, $ix, $dbug_level);
  my $options = "";
  my $argc = $#ARGV + 1;
        
  for ($ix = 0; $ix < $argc && $ARGV[$ix] =~ m/^-#/; $ix++) 
  {
      $options = substr($ARGV[$ix], 2);
  }

  pdbug::init( $options, $ARGV[0] );
  pdbug::enter( "test.pl", "main", 1, $dbug_level );
  for (; $ix < $argc; $ix++) 
  {
    pdbug::print( 2, "args", sprintf( "argv[%d] = %d", $ix, $ARGV[$ix] ) );
    $result = &factorial ( $ARGV[$ix] );
    printf ("%d\n", $result);
  }
  pdbug::leave( 3, $dbug_level );
  pdbug::done( );
}

        
sub factorial 
{
  my $value = $_[0];
  my $dbug_level;

  pdbug::enter( "test.pl", "factorial", 4, $dbug_level );
  pdbug::print( 5, "find", sprintf( "find %d factorial" , $value ) );
  if ($value > 1) {
      $value *= &factorial ($value - 1);
  }
  pdbug::print( 6, "result", sprintf( "result is %d", $value ) );
  pdbug::leave( 7, $dbug_level );
  $value;
}

&main;
