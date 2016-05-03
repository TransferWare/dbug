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

# Documentation for pdbug.

=head1 NAME

pdbug - Perl extension for C dbug library.

=head1 SYNOPSIS

  use pdbug;

  my $status = &pdbug::init( $options, $name );
  my $status = &pdbug::init_ctx( $options, $name, \$dbug_ctx );
  # OO interface
  my $dbug_ctx = pdbug->new( $options, name );

=cut

sub init {
    my ($options, $name) = @_;

    my $status = &pdbug::_init($options, $name);

    return $status;
}

sub init_ctx {
    my ($options, $name, $r_dbug_ctx) = @_;

    my $status = &pdbug::_init_ctx($options, $name, $$r_dbug_ctx);

    return $status;
}

sub new {
    my ($class, $options, $name) = @_;

    my ($dbug_ctx);
    
    &pdbug::init_ctx($options, $name, \$dbug_ctx);

    return bless(\$dbug_ctx, $class)
}

=pod

  my $status = &pdbug::done();
  my $status = &pdbug::done_ctx( \$dbug_ctx );
  # OO interface
  undef $dbug_ctx;

=cut

sub done {
    my $status = &pdbug::_done();

    return $status;
}

sub done_ctx {
    my ($r_dbug_ctx) = @_;

    my $status = &pdbug::_done_ctx($$r_dbug_ctx);

    return $status;
}

sub DESTROY {
    my ($dbug_ctx) = @_;

    &pdbug::done_ctx(ref($dbug_ctx) ? $dbug_ctx : \$dbug_ctx);
}

=pod

  my $status = &pdbug::enter( \$dbug_level );
  my $status = &pdbug::enter_ctx( $dbug_ctx, \$dbug_level );
  # OO interface
  my $status = $dbug_ctx->enter( \$dbug_level );

=cut

sub enter {
    my ($package, $filename, $line, $subroutine) = caller(1);
    my $status;

    if (ref($_[0]) && ref($_[0]) ne 'SCALAR') {
	my ($r_dbug_ctx, $r_dbug_level) = @_;

	$status = &pdbug::_enter_ctx($$r_dbug_ctx, $filename, $subroutine, $line, $$r_dbug_level);
    } else {
	my ($r_dbug_level) = @_;

	$status = &pdbug::_enter($filename, $subroutine, $line, $$r_dbug_level);
    }

    return $status;
}

sub enter_ctx {
    my ($dbug_ctx, $r_dbug_level) = @_;
    my ($package, $filename, $line, $subroutine) = caller(1);

    my $status = &pdbug::_enter_ctx($dbug_ctx, $filename, $subroutine, $line, $$r_dbug_level);

    return $status;
}

=pod

  my $status = &pdbug::leave( $dbug_level ); 
  my $status = &pdbug::leave_ctx( $dbug_ctx, $dbug_level ); 
  # OO interface
  my $status = $dbug_ctx->leave( $dbug_level );

=cut

sub leave {
    my (undef, undef, $line, undef) = caller(1);
    my $status;

    if (ref($_[0])) {
	my ($r_dbug_ctx, $dbug_level) = @_;

	$status = &pdbug::_leave_ctx($$r_dbug_ctx, $line, $dbug_level);
    } else {
	my ($dbug_level) = @_;

	$status = &pdbug::_leave($line, $dbug_level);
    }
    return $status;
}

sub leave_ctx {
    my ($dbug_ctx, $dbug_level) = @_;
    my (undef, undef, $line, undef) = caller(1);

    my $status = &pdbug::_leave_ctx($dbug_ctx, $line, $dbug_level);

    return $status;
}

=pod

  my $status = &pdbug::print( $break_point, $str );
  my $status = &pdbug::print_ctx( $dbug_ctx, $break_point, $str );
  # OO interface
  my $status = $dbug_ctx->print( $break_point, $str );

=cut

sub print {
    my (undef, undef, $line, undef) = caller(1);
    my $status;

    if (ref($_[0])) {
	my ($r_dbug_ctx, $break_point, $str) = @_;

	$status = &pdbug::_print_ctx($$r_dbug_ctx, $line, $break_point, $str);
    } else {
	my ($break_point, $str) = @_;

	$status = &pdbug::_print($line, $break_point, $str);
    }

    return $status;
}

sub print_ctx {
    my ($dbug_ctx, $break_point, $str) = @_;
    my (undef, undef, $line, undef) = caller(1);

    my $status = &pdbug::_print_ctx($dbug_ctx, $line, $break_point, $str);

    return $status;
}

=pod

  my $status = &pdbug::dump( $line, $break_point, $memory, $len );
  my $status = &pdbug::dump_ctx( $dbug_ctx, $line, $break_point, $memory, $len );
  # OO interface
  my $status = $dbug_ctx->dump( $line, $break_point, $memory, $len );

=cut

sub dump {
    my (undef, undef, $line, undef) = caller(1);
    my $status;

    if (ref($_[0])) {
	my ($r_dbug_ctx, $break_point, $memory, $len) = @_;

	$status = &pdbug::_dump($$r_dbug_ctx, $line, $break_point, $memory, $len);
    } else {
	my ($break_point, $memory, $len) = @_;

	$status = &pdbug::_dump($line, $break_point, $memory, $len);
    }

    return $status;
}

sub dump_ctx {
    my ($dbug_ctx, $break_point, $memory, $len) = @_;
    my (undef, undef, $line, undef) = caller(1);

    my $status = &pdbug::_dump($dbug_ctx, $line, $break_point, $memory, $len);

    return $status;
}

=pod

=head1 DESCRIPTION

The I<pdbug> package implements the functionality of the I<dbug> library
written in the programming language C. This I<dbug> library can be used to
perform regression testing and profiling.

=over 4

=item init

=item init_ctx

=item new

Initialise a dbug context either implicit (init) or explicit
(init_ctx/new). Set debugging options, i.e. whether tracing is enabled
or debugging, etc. Returns 0 for init/init_ctx when correct and it
returns a reference to a debugging context for the OO interface.

=item done

=item done_ctx

Destroy a dbug thread. Returns 0 when correct. Only needed for the
procedural (non OO) interface. When the OO interface is used and the
debugging context object goes out of scope the DESTROY function will
call done_ctx automatically.

=item enter

=item enter_ctx

Enter a function. The dbug level parameter is used for
checking balanced enter/leave calls. The enter_ctx has an extra input
parameter dbug context which is set at init time. Returns 0 when correct.

Preconditions: init/init_ctx/new must be called before using these functions.

=item leave

=item leave_ctx

Leave a function. This must always be called if enter was called
before, even if an exception has been raised. The input parameter
dbug_level (set by enter) is used to check balanced enter/leave
calls. Returns 0 when correct.

Preconditions: init/init_ctx/new must be called before using these functions.

=item print

=item print_ctx

Print a line. Input parameters are a break point and a string. Returns 0 when correct.

Preconditions: init/init_ctx/new must be called before using these functions.

=item dump

=item dump_ctx

Dumps a memory structure. Input parameters are a break point,
the memory to print and the number of bytes to print. Returns 0 when correct.

Preconditions: init/init_ctx/new must be called before using these functions.

=back

=head1 EXAMPLES

See file F<./test.pl> for an example.

=head1 AUTHOR

Gert-Jan Paulissen, E<lt>gert.jan.paulissen@gmail.comE<gt>.

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

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
