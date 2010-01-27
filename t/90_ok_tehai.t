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

    { # DOUBLE-NAN TSUMO
        'te' => "m1m2m3m2m3m4p1p2p3z2z2z2s2s2",
        'reach' => 1,
        'ippatsu' => 1,
        'agari' => 'm2',
        'menzen' => 1,
        'tsumo' => 1,
        'jikaze' => '2',
        'bakaze' => '2',
        'dora' => 'm3 m3',

        'yaku' => [
            "DOUBLE-南",
            "TSUMO",
            "REACH",
            "IPPATSU",
            "DORAx4",
        ],
        'fu' => 32,
        'han' => 9, # Bai-man

        'score' => {
            'oya' => 8000,
            'ko'  => 4000,
        },
    },
    { # PINFU
        'te' => "m1m2m3m2m3m4p1p2p3z4z4s3s4s5",
        'agari' => 'm2',
        'menzen' => 1,
        'jikaze' => "1", # TON
        'bakaze' => "2", # NAN

        'yaku' => [
            "PINFU",
        ],
        'fu' => 30,
        'han' => 1,

        'score' => {
            'ron' => 1500, # oya
        },
    },
    { # CHIN-ITSU PINFU RYAN-PEI-KO
        'te' => "m1m1m2m2m3m3m4m4m5m5m6m6m7m7",
        'agari' => 'm7',
        'menzen' => 1,
        'tsumo' => 1,
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "TSUMO",
            "CHIN-ITSU",
            "PINFU",
            "RYAN-PEI-KO",
        ],
        'fu' => 20,
        'han' => 11, # 3-bai-man

        'score' => {
            'oya' => 12000,
            'ko'  =>  6000,
        },
    },
    { # CHIN-ITSU TAN-YAO 3-ANKO TOI-TOI-HOU
        'te' => "m2m2m2m3m3m3m4m4m4m5m5m5m6m6",
        'agari' => 'm2',
        'menzen' => 1,
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "CHIN-ITSU",
            "TAN-YAO",
            "3-ANKO",
            "TOI-TOI-HOU",
        ],
        'fu' => 44,
        'han' => 11, # 3-bai-man

        'score' => {
            'ron' => 24000,
        },
    },
    { # RYAN-PEI-KO
        'te' => "m1m1m2m2m3m3p1p1p2p2p3p3p4p4",
        'agari' => 'm2',
        'menzen' => 1,
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "RYAN-PEI-KO",
        ],
        'fu' => 32,
        'han' => 3,

        'score' => {
            'ron' => 5200,
        }
    },
    { # 1-TSUU
        'te' => "s1s2s3s4s5s6s7s8s9p1p1p1p2p2",
        'agari' => 's2',
        'menzen' => 1,
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "1-TSUU",
        ],
        'fu' => 40,
        'han' => 2,

        'score' => {
            'ron' => 2600,
        },
    },
    { # 1-TSUU
        'te' => "s1s2s3s4s5s6s7s8s9p1p1p1p2p2",
        'agari' => 's2',
        'menzen' => 1,
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "1-TSUU",
        ],
        'fu' => 40,
        'han' => 2,

        'score' => {
            'ron' => 2600,
        },
    },
    { # 1-TSUU
        'te' => "s1s2s3s4s5s6s7s8s9s5s6s7s8s8",
        'agari' => 's2',
        'naki' => 's7s8s9-',
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "1-TSUU",
            "CHIN-ITSU",
        ],
        'fu' => 20 + 2,
        'han' => 6,

        'score' => {
            'ron' => 12000,
        },
    },
    { # CHUUREN-POTO(9men-chan)
        'te' => "m1m1m1m2m3m4m5m6m7m8m9m9m9m1",
        'agari' => 'm1',
        'menzen' => 1,
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "CHUUREN-POTO(9men-chan)",
        ],
        'fu' => 20 + 8 + 10,
        'han' => 200,

        'score' => {
            'ron' => 64000,
        },
    },
    { # CHUUREN-POTO
        'te' => "m1m1m1m2m3m4m5m6m7m8m9m9m9m1",
        'agari' => 'm2',
        'tsumo' => 1,
        'menzen' => 1,
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "CHUUREN-POTO",
        ],
        'fu' => 20 + 8 + 2 + 2,
        'han' => 100,

        'score' => {
            'oya' => 16000,
            'ko'  =>  8000,
        },
    },
    { # 3-ANKO
        'te' => "p1p2p3p1p2p3p1p2p3m1m2m3m8m8",
        'agari' => 'm1',
        'menzen' => 1,
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "3-ANKO",
        ],
        'fu' => 46,
        'han' => 2,

        'score' => {
            'ron' => 3200,
        },
    },
    { # TSUU-II-SOU (CHII-TOITSU)
        'te' => "z1z1z2z2z3z3z4z4z5z5z6z6z7z7",
        'agari' => 'z1',
        'menzen' => 1,
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "TSUU-II-SOU",
        ],
        'fu' => 25,
        'han' => 100,

        'score' => {
            'ron' => 32000,
        },
    },
    { # CHII-TOITSU
        'te' => "m1m1m2m2p3p3p4p4s5s5s6s6m7m7",
        'agari' => 'm1',
        'menzen' => 1,
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "CHII-TOITSU",
        ],
        'fu' => 25,
        'han' => 2,

        'score' => {
            'ron' => 1600,
        },
    },
    { # CHIN-ITSU(5)
        'te' => "m1m1m2m2m3m3m4m4m5m5m6m6m7m7",
        'naki' => "m1m2m3- m5m6m7-",
        'agari' => 'm1',
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "CHIN-ITSU",
        ],
        'fu' => 30,
        'han' => 5,

        'score' => {
            'ron' => 8000,
        },
    },
    { # TSUU-II-SOU DAI-SUU-SHII
        'te' => "z1z1z1z2z2z2z3z3z3z4z4z4z4z5z5",
        'naki' => "z1z1z1- z4z4z4z4",
        'agari' => 'z5',
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "TSUU-II-SOU",
            "DAI-SUU-SHII",
        ],
        'fu' => 76,
        'han' => 300,

        'score' => {
            'ron' => 96000,
        },
    },
    { # SHOU-SUU-SHII
        'te' => "z1z1z2z2z2z3z3z3z4z4z4z4m2m3m4",
        'naki' => "z2z2z2- z4z4z4z4",
        'agari' => 'm3',
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "SHOU-SUU-SHII",
        ],
        'fu' => 68,
        'han' => 100,

        'score' => {
            'ron' => 32000,
        },
    },
    { # KOKUSHI-MUSOU(13men-chan)
        'te' => "z1z2z3z4z5z6z7m1m9p1p9s1s9z1",
        'menzen' => 1,
        'agari' => 'z1',
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "KOKUSHI-MUSOU(13men-chan)",
        ],
        'fu' => 0,
        'han' => 200,

        'score' => {
            ron => 64000,
        },
    }, 
    { # KOKUSHI-MUSOU
        'te' => "z1z2z3z4z5z6z7m1m9p1p9s1s9z1",
        'menzen' => 1,
        'tsumo' => 1,
        'agari' => 's9',
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "KOKUSHI-MUSOU",
        ],
        'fu' => 0,
        'han' => 100,

        'score' => {
            'oya' => 16000,
            'ko'  =>  8000,
        },
    }, 
    { # HATSU
        'te' => "z7z7p1p2p3z6z6z6p8p8p8p8m9m9m9",
        'naki' => "p8p8p8p8- m9m9m9-",
        'menzen' => 0,
        'tsumo' => 1,
        'agari' => 'p3',
        'jikaze' => '2',
        'bakaze' => '1',

        'yaku' => [
            "発",
        ],
        'fu' => 46,
        'han' => 1,

        'score' => {
            'oya' => 800,
            'ko'  => 400,
        },
    },
    { # TSUMO JUN-CHAN II-PEI-KO
        'te' => "p1p2p3p1p2p3p1p3m1m1m7m8m9p2",
        'menzen' => 1,
        'tsumo' => 1,
        'agari' => 'p2',
        'jikaze' => '1', # oya
        'bakaze' => '1',

        'yaku' => [
            "TSUMO",
            "JUN-CHAN",
            "II-PEI-KO",
        ],
        'fu' => 20 + 2 + 2, # 24
        'han' => 5,

        'score' => {
            'all' => 4000,
        },
    },
    { # 3-ANKO
        'te' => "p1p2p3p1p2p3p1p3m1m1m7m8m9p2",
        'naki' => 'm7m8m9-',
        'menzen' => 1,
        'tsumo' => 1,
        'agari' => 'p2',
        'jikaze' => '1', # oya
        'bakaze' => '1',

        'yaku' => [
            "3-ANKO",
        ],
        'fu' => 20 + 8 + 4 + 4 + 2, # 38
        'han' => 2,

        'score' => {
            'all' => 1300,
        },
    },
    { # CHIN-ROU-TOU
        'te' => "p1p1p1p9p9p9m1m1m1s1s1s1s9s9",
        'naki' => 's1s1s1-',
        'agari' => 's9',
        'jikaze' => '1',
        'bakaze' => '1',

        'yaku' => [
            "CHIN-ROU-TOU",
        ],
        'fu' => 20 + 8 + 8 + 8 + 4 + 2,
        'han' => 100,

        'score' => {
            'ron' => 48000,
        },
    },
    { # DAI-SAN-GEN
        'te' => "s2s2m4m5m6z5z5z5z6z6z6z7z7z7",
        'naki' => 'z7z7z7-',
        'agari' => 'm6',
        'jikaze' => '1', # oya
        'bakaze' => '1',

        'yaku' => [
            'DAI-SAN-GEN',
        ],
        'fu' => 20 + 8 + 8 + 4,
        'han' => 100,

        'score' => {
            'ron' => 48000,
        },
    },
    { # 中
        'te' => "p2p3p4z1z1z7z7z7m1m1m1m1p9p9p9p9",
        'naki' => 'm1m1m1m1 p9p9p9p9', # AN-KAN
        'menzen' => 1,
        'agari' => 'z7',
        'jikaze' => '1', # oya
        'bakaze' => '1',

        'yaku' => [
            "中",
        ],
        'fu' => 20 + 2 + 4 + 32 + 32 + 10, # 100
        'han' => 1,

        'score' => {
            'ron' => 4800,
        },
    },
    { # TAN-YAO SAN-SHOKU II-PEIKO
        'te' => "m2m2m3m4m4m5m5s2s3s4p2p3p4m3",
        'agari' => 'm3',
        'menzen' => 1,
        'jikaze' => '4',
        'bakaze' => '1',

        'yaku' => [
            "TAN-YAO",
            "3-SHOKU",
            "II-PEI-KO",
        ],
        'fu' => 20 + 2 + 10, # 32
        'han' => 4,

        'score' => {
            'ron' => 8000,
        },
    },
    { # TAN-YAO 3-SHOKU
         'te' => "s2s3s4p2p3p4m2m3m4m8m8m8p5p5",
         'agari' => 'm2',
         'menzen' => 1,
         'jikaze' => '3',
         'bakaze' => '1',

        'yaku' => [
            "TAN-YAO",
            "3-SHOKU",
        ],
        'fu' => 20 + 4 + 10, # 34
        'han' => 3,

        'score' => {
            'ron' => 5200,
        },
    },
    { # 4-ANKO TANKI
         'te' => "m2m2m2m4m4m4m8m8m8s5s5s5p7p7",
         'agari' => 'p7',
         'menzen' => 1,
         'jikaze' => 2,
         'bakaze' => 2,

        'yaku' => [
            "4-ANKO(TANKI)",
        ],
        'fu' => 20 + 16 + 2 + 10,
        'han' => 200,

        'score' => {
            'ron' => 64000,
        },
    },
    { # TSUMORI 4-ANKO
         'te' => "m2m2m2m4m4m4m8m8m8s5s5s5p7p7",
         'agari' => 'm2',
         'menzen' => 1,
         'tsumo' => 1,
         'jikaze' => 2,
         'bakaze' => 2,

        'yaku' => [
            "4-ANKO",
        ],
        'fu' => 20 + 16 + 2,
        'han' => 100,

        'score' => {
            'oya' => 16000,
            'ko'  =>  8000,
        },
    },
    { # 4-KANTSU
         'te' => "m2m2m2m2m4m4m4m4m8m8m8m8s5s5s5s5p7p7",
         'naki' => "m2m2m2m2 m4m4m4m4- m8m8m8m8 s5s5s5s5-",
         'agari' => 'p7',
         'jikaze' => 2,
         'bakaze' => 2,

        'yaku' => [
            "4-KANTSU",
        ],
        'fu' => 20 + 16 + 8 + 16 + 8 + 2, # 70
        'han' => 100,

        'score' => {
            'ron' => 32000,
        },
    },
    { # SHOU-SAN-GEN HATSU CHUN
         'te' => "z5z5z6z6z6z7z7z7p1p2p3p5p5p5",
         'naki' => "z7z7z7-",
         'agari' => 'p1',
         'tsumo' => 1,
         'jikaze' => 2,
         'bakaze' => 2,

        'yaku' => [
            "SHOU-SAN-GEN",
            "発",
            "中",
            "HON-ITSU",
        ],
        'fu' => 20 + 2 + 8 + 4 + 4 + 2, # 40
        'han' => 6,

        'score' => {
            'oya' => 6000,
            'ko'  => 3000,
        },
    },
    { # 3-SHOKU
        'te' => "z1z1p3p4p5z2z2z2s3s4s5m3m4m5",
        'naki' => "p3p4p5-",
        'agari' => "m5",
        'jikaze' => 3,
        'bakaze' => 1,

        'yaku' => [
            "3-SHOKU",
        ],
        'fu' => 20 + 2 + 8, # 30
        'han' => 1,

        'score' => {
            'ron' => 1000,
        },
    },
    { # HON-ROU-TOU 3-SHOKU-DOUKOU TOI-TOI 中
        'te' => "z1z1p9p9p9z7z7z7s9s9s9m9m9m9",
        'naki' => "p9p9p9-",
        'agari' => "s9",
        'jikaze' => 3,
        'bakaze' => 1,

        'yaku' => [
            "HON-ROU-TOU",
            "3-SHOKU-DOUKOU",
            "TOI-TOI-HOU",
            "中",
        ],
        'fu' => 20 + 2 + 4 + 8 + 4 + 8,
        'han' => 7,

        'score' => {
            'ron' => 12000,
        },
    },
    { # 3-KANTSU 3-ANKO
        'te'=> "m4m4m4m4m9m9m9m9p3p3p3p3s2s3s4p6p6",
        'naki' => "m4m4m4m4 m9m9m9m9 p3p3p3p3",
        'menzen' => 1,
        'agari' => "s3",
        'jikaze' => 3,
        'bakaze' => 2,

        'yaku' => [
            "3-KANTSU",
            "3-ANKO",
        ],
        'fu' => 20 + 16 + 32 + 16 + 2 + 10, # 96
        'han' => 4,

        'score' => {
            'ron' => 8000,
        },
    },
    { # RYUU-II-SOU
        'te' => "s2s3s4s2s3s4s6s6s8s8s8z6z6z6",
        'naki' => "s2s3s4 s8s8s8", # 「-」が省略されている
        'agari' => "z6",
        'tsumo' => 1,
        'jikaze' => 1, # oya
        'bakaze' => 2,

        'yaku' => [
            "RYUU-II-SOU",
        ],
        'fu' => 20 + 2 + 8 + 2, # 32
        'han' => 100,

        'score' => {
            'all' => 16000,
        },
    },
    { # NAKI structure
        'te' => 'm2m3m4m4m5m6m7 m1m2m3 m5m6m7 m1',
        'jikaze' => 1, # oya
        'bakaze' => 2,

        'yaku' => [
            "CHIN-ITSU",
        ],
        'fu' => 22, # 30
        'han' => 5,

        'score' => {
            'all' => 4000,
        },
    },
    { # DOUBLE-REACH CHANTA TSUMO
        'te' => 'm1m2p1p1p7p8p9s7s8s9z4z4z4 m3',
        'reach'  => 2,
        'jikaze' => 1, # oya
        'bakaze' => 2,

        'yaku' => [
            "DOUBLE-REACH",
            "CHANTA",
            "TSUMO",
        ],
        'fu' => 20 + 8 + 2 + 2, # 32
        'han' => 5,

        'score' => {
            'all' => 4000,
        },
    },
    { # DOUBLE-REACH CHANTA
        'te' => 'm1m2p1p1p7p8p9s7s8s9z4z4z4 m3-',
        'reach'  => 2,
        'tsumo'  => 1, # ERROR
        'jikaze' => 1, # oya
        'bakaze' => 2,

        'yaku' => [
            "DOUBLE-REACH",
            "CHANTA",
        ],
        'fu' => 20 + 8 + 2 + 10, # 40
        'han' => 4,

        'score' => {
            'ron' => 12000,
        },
    },
    { # HON-ITSU CHANTA (kui-sagari)
        'te' => 'z5z5z5s7s8s9s9s9z3z3 s1s2s3 s9-', # 「-」省略 # tsumo
        'jikaze' => 3,
        'bakaze' => 1,

        'yaku' => [
            "HON-ITSU",
            "CHANTA",
            "白",
        ],
        'fu' => 20 + 2 + 8 + 8, # 38
        'han' => 4,

        'score' => {
            'ron' => 8000,
        },
    },
    { # MEN-HON II-PEI-KO TSUMO
        'te' => 's1s2s3s2s3s4s8s9z2z2 s5s5s5s5 s7', # tsumo
        'jikaze' => 3,
        'bakaze' => 1,

        'yaku' => [
            "HON-ITSU",
            "TSUMO",
        ],
        'fu' => 20 + 16 + 2 + 2, # 40
        'han' => 4,

        'score' => {
            'oya' => 4000,
            'ko'  => 2000,
        },
    },
    { # MEN-HON HAKU HATSU
        'te' => 'p1p1p2p3p4p5p6z5z5z5z6z6z6 p1-',
        'jikaze' => 4,
        'bakaze' => 2,

        'yaku' => [
            "HON-ITSU",
            "白",
            "発",
        ],
        'fu' => 20 + 8 + 8 + 2 + 10,
        'han' => 5,

        'score' => {
            'ron' => 8000,
        },
    },
    { # TENHO
        'te' => 'p1p1p2p3p4p5p6z5z5z5z6z6z6 p1',
        'jikaze' => 1,
        'bakaze' => 2,
        'tenho'  => 1,

        'yaku' => [
            "TENHO",
        ],
        'fu' => 20 + 8 + 8 + 2 + 2,
        'han' => 100,

        'score' => {
            'all' => 16000,
        },
    },
    { # CHIIHO
        'te' => 'p1p1p2p3p4p5p6z5z5z5z6z6z6 p1',
        'jikaze' => 3,
        'bakaze' => 2,
        'tenho'  => 1,

        'yaku' => [
            "CHIIHO",
        ],
        'fu' => 20 + 8 + 8 + 2 + 2,
        'han' => 100,

        'score' => {
            'oya' => 16000,
            'ko'  =>  8000,
        },
    },
    { # HAITEI
        'te' => 'm1m2m3m9m9p2p3p7p8p9s7s8s9 p1',
        'jikaze' => 3,
        'bakaze' => 1,
        'reach'  => 1,
        'ippatsu' => 1,
        'haitei' => 1,
        'dora' => 's7',

        'yaku' => [
            "REACH",
            "IPPATSU",
            "JUN-CHAN",
            "HAITEI",
            "TSUMO",
            "PINFU",
            "DORAx1"
        ],
        'fu' => 20, # PINFU
        'han' => 9,

        'score' => {
            'oya' => 8000,
            'ko'  => 4000,
        },
    },
    { # RINSHAN
        'te' => 'm1m2m3p2p4p5p6s8s8s8 p3p3p3p3 p2',
        'jikaze' => 2,
        'bakaze' => 1,
        'rinshan' => 1,

        'yaku' => [
            "RINSHAN-KAIHO",
            "TSUMO",
        ],
        'fu' => 20 + 4 + 16 + 2 + 2, # 44
        'han' => 2,

        'score' => {
            'oya' => 1600,
            'ko'  =>  800,
        },
    },
    { # RINSHAN
        'te' => 'm1m2m3p2p4p5p6s8s8s8p3p3p3 p2',
        'jikaze' => 2,
        'bakaze' => 1,
        'rinshan' => 1, # bad

        'yaku' => [
            "TSUMO",
        ],
        'fu' => 20 + 4 + 4 + 2 + 2, # 32
        'han' => 1,

        'score' => {
            'oya' => 700,
            'ko'  => 400,
        },
    },
    { # CHANKAN
        'te' => 'z2z2p6p7p8s1s3s4s5s6 m7m7m7- s2', # あがり牌の「-」省略
        'jikaze' => 2,
        'bakaze' => 1,
        'chankan' => 1,
        'dora' => 'z2',

        'yaku' => [
            "CHANKAN",
            "DORAx2",
        ],
        'fu' => 20 + 2 + 2 + 2, # 26
        'han' => 3,

        'score' => {
            'ron' => 3900,
        },
    },
);

plan tests => @tests * 5;


my $mjc = MG->new( 'logfile' => $logfile,
                   'rule'    => {
                        'renpu_toitsu4'          => 0, # 連風対子は 2符
                        'kuitan'                 => 0, # 食いタンなし
                        'no_double_yakuman'      => 0, # ダブル役満あり
                        'no_triple_yakuman'      => 0, # トリプル役満あり
                        'no_4anko_tanki_double'  => 0, # 四暗刻単騎待ちはダブル役満
                        'no_daisuushii_double'   => 0, # 大四喜はダブル役満
                        'no_kokushi13_double'    => 0, # 国士無双13面待ちはダブル役満
                        'no_4kantsu_double'      => 1, # 四槓子はダブル役満ではない
                        'no_chuurenpoto9_double' => 0, # 九連宝燈9面待ちはダブル役満
                   } );

foreach my $test ( @tests ) {
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
