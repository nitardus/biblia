#!perl
use v5.14;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Biblia' ) || print "Bail out!\n";
}

diag( "Testing Biblia $Biblia::VERSION, Perl $], $^X" );
