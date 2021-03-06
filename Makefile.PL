use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Coverage;

WriteMakefile(
    NAME                => 'MG',
    AUTHOR              => 'Naoki IIMURA <amatubu@gmail.com>',
    VERSION_FROM        => 'lib/MG.pm',
    ( eval { ExtUtils::MakeMaker->VERSION(6.3002) } ? (
        LICENSE         => 'perl',
        ) : ()
    ),
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (
        META_MERGE      => {
            resources   => {
                repository => 'http://github.com/amatubu/mjscore',
            },
        }
        ) : ()
    ),
    ABSTRACT            => 'Marjang calculator written in Perl',
    PL_FILES            => {},
    PREREQ_PM => {
    },
    EXE_FILES           => [],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MG-*' },
);

