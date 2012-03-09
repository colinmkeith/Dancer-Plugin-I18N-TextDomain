use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::I18N::TextDomain',
    AUTHOR              => 'Colin Keith <ckeith@cpan.org>',
    VERSION_FROM        => 'lib/Dancer/Plugin/I18N/TextDomain.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/I18N/TextDomain.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'POSIX'      => 0,
        'Locale::TextDomain' => 1.20,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-I18N-TextDomain-*' },
);
