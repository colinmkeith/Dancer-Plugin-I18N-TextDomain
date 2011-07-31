#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::I18N::TextDomain' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Plugin::I18N::TextDomain $Dancer::Plugin::I18N::TextDomain::VERSION, Perl $], $^X" );
