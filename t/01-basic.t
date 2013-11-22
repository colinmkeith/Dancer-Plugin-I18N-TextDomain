#!/usr/bin/perl
use strict;
use warnings;

use Test::More import => ['!pass'];

# use t::lib::TestApp;

use Dancer ':syntax';
use Dancer::Test;
use File::Which;
use File::Path;
use Dancer::Plugin::I18N::TextDomain;

eval { require Locale::TextDomain };
if($@) {
  plan skip_all => 'Locale::TextDomain required to run these tests';
}

my $testCount = 0;
my $atLeastOneLang;
my $langDir = 't/lang';

for my $lang (qw(en_US.UTF-8)) {
  File::Path::remove_tree($langDir . '/' . $lang, { verbose=>0});

  $testCount++;
  is(Dancer::Plugin::I18N::TextDomain::set_i18n_language($lang), $lang,
     "Set language to $lang");

  $testCount += 2;
  $atLeastOneLang = 1;

  # Alias for shorter code;
  *set_i18n_domain = \&Dancer::Plugin::I18N::TextDomain::set_i18n_domain;

  my $catalog = 'dancer_plugin_i18n_textdomain_test';

  is(set_i18n_domain(undef, undef), -1, 'Missing catalog error caught');

  is(set_i18n_domain($catalog, 'catalogdir'),
    -3, 'Invalid domain directory error caught');
}

$atLeastOneLang || fail('Failed to test any languages');
done_testing($testCount);
