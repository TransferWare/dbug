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
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

pdbug - Perl extension for C dbug library.

=head1 SYNOPSIS

  use pdbug;

  enter ( $i_module, $o_module_info );

  leave ( $i_module_info );

  push ( $i_options );

  print ( $i_keyword, $i_fmt, $i_arg1, $i_arg2, $i_arg3, $i_arg4, $i_arg5 );

  pop;

  process ( $i_process );

=head1 DESCRIPTION

The I<pdbug> package implements the functionality of the I<dbug> library
written by Fred Fish in the programming language C. This I<dbug> library can
be used to perform regression testing and profiling.

=over 4

=item enter

Enter a function. The arguments are the name of the function and a handle
for debugging information.

=item leave

Leave a function. This must always be called if enter was called before, even
if an exception has been raised.

=item push

Set global options, i.e. whether tracing is enabled or debugging, etc. 

=item print

Print a line. Parameters are a keyword and a I<printf> format
string and up till 5 string arguments. 

=item pop

Reset global options.

=item process

Set the name of the process.

=back

=head1 EXAMPLES

See file F<./test.pl> for an example.

=head1 AUTHOR

Gert-Jan Paulissen, E<lt>G.Paulissen@speed.A2000.nlE<gt>.

=head1 NOTES

None of the functions are exported: the names are too common. You have to use pdbug::<function>.

=head1 BUGS

=head1 SEE ALSO

=over 4

=item *

The I<dbug> documentation by Fred Fish.

=item *

perl(1).

=back

=cut

