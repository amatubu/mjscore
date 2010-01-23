use strict;
use warnings;
use Test::More;

use utf8;
use encoding "utf-8", STDOUT=>"cp932", STDERR=>"cp932";
use Encode;

use MG;

# デバッグログ

open my $logfile, '>>:encoding(euc-jp)', "g.log";

my @tests = (
    { # 牌の数が多い
        'te'     => 'm1m2m3p1p1p7p8p8s7s8s9z4z4z4p1',
        'agari'  => 's9',
        'jikaze' => 2,
        'bakaze' => 1,

        'error'  => 1,
    },
    { # 牌の数が少ない
        'te'     => 'm1m2m3p1p1p7p8p8s7s8s9z4z4',
        'agari'  => 's9',
        'jikaze' => 2,
        'bakaze' => 1,

        'error'  => 1,
    },
    { # 牌の数が少ない
        'te'     => 'm1m2m3p1p1p8p8p8p8s7s8s9z4z4',
        'naki'   => 'p8p8p8p8',
        'agari'  => 's9',
        'jikaze' => 2,
        'bakaze' => 1,

        'error'  => 1,
    },

    { # 不正な文字が含まれている
        'te'     => 'm1m2m3p1p1p7p8p8s7s8s9z8z8',
        'agari'  => 's9',
        'jikaze' => 2,
        'bakaze' => 1,

        'error'  => 1,
    },
    { # 不正な文字が含まれている
        'te'     => 'm1m2m3p1p1p7p8p9s7s8s9s0s0p1',
        'agari'  => 's9',
        'jikaze' => 2,
        'bakaze' => 1,

        'error'  => 1,
    },
    { # 不正な文字が含まれている
        'te'     => 'm1m2m3p1p1p7p8p9s7s8s9n1n1p1',
        'agari'  => 's9',
        'jikaze' => 2,
        'bakaze' => 1,

        'error'  => 1,
    },

    { # 泣きの形がおかしい場合
        'te'     => 'm2m2m3p1p1p7p8p9s7s8s9z4z4z4',
        'naki'   => 'm2m2m3',
        'agari'  => 's9',
        'jikaze' => 1,
        'bakaze' => 2,

        'error'  => 1,
    },
    { # 泣きの形がおかしい場合
        'te'     => 'm1p2s3p1p1p7p8p9s7s8s9z4z4z4',
        'naki'   => 'm1p2s3',
        'agari'  => 's9',
        'jikaze' => 1,
        'bakaze' => 2,

        'error'  => 1,
    },
    { # 泣きの形がおかしい場合
        'te'     => 'p1p1p7p8p9s7s8z4z4z4 m2m2m3- s9',
        'jikaze' => 1,
        'bakaze' => 2,

        'error'  => 1,
    },
    { # 泣きに手牌に存在しない牌がある
        'te'     => 'm1m2m3p1p1p7p8p9s7s8s9z4z4z4',
        'naki'   => 'm2m3m4',
        'agari'  => 's9',
        'jikaze' => 1,
        'bakaze' => 2,

        'error'  => 1,
    },

    { # 同じ牌が5枚以上ある
        'te'     => 'm1m1m1m1m2m3m1m2m3m6m6m6m9m9',
        'agari'  => 'm2',
        'jikaze' => 2,
        'bakaze' => 1,

        'error'  => 1,
    },
    { # 同じ牌が5枚以上ある
        'te'     => 'm1m1m1m1m1m2m3m1m2m3m6m6m6m9m9',
        'naki'   => 'm1m1m1m1',
        'agari'  => 'm2',
        'jikaze' => 2,
        'bakaze' => 1,

        'error'  => 1,
    },
    { # 同じ牌が5枚以上ある（泣きを含めて）
        'te'     => 'm1m2m3m1m2m3m6m6m9m9 m1m1m1- m6',
        'jikaze' => 4,
        'bakaze' => 1,

        'error'  => 1,
    },

    { # あがり牌が未定義
        'te'     => 'm1m2m3p1p1p7p8p9s7s8s9z4z4z4',
        'jikaze' => 1,
        'bakaze' => 2,

        'error'  => 1,
    },
    { # あがり牌が手牌にない
        'te'     => 'm1m2m3p1p1p7p8p9s7s8s9z4z4z4',
        'agari'  => 'm9',
        'jikaze' => 1,
        'bakaze' => 2,

        'error'  => 1,
    },
    { # あがり牌が泣きの中にしかない
        'te'     => 'm1m2m3p1p1p7p8p9s7s8s9z4z4z4',
        'naki'   => 'z4z4z4',
        'agari'  => 'z4',
        'jikaze' => 3,
        'bakaze' => 2,

        'error'  => 1,
    },
    { # あがり牌が泣きの中にしかない
        'te'     => 'm1m2m3p1p1p7p8p9s7s8s9 z4z4z4 z4',
        'jikaze' => 3,
        'bakaze' => 2,

        'error'  => 1,
    },

    { # あがりの形になってない場合(チョンボ1)
        'te'     => 'm1m2m3p1p1p7p8p9s7s8s9z4z4z3',
        'menzen' => 1,
        'agari'  => 'z3',
        'jikaze' => 1,
        'bakaze' => 2,

        'error'  => 1,
    },
    { # あがりの形になってない場合(チョンボ2)
        'te'     => 'm1m2m3m1m2p7p8p9s7s8s9z4z4z4',
        'menzen' => 1,
        'agari'  => 'm1',
        'jikaze' => 1,
        'bakaze' => 2,

        'error'  => 1,
    },

    { # 役がない場合(チョンボ)
        'te'     => 'p1p2p3p1p2p3p1p3m1m1 m6m7m8- p2-',
        'menzen' => 1,
        'jikaze' => 1,
        'bakaze' => 1,

        'error'  => 1,
    },
);

plan tests => @tests * 1;

my $mjc = MG->new( 'logfile' => $logfile );

foreach my $test ( @tests ) {
    my $result = $mjc->check( $test );

    ok( !defined( $result ) && $test->{error}, "FU $test->{te}" );

    $mjc->log_( 0, "" );
}

close $logfile;

exit 0;
