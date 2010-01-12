use strict;
use warnings;
use Test::More;

use MG;

# デバッグログ

open my $logfile, '>:encoding(euc-jp)', "g.log";

my @tests = (
    { # 30 fu 1 han ron (ko)
        'fu'    => 30,
        'han'   => 1,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => {
            'ron' => 1000,
        },
    },
    { # 30 fu 1 han tsumo (ko)
        'fu'    => 30,
        'han'   => 1,
        'oya'   => 0,
        'tsumo' => 1,

        'score' => { # gomi
            'oya' =>  500,
            'ko'  =>  300,
        },
    },
    { # 40 fu 1 han ron (oya)
        'fu'    => 40,
        'han'   => 1,
        'oya'   => 1,
        'tsumo' => 0,

        'score' => { # 2sen
            'ron' => 2000,
        },
    },
    { # 40 fu 1 han tsumo (ko)
        'fu'    => 40,
        'han'   => 1,
        'oya'   => 0,
        'tsumo' => 1,

        'score' => { # 400 700
            'oya' => 700,
            'ko'  => 400,
        },
    },
    { # 20 fu 2 han tsumo (ko)
        'fu'    => 20,
        'han'   => 2,
        'oya'   => 0,
        'tsumo' => 1,

        'score' => { # na-shi
            'oya' => 700,
            'ko'  => 400,
        },
    },
    { # 25 fu 2 han ron (ko)
        'fu'    => 25,
        'han'   => 2,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => { # 1600
            'ron' => 1600,
        },
    },
    { # 30 fu 2 han ron (ko)
        'fu'    => 30,
        'han'   => 2,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => { # 2000
            'ron' => 2000,
        },
    },
    { # 30 fu 2 han ron (oya)
        'fu'    => 30,
        'han'   => 2,
        'oya'   => 1,
        'tsumo' => 0,

        'score' => { # nikku
            'ron' => 2900,
        },
    },
    { # 40 fu 2 han tsumo (ko)
        'fu'    => 40,
        'han'   => 2,
        'oya'   => 0,
        'tsumo' => 1,

        'score' => { # nana-to-san
            'oya' => 1300,
            'ko'  =>  700,
        },
    },
    { # 40 fu 2 han ron (oya)
        'fu'    => 40,
        'han'   => 2,
        'oya'   => 1,
        'tsumo' => 0,

        'score' => { # zanku
            'ron' => 3900,
        },
    },
    { # 50 fu 2 han ron (ko)
        'fu'    => 50,
        'han'   => 2,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => { # zanni
            'ron' => 3200,
        },
    },
    { # 20 fu 3 han tsumo (ko)
        'fu'    => 20,
        'han'   => 3,
        'oya'   => 0,
        'tsumo' => 1,

        'score' => { # nana-to-san
            'oya' => 1300,
            'ko'  =>  700,
        },
    },
    { # 30 fu 3 han ron (ko)
        'fu'    => 30,
        'han'   => 3,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => { # zanku
            'ron' => 3900,
        },
    },
    { # 30 fu 3 han tsumo (oya)
        'fu'    => 30,
        'han'   => 3,
        'oya'   => 1,
        'tsumo' => 1,

        'score' => { # 2000 all
            'all' => 2000,
        },
    },
    { # 40 fu 3 han tsumo (ko)
        'fu'    => 40,
        'han'   => 3,
        'oya'   => 0,
        'tsumo' => 1,

        'score' => { # ichi-san-nin-roku
            'oya' => 2600,
            'ko'  => 1300,
        },
    },
    { # 40 fu 3 han tsumo (oya)
        'fu'    => 40,
        'han'   => 3,
        'oya'   => 1,
        'tsumo' => 1,

        'score' => { # nin-roku all
            'all' => 2600,
        },
    },
    { # 50 fu 3 han ron (ko)
        'fu'    => 50,
        'han'   => 3,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => { # roku-yon
            'ron' => 6400,
        },
    },
    { # 50 fu 3 han tsumo (ko)
        'fu'    => 50,
        'han'   => 3,
        'oya'   => 0,
        'tsumo' => 1,

        'score' => { # 1600 3200
            'oya' => 3200,
            'ko'  => 1600,
        },
    },
    { # 50 fu 3 han tsumo (oya)
        'fu'    => 50,
        'han'   => 3,
        'oya'   => 1,
        'tsumo' => 1,

        'score' => { # 3200 all
            'all' => 3200,
        },
    },
    { # 60 fu 3 han ron (ko)
        'fu'    => 60,
        'han'   => 3,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => { # chicchii-
            'ron' => 7700,
        },
    },
    { # 70 fu 3 han ron (ko)
        'fu'    => 70,
        'han'   => 3,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => { # 8000
            'ron' => 8000,
        },
    },
    { # 20 fu 4 han tsumo (ko)
        'fu'    => 20,
        'han'   => 4,
        'oya'   => 0,
        'tsumo' => 1,

        'score' => { # ichi-san nin-roku
            'oya' => 2600,
            'ko'  => 1300,
        },
    },
    { # 25 fu 4 han ron (ko)
        'fu'    => 25,
        'han'   => 4,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => { # roku-yon
            'ron' => 6400,
        },
    },
    { # 30 fu 4 han ron (ko)
        'fu'    => 30,
        'han'   => 4,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => { # chicchii
            'ron' => 7700,
        },
    },
    { # 30 fu 4 han tsumo (ko)
        'fu'    => 30,
        'han'   => 4,
        'oya'   => 0,
        'tsumo' => 1,

        'score' => { # 2sen zanku
            'oya' => 3900,
            'ko'  => 2000,
        },
    },
    { # 30 fu 4 han ron (oya)
        'fu'    => 30,
        'han'   => 4,
        'oya'   => 1,
        'tsumo' => 0,

        'score' => { # pin-pin-roku
            'ron' => 11600,
        },
    },
    { # 30 fu 4 han tsumo (oya)
        'fu'    => 30,
        'han'   => 4,
        'oya'   => 1,
        'tsumo' => 1,

        'score' => { # zanku all
            'all' => 3900,
        },
    },
    { # 40 fu 4 han ron (ko)
        'fu'    => 40,
        'han'   => 4,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => { # 8000 (man-gan)
            'ron' => 8000,
        },
    },
    { # 5 han ron (ko)
        'fu'    => 30,
        'han'   => 5,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => { # 8000 (man-gan)
            'ron' => 8000,
        },
    },
    { # 6 han ron (oya)
        'fu'    => 40,
        'han'   => 6,
        'oya'   => 1,
        'tsumo' => 0,

        'score' => { # 18000 (oya-ppane)
            'ron' => 18000,
        },
    },
    { # 8 han tsumo (ko)
        'fu'    => 40,
        'han'   => 8,
        'oya'   => 0,
        'tsumo' => 1,

        'score' => { # 4000 8000 (bai-man)
            'oya' => 8000,
            'ko'  => 4000,
        },
    },
    { # 11 han tsumo (oya)
        'fu'    => 40,
        'han'   => 11,
        'oya'   => 1,
        'tsumo' => 1,

        'score' => { # 12000 all (3bai-man)
            'all' => 12000,
        },
    },
    { # 13 han ron (ko)
        'fu'    => 40,
        'han'   => 13,
        'oya'   => 0,
        'tsumo' => 0,

        'score' => { # 32000 (kazoe-yaku-man)
            'ron' => 32000,
        },
    },
    { # yaku-man ron (oya)
        'fu'    => 40,
        'han'   => 100,
        'oya'   => 1,
        'tsumo' => 0,

        'score' => { # 48000 (oya yaku-man)
            'ron' => 48000,
        },
    },
    { # double-yaku-man tsumo (ko)
        'fu'    => 40,
        'han'   => 200,
        'oya'   => 0,
        'tsumo' => 1,

        'score' => { # 16000 32000
            'oya' => 32000,
            'ko'  => 16000,
        },
    },
    { # triple-yaku-man tsumo (oya)
        'fu'    => 40,
        'han'   => 300,
        'oya'   => 1,
        'tsumo' => 1,

        'score' => { # 48000 all
            'all' => 48000,
        },
    },
);

plan tests => @tests * 1;

MG::init( $logfile );

foreach my $test ( @tests ) {
    my $score = MG::calc_score(
        $test->{fu},
        $test->{han},
        $test->{oya},
        $test->{tsumo} );

    is_deeply( $score, $test->{score},
               sprintf "$test->{fu} fu $test->{han} han (%s) (%s)",
                       ( $test->{oya} ? 'oya' : 'ko' ),
                       ( $test->{tsumo} ? 'tsumo' : 'ron' ) );
}

exit 0;

