#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec::Functions 'catfile';
use File::Basename;

my $CMAKE_CURRENT_SOURCE_DIR = dirname($0);
my $CMAKE_CURRENT_BINARY_DIR = shift @ARGV;
my $factorial = catfile($CMAKE_CURRENT_BINARY_DIR, 'factorial');
my $diff = 'diff';

sub execute ($);
sub check_status ($$);
sub main();

main();

sub main() {
    foreach my $argv (@ARGV) {
        eval "$argv";
        die $@
            if $@;
    }
}

sub test1() {
    execute("$factorial 1 2 3 4 5 > test1.log");
    execute("$diff test1.log $CMAKE_CURRENT_SOURCE_DIR/test1.ref");
}

sub test2() {
    execute("$factorial -#t 3 2 | perl $CMAKE_CURRENT_SOURCE_DIR/../src/prog/dbugrpt > test2.log");
    execute("$diff test2.log $CMAKE_CURRENT_SOURCE_DIR/test2.ref");
}

sub test3() {
    execute("$factorial -#d,t 3 | perl $CMAKE_CURRENT_SOURCE_DIR/../src/prog/dbugrpt > test3.log");
    execute("$diff test3.log $CMAKE_CURRENT_SOURCE_DIR/test3.ref");
}

sub test4() {
    execute("$factorial -#d 4 | perl $CMAKE_CURRENT_SOURCE_DIR/../src/prog/dbugrpt -d result > test4.log");
    execute("$diff test4.log $CMAKE_CURRENT_SOURCE_DIR/test4.ref");
}

sub test5() {
    execute("$factorial -#d 3 | perl $CMAKE_CURRENT_SOURCE_DIR/../src/prog/dbugrpt -t factorial -FL | perl -ne 's!$CMAKE_CURRENT_SOURCE_DIR/!!; print' > test5.log");
    execute("$diff test5.log $CMAKE_CURRENT_SOURCE_DIR/test5.ref");
}

sub test6() {
    execute("$factorial -#t,D=1000,g 3 | perl $CMAKE_CURRENT_SOURCE_DIR/../src/prog/dbugrpt > test6.log");
    execute("perl $CMAKE_CURRENT_SOURCE_DIR/diffrex.pl $CMAKE_CURRENT_SOURCE_DIR/test6.ref test6.log");
}

sub execute ($) {
    my ($cmd) = @_;

    eval {
        system($cmd);
    };

    my $process = $cmd;
    
    die "$process\n$@" if $@;
    check_status($process, $?);
}

sub check_status ($$) {
    my ($process, $status) = @_;

    if (defined($status)) {
        if ($status == -1) {
            die "$process\nFailed to execute: $!";
        }
        elsif ($status & 127) {
            die sprintf("$process\nChild died with signal %d, %s coredump", ($status & 127),  ($status & 128) ? 'with' : 'without');
        }
        elsif (($status >> 8) != 0) {
            die sprintf("$process\nChild exited with value %d", $status >> 8);
        }
    }
}
