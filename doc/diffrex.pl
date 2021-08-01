use autodie;
use strict;
use warnings;

use Test::More; # do not know how many in advance

# VARIABLES

my $verbose = 0;

# PROTOTYPES

sub main ();

# MAIN

main();

# SUBROUTINES

sub main () {
    my $rex_file = shift @ARGV;

    plan tests => scalar(@ARGV);

    open(my $fh, '<', $rex_file);
    chomp(my @rex_lines = <$fh>);
    close $fh;
    
    foreach my $file (@ARGV) {
        open $fh, '<', $file;

        eval {
            my $line_nr = 0;
            
            foreach (<$fh>) {
                chomp;
                diag("line nr: ", $line_nr + 1)
                    if $verbose;
                diag("line      : ^", $_, '$')
                    if $verbose;
                diag("expression: ^", $rex_lines[$line_nr], '$')
                    if $verbose;
                die sprintf("%s:%d: line (%s) does not match REX (%s)",
                            $file,
                            $line_nr + 1,
                            $_,
                            $rex_lines[$line_nr])
                    unless m/^$rex_lines[$line_nr]$/;
                $line_nr++;
            }
            die sprintf("%s:%d: line number exceeds number of REX lines (%d)",
                        $file,
                        $line_nr + 1,
                        scalar(@rex_lines))
                unless $line_nr == scalar(@rex_lines);
        };
        
        close $fh;

        ok(!defined($@) || $@ eq '', "file $file should match REX file $rex_file") or diag($@);
    }    
}

