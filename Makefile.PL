use strict;use warnings;use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Coverage;

WriteMakefile(    NAME                => 'MG',    AUTHOR              => 'Naoki IIMURA <amatubu@gmail.com>',    VERSION_FROM        => 'lib/MG.pm',    ABSTRACT            => 'Marjang calculator written in Perl',    PL_FILES            => {},    PREREQ_PM => {    },    EXE_FILES           => [],    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },    clean               => { FILES => 'MG-*' },);
