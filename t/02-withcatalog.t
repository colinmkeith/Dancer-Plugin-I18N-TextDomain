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

my $msgfmtCmd = File::Which::which('msgfmt');

if(!$msgfmtCmd) {
  if(!use_ok('Locale::Msgfmt')) {
    plan skip_all => 'msgfmt required to run these tests';
  }
} else {
  ok(1, 'Found msgfmt command');
}

my $testCount = 2;

my $atLeastOneLang;
my $langDir = 't/lang';

BEGIN { use_ok('t::lib::createCatalog', 'createCatalog'); }


for my $lang (qw(en_US.UTF-8)) {
  File::Path::remove_tree($langDir . '/' . $lang, { verbose=>0});

  $testCount++;
  is(Dancer::Plugin::I18N::TextDomain::set_i18n_language($lang), $lang,
     "Set language to $lang");

  $testCount += 9;
  $atLeastOneLang = 1;

  # Alias for shorter code;
  *set_i18n_domain = \&Dancer::Plugin::I18N::TextDomain::set_i18n_domain;

  my $catalog = 'dancer_plugin_i18n_textdomain_test';
  my $catalogDir = $langDir . '/' . $lang . '/LC_MESSAGES/';
  my $catalogFile = $catalogDir . $catalog . '.mo';
  unlink($catalogFile);

  is(createCatalog($catalogFile, $msgfmtCmd), 0,
                   "Created catalog file ($catalogFile)");

  is(set_i18n_domain($catalog, $langDir), 0, 'Valid domain directory');

  my $ret;
  is(__('hello world'),
     $ret = "__('hello world') OK",
     "__() text match with a catalog ($ret)");

  is(__x('hello {name}', name => 'world'),
     $ret = "__x('hello {name }') returns 'hello world' OK",
     "__x() text match with a catalog ($ret)");



  is(__n('hello world singular', 'hello worlds plural', 1),
     $ret = "__n('hello world singular') OK",
     "__n() singular text match with a catalog ($ret)");

  is(__n('hello world singular', 'hello worlds plural', 2),
     $ret = "__n('hello worlds plural') OK",
     "__n() plural text match with a catalog ($ret)");



  is(__nx('hello {name} singular', 'hello {name} plural', 1, name => 'world'),
     $ret = "__n('hello {name } singular') == hello world OK",
     "__nx() singular text match with a catalog ($ret)");

  is(__nx('hello {name} singular', 'hello {name} plural', 2, name => 'world'),
     $ret = "__n('hello {name } plural') == hello worlds OK",
     "__nx() plural text match with a catalog ($ret)");



  is(__('a msgid'), 'a msgid',
     '__() non-match returned passed msgid with a catalog');

  File::Path::remove_tree($langDir . '/' . $lang, { verbose=>0});
}

$atLeastOneLang || fail('Failed to test any languages');
done_testing($testCount);
