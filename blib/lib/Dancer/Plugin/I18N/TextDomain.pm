package Dancer::Plugin::I18N::TextDomain;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use Dancer ':syntax';
use Dancer::Plugin;
use POSIX;

my $settings = plugin_setting;

if($settings->{language} || $settings->{deflanguage}) {
  set_i18n_language($settings->{language} || $settings->{deflanguage});
}

$settings->{domain}
 && set_i18n_domain($settings->{domain}, $settings->{domain_dir});

register 'set_i18n_language' => \&set_i18n_language;
register 'set_i18n_domain'   => \&set_i18n_domain;

register '__'    => sub { tdcore('__',    @_); };
register '__x'   => sub { tdcore('__x',   @_); };
register '__n'   => sub { tdcore('__n',   @_); };
register '__nx'  => sub { tdcore('__nx',  @_); };
register '__p'   => sub { tdcore('__p',   @_); };
register '__pn'  => sub { tdcore('__pn',  @_); };
register '__pnx' => sub { tdcore('__pnx', @_); };

before_template(
  sub {
    my $tokens = shift;
    my $prefix = $settings->{prefix} || '';

    # Default fn names are prefixed with __,
    # which Template Toolkit sees as private vars
    if(!$prefix) {

      # dup'd to stop warning about unused variable
      $Template::Stash::PRIVATE = $Template::Stash::PRIVATE = undef;
    }

    $tokens->{$prefix . '__'}    = sub { tdcore('__',    @_); };
    $tokens->{$prefix . '__x'}   = sub { tdcore('__x',   @_); };
    $tokens->{$prefix . '__n'}   = sub { tdcore('__n',   @_); };
    $tokens->{$prefix . '__nx'}  = sub { tdcore('__nx',  @_); };
    $tokens->{$prefix . '__p'}   = sub { tdcore('__p',   @_); };
    $tokens->{$prefix . '__pn'}  = sub { tdcore('__pn',  @_); };
    $tokens->{$prefix . '__pnx'} = sub { tdcore('__pnx', @_); };
  });

sub set_i18n_language {
  $_[0] && ($settings->{language} = $_[0]);
  POSIX::setlocale(&POSIX::LC_MESSAGES, $settings->{language});
}

sub set_i18n_domain {
  $_[0] && ($settings->{domain}     = $_[0]);
  $_[1] && ($settings->{domain_dir} = $_[1]);
  $settings->{domain}        || return 0;
  $settings->{domain_dir}    || return 0;
  -d $settings->{domain_dir} || return 0;

  require Locale::TextDomain;

  # Grrr. Needed to stop warnings about redefined subs and prototype mismatches
  @Locale::TextDomain::EXPORT = ();
  Locale::TextDomain->import($settings->{domain}, $settings->{domain_dir});
}

# We need this function because Locale::TextDomain uses the package of the
# caller. During setup that is __PACKAGE__, but when called from the app, it
# is the app, e.g. xyz::app and we need to force it back to D:P:I18N:TextDomain
sub tdcore {

  package Dancer::Plugin::I18N::TextDomain;
  my $which = +shift(@_);

  # L::TD requires arrays, not hashrefs for replacement vars,
  # but TT tries to be helpful and send a hashref - Yay!
  substr($which, -1) eq 'x'
   && ref($_[$#_]) eq 'HASH'
   && push(@_, %{pop(@_)});

  my $sub = {__ => \&Locale::TextDomain::__,
    __x   => \&Locale::TextDomain::__x,
    __n   => \&Locale::TextDomain::__n,
    __nx  => \&Locale::TextDomain::__nx,
    __p   => \&Locale::TextDomain::__p,
    __pn  => \&Locale::TextDomain::__pn,
    __pnx => \&Locale::TextDomain::__pnx,
   }->{$which};

   return &{$sub};
}

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

=head1 config.yml configuration

The plugin can be configured with defaults through your config file:

  plugins:
    "I18N::TextDomain":
        # looks for gettext message domain in file data/en_US.UTF8/LC_MESSAGES/myappname.mo
        language: "en_US.UTF8"
        domain:   "myappname"
        domain_dir: "data"
        prefix: "gt"

=head1 Message Catalog (.mo) file

The message catalog .mo file name is whatever name you use for the value of the
"domain" setting in config.yml. E.g. "myappname" with ".mo" appended. The
folder location is handled as follows:

C<domain_dir>/C<language>/LC_MESSAGES/C<domain>.mo


For example using the example

lang/en_US.UTF8/LC_MESSAGES/testapp.mo

=head1 SEE ALSO

gettext(3i), gettext(1), msgfmt(1)

=head1 AUTHOR

Colin Keith, C<< <colinmkeith at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dancer-plugin-i18n-textdomain at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-I18N-TextDomain>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::I18N::TextDomain


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-I18N-TextDomain>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-I18N-TextDomain>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-I18N-TextDomain>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-I18N-TextDomain/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Colin Keith.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
