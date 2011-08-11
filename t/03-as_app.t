#!/usr/bin/perl
use strict;
use warnings;

use Test::More import => ['!pass'];

use t::lib::TestApp;
use Dancer ':syntax';
use Dancer::Test;

my $testCount = 1;

ok('loaded test app');

done_testing($testCount);
