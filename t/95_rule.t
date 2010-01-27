use strict;
use warnings;
use Test::More;

use utf8;
use encoding "utf-8", STDOUT=>"euc-jp", STDERR=>"euc-jp";
use Encode;

use MG;

# デバッグログ

open my $logfile, '>>:encoding(euc-jp)', "g.log";

my @tests = (

    { # RENPU_TOITSU (2 fu)
        'te' => "m2m2m2m2m3m4p1p2p3z2z2s2s4 s3",
        'jikaze' => '2',
        'bakaze' => '2',
        'dora' => 'm8',

        'yaku' => [
            "TSUMO",
        ],
        'fu' => 20 + 2 + 4 + 2 + 2, # 30
        'han' => 1,

        'score' => {
            'oya' => 500,
            'ko'  => 300,
        },

        'rule' => {
            'renpu_toitsu4' => 0,
        },
    },
    { # RENPU_TOITSU (4 fu)
        'te' => "m2m2m2m2m3m4p1p2p3z2z2s2s4 s3",
        'jikaze' => '2',
        'bakaze' => '2',
        'dora' => 'm8',

        'yaku' => [
            "TSUMO",
        ],
        'fu' => 20 + 4 + 4 + 2 + 2, # 32
        'han' => 1,

        'score' => {
            'oya' => 700,
            'ko'  => 400,
        },

        'rule' => {
            'renpu_toitsu4' => 1,
        },
    },
    { # RENPU_TOITSU (4 fu)
        'te' => "m2m2m2m2m3m4p1p2p3z2z2s2s4 s3",
        'jikaze' => '2',
        'bakaze' => '1',
        'dora' => 'm8',

        'yaku' => [
            "TSUMO",
        ],
        'fu' => 20 + 2 + 4 + 2 + 2, # 30
        'han' => 1,

        'score' => {
            'oya' => 500,
            'ko'  => 300,
        },

        'rule' => {
            'renpu_toitsu4' => 1,
        },
    },

    { #KUITAN nasi
        'te'     => "m3m4m5p3p4m7m7 s3s4s5- s8s8s8- p5",
        'jikaze' => 3,
        'bakaze' => 1,
        'dora'   => 'p2',

        'yaku'   => [
            "3-SHOKU",
        ],
        'fu'     => 20 + 2 + 2, # 24
        'han'    => 1,

        'score'  => {
            'oya' => 500,
            'ko'  => 300,
        },

        'rule'   => {
            'kuitan' => 0,
        },
    },
    { #KUITAN ari
        'te'     => "m3m4m5p3p4m7m7 s3s4s5- s8s8s8- p5",
        'jikaze' => 3,
        'bakaze' => 1,
        'dora'   => 'p2',

        'yaku'   => [
            "3-SHOKU",
            "TAN-YAO",
        ],
        'fu'     => 20 + 2 + 2, # 24
        'han'    => 2,

        'score'  => {
            'oya' => 1000,
            'ko'  =>  500,
        },

        'rule'   => {
            'kuitan' => 1,
        },
    },

    { #DOUBLE-YAKUMAN ari
        'te'     => "z1z1z2z2z2z5z5 z6z6z6- z7z7z7- z5",
        'jikaze' => 4,
        'bakaze' => 2,
        'dora'   => 'p2',

        'yaku'   => [
            "TSUU-II-SOU",
            "DAI-SAN-GEN",
        ],
        'fu'     => 20 + 8 + 8 + 4 + 4 + 2, # 46
        'han'    => 200,

        'score'  => {
            'oya' => 32000,
            'ko'  => 16000,
        },

        'rule'   => {
            'no_double_yakuman' => 0,
        },
    },

    { #DOUBLE-YAKUMAN nasi
        'te'     => "z1z1z2z2z2z5z5 z6z6z6- z7z7z7- z5",
        'jikaze' => 4,
        'bakaze' => 2,
        'dora'   => 'p2',

        'yaku'   => [
            "TSUU-II-SOU",
            "DAI-SAN-GEN",
        ],
        'fu'     => 20 + 8 + 8 + 4 + 4 + 2, # 46
        'han'    => 100, # yakuman

        'score'  => {
            'oya' => 16000,
            'ko'  =>  8000,
        },

        'rule'   => {
            'no_double_yakuman' => 1,
        },
    },

);

plan tests => @tests * 5;


foreach my $test ( @tests ) {
    my $mjc = MG->new( 'logfile' => $logfile,
                       'rule'    => $test->{rule} );

    my $result = $mjc->check( $test );

    ok( defined( $result ), "RESULT $test->{te}" );

    if ( defined( $result ) ) {
        my $pass = 1;
        my $msg;

        $mjc->log_( 2, "=== RESULT ===" );
        $mjc->log_( 0, sprintf "AGARI-KEI  %s", $result->{tehai} );

        is( $result->{fu}, $test->{fu}, "FU $test->{te}" );
        is( $result->{han}, $test->{han}, "HAN $test->{te}" );

        if ( ( $result->{fu} == $test->{fu} ) && ( $result->{han} == $test->{han} ) ) {
            $msg = "OK";
        } else {
            $msg = "NG";
            $pass = 0;
        }
        $msg .= sprintf "  %d fu => %d fu  ", $result->{fu}, MG::st_fu( $result->{fu} );
        if ( $result->{han} >= 200 ) {
            $msg .= "Double-Yakuman($result->{han})";
        } elsif ( $result->{han} >= 100 ) {
            $msg .= "Yakuman($result->{han})";
        } else {
            $msg .= sprintf "%d han", $result->{han};
        }
        $mjc->log_( 0, $msg );

        my $yaku_list = join( ' ', sort @{$result->{yaku}} );
        my $expect_yaku_list = join( ' ', sort @{$test->{yaku}} );

        is( $yaku_list, $expect_yaku_list, "YAKU $test->{te}" );

        if ( $yaku_list eq $expect_yaku_list ) {
            $msg = "OK";
        } else {
            $msg = "NG";
            $pass = 0;
        }
        $msg .= sprintf "  %s", $yaku_list;
        $mjc->log_( 0, $msg );

        my $score = $mjc->calc_score(
            $result->{fu},
            $result->{han},
            ( $test->{jikaze} == 1 ), # oya
            $test->{tsumo} );

        if ( $test->{score} ) {
            foreach my $p ( keys %{$test->{score}} ) {
                $mjc->log_( 0, sprintf "  $p $test->{score}->{$p}" );
            }
            is_deeply( $score, $test->{score},
                       sprintf "$result->{fu} fu $result->{han} han (%s) (%s)",
                               ( $test->{jikaze} == 1 ? 'oya' : 'ko' ),
                               ( $test->{tsumo} ? 'tsumo' : 'ron' ) );
        }

        if ( !$pass ) {
            $mjc->log_( 0, "=== EXPECT ===" );
            $mjc->log_( 0, sprintf "    %d fu => %d fu  %d han",
                $test->{fu}, MG::st_fu( $test->{fu} ), $test->{han} );
            $mjc->log_( 0, sprintf "    %s", $expect_yaku_list );
        }
    }
    $mjc->log_( 0, "" );
}

close $logfile;

exit 0;
