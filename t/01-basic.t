#!/usr/bin/perl
use strict;
use warnings;

use Test::More import => ['!pass'];

# use t::lib::TestApp;

use Dancer ':syntax';
use Dancer::Test;
use File::Which;
use Dancer::Plugin::I18N::TextDomain;

eval { require Locale::TextDomain };
if($@) {
  plan skip_all => 'Locale::TextDomain required to run these tests';
}

my $msgfmtCmd = File::Which::which('msgfmt');

if(!$msgfmtCmd) {
  plan skip_all => 'msgfmt required to run these tests';
}
ok(1, 'Found msgfmt command');

# setting plugins => {I18N => {TextDomain => {
#  deflanguage => 'en_US.UTF-8',
# }}};

my $testCount = 1;

my $atLeastOneLang;
for my $lang (qw(en_US.UTF-8 fr_fr.UTF-8)) {
  if(Dancer::Plugin::I18N::TextDomain::set_i18n_language($lang)) {
    $testCount += 2;
    $atLeastOneLang = 1;
    ok(1, "Set language to $lang");
    ok(Dancer::Plugin::I18N::TextDomain::set_i18n_domain('dancer_plugin_i18n_textdomain_test',
       't/lang'), "Set test dir");
  }
}

$atLeastOneLang || fail('Failed to test any languages');
done_testing($testCount);
