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
    { # RENPU_TOITSU (4 fu)
        'te' => "m2m2m2m2m3m4p1p2p3z1z1s2s4 s3",
        'jikaze' => '2',
        'bakaze' => '2',
        'dora' => 'm8',

        'yaku' => [
            "TSUMO",
        ],
        'fu' => 20 + 4 + 2 + 2, # 28
        'han' => 1,

        'score' => {
            'oya' => 500,
            'ko'  => 300,
        },

        'rule' => {
            'renpu_toitsu4' => 1,
        },
    },
    { # RENPU_TOITSU (4 fu)
        'te' => "m2m2m2m2m3m4p1p2p3z5z5s2s4 s3",
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
            'no_triple_yakuman' => 0,
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
            'no_triple_yakuman' => 1,
        },
    },
    { #DOUBLE-YAKUMAN nasi2
        'te'     => "p2p2p2p3p4p4p4p7p7p7p5p5p5 p1",
        'jikaze' => 4,
        'bakaze' => 2,
        'dora'   => 'm2',

        'yaku'   => [
            "CHIN-ITSU",
            "3-ANKO",
            "TSUMO",
        ],
        'fu'     => 20 + 4 + 4 + 4 + 2, # 34
        'han'    => 9, # bai-man

        'score'  => {
            'oya' => 8000,
            'ko'  => 4000,
        },

        'rule'   => {
            'no_double_yakuman' => 1,
            'no_triple_yakuman' => 1,
        },
    },
    { #DOUBLE-YAKUMAN nasi3 四暗刻単騎待ちがダブル役満でも、ルール上ダブル役満なしなら、なし
        'te'     => "p2p2p2p3p4p4p4p7p7p7p5p5p5 p3",
        'jikaze' => 4,
        'bakaze' => 2,
        'dora'   => 'm2',

        'yaku'   => [
            "4-ANKO(TANKI)",
        ],
        'fu'     => 20 + 4 + 4 + 4 + 4 + 2 + 2, # 40
        'han'    => 100, # yakuman

        'score'  => {
            'oya' => 16000,
            'ko'  =>  8000,
        },

        'rule'   => {
            'no_double_yakuman'     => 1,
            'no_triple_yakuman'     => 1,
            'no_4anko_tanki_double' => 0,
        },
    },

    { #TRIPLE-YAKUMAN ari
        'te'     => "z1z1z2z2z2z5z5z6z6z6z7z7z7 z5",
        'jikaze' => 4,
        'bakaze' => 2,
        'dora'   => 'p2',

        'yaku'   => [
            "TSUU-II-SOU",
            "DAI-SAN-GEN",
            "4-ANKO",
        ],
        'fu'     => 20 + 8 + 8 + 8 + 8 + 2, # 54
        'han'    => 300,

        'score'  => {
            'oya' => 48000,
            'ko'  => 24000,
        },

        'rule'   => {
            'no_double_yakuman' => 0,
            'no_triple_yakuman' => 0,
        },
    },
    { #TRIPLE-YAKUMAN nasi
        'te'     => "z1z1z2z2z2z5z5z6z6z6z7z7z7 z5",
        'jikaze' => 4,
        'bakaze' => 2,
        'dora'   => 'p2',

        'yaku'   => [
            "TSUU-II-SOU",
            "DAI-SAN-GEN",
            "4-ANKO",
        ],
        'fu'     => 20 + 8 + 8 + 8 + 8 + 2, # 54
        'han'    => 200, # double-yakuman

        'score'  => {
            'oya' => 32000,
            'ko'  => 16000,
        },

        'rule'   => {
            'no_double_yakuman' => 0,
            'no_triple_yakuman' => 1,
        },
    },

    { #4ANKO TANKI (double)
        'te'     => "m2m2m2m5m5m5p8p8p8s7 p3p3p3p3 s7-",
        'jikaze' => 1,
        'bakaze' => 2,
        'dora'   => 's5',

        'yaku'   => [
            "4-ANKO(TANKI)",
        ],
        'fu'     => 20 + 4 + 4 + 4 + 16 + 10 + 2, # 60
        'han'    => 200, # double-yakuman

        'score'  => {
            'ron' => 96000,
        },

        'rule'   => {
            'no_4anko_tanki_double' => 0,
            'no_double_yakuman'     => 0,
            'no_triple_yakuman'     => 1,
        },
    },
    { #4ANKO TANKI (single)
        'te'     => "m2m2m2m5m5m5p8p8p8s7 p3p3p3p3 s7-",
        'jikaze' => 1,
        'bakaze' => 2,
        'dora'   => 's5',

        'yaku'   => [
            "4-ANKO(TANKI)",
        ],
        'fu'     => 20 + 4 + 4 + 4 + 16 + 10 + 2, # 60
        'han'    => 100, # yakuman

        'score'  => {
            'ron' => 48000,
        },

        'rule'   => {
            'no_4anko_tanki_double' => 1,
            'no_double_yakuman'     => 0,
            'no_triple_yakuman'     => 1,
        },
    },

    { #DAI-SUU-SHII (double)
        'te'     => "z1z1z1z3z3z3z4z4p2p2 z2z2z2- z4",
        'jikaze' => 4,
        'bakaze' => 1,
        'dora'   => 's5',

        'yaku'   => [
            "DAI-SUU-SHII",
        ],
        'fu'     => 20 + 8 + 8 + 8 + 4 + 2, # 50
        'han'    => 200, # double-yakuman

        'score'  => {
            'oya' => 32000,
            'ko'  => 16000,
        },

        'rule'   => {
            'no_daisuushii_double'  => 0,
            'no_double_yakuman'     => 0,
            'no_triple_yakuman'     => 1,
        },
    },
    { #DAI-SUU-SHII (single)
        'te'     => "z1z1z1z3z3z3z4z4p2p2 z2z2z2- z4",
        'jikaze' => 4,
        'bakaze' => 1,
        'dora'   => 's5',

        'yaku'   => [
            "DAI-SUU-SHII",
        ],
        'fu'     => 20 + 8 + 8 + 8 + 4 + 2, # 50
        'han'    => 100, # yakuman

        'score'  => {
            'oya' => 16000,
            'ko'  =>  8000,
        },

        'rule'   => {
            'no_daisuushii_double'  => 1,
            'no_double_yakuman'     => 0,
            'no_triple_yakuman'     => 1,
        },
    },

    { #4-KANTSU (double)
        'te'     => "p2 p3p3p3p3 p4p4p4p4- p5p5p5p5 p6p6p6p6- p2",
        'jikaze' => 2,
        'bakaze' => 2,
        'dora'   => 's5 m2 p9 z2 p9',

        'yaku'   => [
            "4-KANTSU",
        ],
        'fu'     => 20 + 16 + 8 + 16 + 8 + 2 + 2, # 72
        'han'    => 200, # double-yakuman

        'score'  => {
            'oya' => 32000,
            'ko'  => 16000,
        },

        'rule'   => {
            'no_4kantsu_double'     => 0,
            'no_double_yakuman'     => 0,
            'no_triple_yakuman'     => 1,
        },
    },
    { #4-KANTSU (single)
        'te'     => "p2 p3p3p3p3 p4p4p4p4- p5p5p5p5 p6p6p6p6- p2",
        'jikaze' => 2,
        'bakaze' => 2,
        'dora'   => 's5 m2 p9 z2 p9',

        'yaku'   => [
            "4-KANTSU",
        ],
        'fu'     => 20 + 16 + 8 + 16 + 8 + 2 + 2, # 72
        'han'    => 100, # yakuman

        'score'  => {
            'oya' => 16000,
            'ko'  =>  8000,
        },

        'rule'   => {
            'no_4kantsu_double'     => 1,
            'no_double_yakuman'     => 0,
            'no_triple_yakuman'     => 1,
        },
    },

    { # CHUUREN-POTO(9men-chan) (double)
        'te' => "m1m1m1m2m3m4m5m6m7m8m9m9m9 m5",
        'jikaze' => '2',
        'bakaze' => '1',
        'dora'   => 'p2',

        'yaku' => [
            "CHUUREN-POTO(9men-chan)",
        ],
        'fu' => 20 + 8 + 8 + 2 + 2, # 40
        'han' => 200,

        'score' => {
            'oya' => 32000,
            'ko'  => 16000,
        },

        'rule'   => {
            'no_chuurenpoto9_double' => 0,
            'no_double_yakuman'      => 0,
            'no_triple_yakuman'      => 1,
        },
    },
    { # CHUUREN-POTO(9men-chan) (single)
        'te' => "m1m1m1m2m3m4m5m6m7m8m9m9m9 m5",
        'jikaze' => '2',
        'bakaze' => '1',
        'dora'   => 'p2',

        'yaku' => [
            "CHUUREN-POTO(9men-chan)",
        ],
        'fu' => 20 + 8 + 8 + 2 + 2, # 40
        'han' => 100,

        'score' => {
            'oya' => 16000,
            'ko'  =>  8000,
        },

        'rule'   => {
            'no_chuurenpoto9_double' => 1,
            'no_double_yakuman'      => 0,
            'no_triple_yakuman'      => 1,
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
        $msg .= sprintf "  %d fu => %d fu  ", $result->{fu}, $result->{st_fu};
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
            $result->{st_fu},
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
                $test->{fu}, $test->{st_fu}, $test->{han} );
            $mjc->log_( 0, sprintf "    %s", $expect_yaku_list );
        }
    }
    $mjc->log_( 0, "" );
}

close $logfile;

exit 0;
