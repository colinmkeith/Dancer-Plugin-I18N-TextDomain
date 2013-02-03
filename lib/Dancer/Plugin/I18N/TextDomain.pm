package Dancer::Plugin::I18N::TextDomain;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use Dancer ':syntax';
use Dancer::Plugin;
use POSIX qw(locale_h);
use Locale::Messages;
use Locale::TextDomain qw();

use Dancer::Exception qw(:all);
register_exception('CatalogDirectoryNotFound',
                    message_pattern => 'catalog directory %s not found');
register_exception('CatalogFileNotFound',
                    message_pattern => 'catalog file %s not found');

my $settings = plugin_setting;

if($settings->{language} || $settings->{deflanguage}) {
  set_i18n_language($settings->{language} || $settings->{deflanguage});
}

$settings->{domain}
 && set_i18n_domain($settings->{domain}, $settings->{domain_dir});

register 'set_i18n_language' => \&set_i18n_language;
register 'set_i18n_domain' => \&set_i18n_domain;
my @gettextMethods;
# Don't mean to mess with another package's data, but otherwise all the
# __() methods are forced into my package when I call import()
while(my $fn = +shift(@Locale::TextDomain::EXPORT)) {
  substr($fn, 0, 1) eq '$' && next;
  substr($fn, 0, 1) eq '%' && next;
  register $fn => sub { tdcore($fn, @_); };
  push(@gettextMethods, $fn);
}

# {{{ hook before_template
hook before_template => sub {
  my $tokens = shift;
  my $prefix = $settings->{prefix} || '';

  # Template Toolkit sees _ prefix as private vars
  $prefix || ($Template::Stash::PRIVATE = $Template::Stash::PRIVATE = undef);

  for my $fn (@gettextMethods) {
    $tokens->{$prefix . $fn} = sub { tdcore($fn, @_); };
  }
}; # }}}

# {{{ set_i18n_language([$lang])
sub set_i18n_language {
  $_[0] && ($settings->{language} = $_[0]);
  POSIX::setlocale(&POSIX::LC_MESSAGES, $ENV{LANG} = $settings->{language});
  Locale::Messages::nl_putenv("LANG=$ENV{LANG}");
} # }}}

# {{{ set_i18n_domain($domain, $domain_dir)
sub set_i18n_domain {
  $_[0] && ($settings->{domain}     = $_[0]);
  $_[1] && ($settings->{domain_dir} = $_[1]);

  my $app = $settings->{domain}    || return -1;
  $settings->{domain_dir}          || return -2;
  -d $settings->{domain_dir}       || return -3;
  my $lang = $settings->{language} || return -4;
  my $dir = "data/$lang/LC_MESSAGES";
  -d $dir || raise CatalogDirectoryNotFound => $dir;
  my $moFile = "$dir/$app.mo";
  -f $moFile || raise CatalogFileNotFound => $moFile;

  Locale::Messages::select_package('gettext_xs');
  Locale::gettext_xs::bindtextdomain($app, 'data');
  Locale::TextDomain->import($app, 'data');
} # }}}

# We need this function because Locale::TextDomain uses the package of the
# caller. During setup that is __PACKAGE__, but when called from the app, it
# is the app, e.g. xyz::app and we need to force it back to D:P:I18N:TextDomain
# {{{ tdcore()
sub tdcore {

  package Dancer::Plugin::I18N::TextDomain;
  my $which = +shift(@_);

  # L::TD requires arrays, not hashrefs for replacement vars,
  # but TT tries to be helpful and send a hashref - Yay!
  substr($which, -1) eq 'x'
   && ref($_[$#_]) eq 'HASH'
   && push(@_, %{pop(@_)});

  {
    no strict 'refs';
    return &{"Locale::TextDomain::$which"};
  }
} # }}}

register_plugin;

1;

__END__

=head1 NAME

Dancer::Plugin::I18N::TextDomain - Add Locale::TextDomain (.po files)

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS

Setup:

    use Dancer::Plugin::I18N::TextDomain;

    set_i18n_language('en_US');
    set_i18n_domain('myappname', 'data/i18n');

(See below for config.yml settings)

Usage:

    __x('Hello {world}', world=>$name);

or in your template;

    [% __x('Hello {world}', world=>$name); %]

=head1 DESCRIPTION

A plugin for L<Dancer>-powered apps to provide access to gettext message
domains. This allows the application to support multiple languages.

This plugin provides the following gettext functions, which can also be
accessed via the template, for example in Template Toolkit, C<[% __x(...) %]>

=over 4

=item __()

=item __x()

=item __n()

=item __nx()

=item __p()

=item __pn()

=item __pnx()

=back

The following methods are also provided;

=over 4

=item set_i18n_language($language)

Sets the language to use. The source of the language is left as an exercise for
the reader. Set it through your config.yml for a fixed value, as a result of an
configuration option within the application's UI settings or as the result of a
User Agent indicating support for a language.

For the latter case we suggest looking at L<Locale::Util> and L<I18N-LangTags>

Setting this will call the L<POSIX> function setlocal() to set this language.
Note that we only set LC_MESSAGES so as to avoid interfering with LC_MONEY,
etc.

WARNING: You can get a list of supported languages on your system using
C<locale -a>. If your selected language is not listed there then it will
be ignored.

=item set_i18n_domain($appName, $languageDir)

Use this (or the config.yml setting) to define where gettext should look for
your catalogue files. The location of the actual message catalogue then becomes;

$languageDir/$language/LC_MESSAGES/$appName.mo

B<WARNING>: You can only use one directory to hold the catalogue file and more
importantly once set you can't change it (or at least it is really hard to do
so) and more importantly the directory has to exist before the first gettext
method is called. If not then this folder will be set to C<undef>, but the
underlying library won't let you reset the path on a subsequent call.

=back


=head1 config.yml configuration

The plugin can be configured with defaults through your config file:

  plugins:
    "I18N::TextDomain":
        # looks for gettext message domain in file data/en_US.UTF8/LC_MESSAGES/myappname.mo
        language: "en_US.UTF8"
        domain:   "myappname"
        domain_dir: "data"
        prefix: "gt"

=head1 SEE ALSO

gettext(3i), gettext(1), msgfmt(1) or L<Locale::Msgfmt>, L<Locale::Util>, L<I18N-LangTags>

=head1 AUTHOR

Colin Keith, C<< <colinmkeith at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/colinmkeith/Dancer-Plugin-I18N-TextDomain.git>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::I18N::TextDomain


You can also look for information at:

=over 4

L<http://github.com/colinmkeith/Dancer-Plugin-I18N-TextDomain.git>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Colin Keith.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
