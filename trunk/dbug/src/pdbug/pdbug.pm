package pdbug;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
@EXPORT_OK = qw(

);

( $VERSION ) = '$Revision$' =~ /\$Revision:\s+([^\s]+)/;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined pdbug macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap pdbug $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Documentation for pdbug.

=head1 NAME

pdbug - Perl extension for C dbug library.

=head1 SYNOPSIS

  use pdbug;

  init( $options, $name );
  init_ctx( $options, $name, $dbug_ctx );

  done();
  done_ctx( $dbug_ctx );

  enter( $file, $function, $line, $dbug_level );
  enter_ctx( $dbug_ctx, $file, $function, $line, $dbug_level );

  leave( $line, $dbug_level ); 
  leave_ctx( $dbug_ctx, $line, $dbug_level ); 

  print( $line, $break_point, $str );
  print_ctx( $dbug_ctx, $line, $break_point, $str );

=head1 DESCRIPTION

The I<pdbug> package implements the functionality of the I<dbug> library
written in the programming language C. This I<dbug> library can be used to
perform regression testing and profiling.

=over 4

=item init

Initialise a dbug context either implicit (init) or explicit (init_ctx). Set
debugging options, i.e. whether tracing is enabled or debugging, etc.

=item done

Destroy a dbug thread.

=item enter

Enter a function. Input parameters are the name of the file, function and a
line indicator. The level output parameter is used for checking balanced
enter/leave calls. The enter_ctx has an extra input parameter dbug context
which is set at init time.

Preconditions: init/init_ctx must be called before using these functions.

=item leave

Leave a function. This must always be called if enter was called before, even
if an exception has been raised. The input/output parameter dbug_level is used
to check balanced enter/leave calls.

Preconditions: init/init_ctx must be called before using these functions.

=item print

Print a line. Input parameters are a line and a break point and a string.

Preconditions: init/init_ctx must be called before using these functions.

=back

=head1 EXAMPLES

See file F<./test.pl> for an example.

=head1 AUTHOR

Gert-Jan Paulissen, E<lt>G.Paulissen@speed.A2000.nlE<gt>.

=head1 NOTES

This library is thread safe. When an implicit dbug context is used in a
multi-threading environment (Posix threads), thread specific data is used for
storing the dbug context.

None of the functions are exported: the names are too common. You have to use pdbug::<function>.

=head1 BUGS

=head1 SEE ALSO

=over 4

=item *

The I<dbug> documentation.

=item *

perl(1).

=back

=cut

