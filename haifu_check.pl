#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Encode;
use encoding "utf-8", STDOUT=>"euc-jp", STDERR=>"euc-jp";
use Test::More;

use MG;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(euc-jp)";
binmode $builder->failure_output, ":encoding(euc-jp)";

my @tests = ();
my $test_num = 0;
my $ok_num = 0;

# デバッグログ

open my $logfile, '>:encoding(euc-jp)', "g.log";

# 牌譜

#open my $haifu, '<:encoding(cp932)', "haifu_mini.txt";
open my $haifu, '<:encoding(cp932)', "haifu.txt";
#open my $haifu, '<:encoding(cp932)', "totuhaihu.txt";
#binmode( STDOUT, ":encoding(euc-jp)" );
#binmode( STDERR, ":encoding(euc-jp)" );

# 牌譜をチェックする

my $haistr = "(?:[1-9][mps]|[東南西北白発中])";

my $bakaze = "";
my $honba = 0;
my $reach_ba = 0;
my @score = ( 0, 0, 0, 0 );
my $fu    = 0;
my $han   = "";
my $tsumo = 0;
my $yaku  = "";
my %tehai = ();
my %jikaze = ();
my $dora_omote = "";
my $dora_ura   = "";
my $pre_hai    = "";
my $pre_person = 0;
my $pre_action = "";
my %reach = ();
my %reach_temp = ();
my $kuitan = 1;

while ( <$haifu> ) {
    my $line = $_;
    $line =~ s/[\r\n]+//;
    my $line_number = $.;

    if ( $line =~ /^[=]{5} [ ] (東風戦|東南戦)/x ) {
        # ===== 東風戦ランキング超上級 568卓 開始 2002/03/04 13:38 =====

        if ( $1 eq "東風戦" ) {
            $kuitan = 0;
        } else {
            $kuitan = 1;
        }
    }

    if ( $line =~ /^[ ]{2}([東南西北])\d局 [ ] (\d+) 本場 [(] リーチ (\d+) [)]
                    [ ] [^ ]+ [ ] (\d+) 
                    [ ] [^ ]+ [ ] (-\d+)
                    (?: [ ] [^ ]+ [ ] (-\d+) )? (?: [ ] [^ ]+ [ ] (-\d+) )?/x ) {
        #   東1局 0本場(リーチ0) 壁に耳あり村 8000 ㌧㌦めろーね -8000

        $bakaze   = $1;
        $honba    = $2;
        $reach_ba = $3;
        $score[0] = $4;
        $score[1] = $5;
        $score[2] = $6 || 0;
        $score[3] = $7 || 0;

        $fu   = 0;
        $han  = "";
        $tsumo = 0;
        $yaku = "";
        %tehai = ();
        %jikaze = ();
        %reach = ();

#        printf "%s %d honba, reach %d, agari %d, minus %d, %d, %d\n", $1, $2, $3, $4, $5, $6 || "0", $7 || "0";
    }

    if ( $line =~ /^[ ]{4}(?:(\d+)符[ ])? ([^ ]+)(ロン|ツモ) [ ] (.+)/x ) {
        #     満貫ロン リーチ 一発 ドラ2 

        $fu    = $1 || 0;
        $han   = $2;
        $tsumo = ( $3 eq "ツモ" );
        $yaku  = $4;
        %tehai = ();
        %jikaze = ();
        %reach = ();

#        printf "%d fu %s %s, yaku %s\n", $1 || 0, $2, $3, $4;
    } elsif ( $line =~ /^[ ]{4}チョンボ/x ) {
        $yaku = "";
    }

    # 配牌

    if ( $line =~ /^[ ]{4}[\[] (\d) (東|南|西|北) [\]] (.+)$/x ) {
        #     [1西]4m6m8m1p2p4p8p1s2s2s5s6s南

        $tehai{$1} = $3;
        $jikaze{$1} = $2;

#        printf "%d %s cha, haipai %s\n", $1, $2, $3;
    }

    # ドラ

    if ( $line =~ /^[ ]{4}[\[] 表ドラ [\]] ([^ ]+) [ ]
                          [\[] 裏ドラ [\]] ([^ ]+)$/x ) {
        $dora_omote = $1;
        $dora_ura   = $2;

#        printf "omote dora %s, ura dora %s\n", $1, $2;
    }

    # ツモの動きを再現

    if ( $line =~ /^[ ]{4}[*] [ ] (.+)$/x ) {
        my $dahai = $1;

        foreach my $da ( split( ' ', $dahai ) ) {
            $da =~ /^(\d) ([GdDNKCAR]) (.+)?$/x;

            my $person = $1;
            my $action = $2;
            my $hai = $3;

            if ( !defined $action ) {
                die "Unknown dahai $da";
            }

            if ( $action eq 'G' ) {
                # ツモ
                $tehai{$person} = $hai . $tehai{$person};
            } elsif ( $action =~ /^[dD]$/ ) {
                # 手出し or ツモ切り
                $tehai{$person} =~ s/$hai//;
                $pre_hai = $hai;
            } elsif ( $action eq "N" ) {
                # ポン
                $tehai{$person} =~ s/($pre_hai)//;
                $tehai{$person} =~ s/($pre_hai)//;
                $tehai{$person} .= " " . ( $pre_hai x 3 ) . "-";
            } elsif ( $action eq "K" ) {
                # カン
                if ( $tehai{$person} =~ /$hai$hai$hai-/ ) {
                    # 加カン
                    $tehai{$person} =~ s/$hai//;
                    $tehai{$person} =~ s/$hai$hai$hai-/$hai$hai$hai$hai-/;
                } else {
                    $tehai{$person} =~ s/$hai//g;
                    $tehai{$person} .= " " . ( $hai x 4 );
                    if ( $pre_action =~ /^[dD]$/ ) {
                        # 大明槓
                        $tehai{$person} .= "-";
                    } else {
                        # 暗槓
                    }
                }
            } elsif ( $action eq "C" ) {
                # チー
                while ( $hai =~ /($haistr)/g ) {
                    $tehai{$person} =~ s/$1//;
                }
                $tehai{$person} .= " " . $hai . $pre_hai . "-";
            } elsif ( $action eq "R" ) {
                # リーチ
                $reach_temp{$person} = 1;
            } elsif ( $action eq "A" ) {
                # あがり
                if ( $pre_action =~ /^[dD]$/ ) {
                    # 前の捨て牌によるあがり (ロン)
                    $tehai{$person} .= " " . $pre_hai . "-";
                } elsif ( $pre_action eq "G" ) {
                    # ツモあがり
                    $tehai{$person} =~ s/^($haistr)(.+)$/$2 $1/x;
                }
#                printf "!!agari!! %s cha : %s, %s\n",
#                    $jikaze{$person}, $tehai{$person}, convert_hai( $tehai{$person} );

                my %check;
                $check{te} = convert_hai( $tehai{$person} );

                $check{reach} = ( $yaku =~ /ダブルリーチ/ ? 2 :
                                ( $yaku =~ /リーチ/      ? 1 : 0 ) );
                $check{ippatsu} = ( $yaku =~ /一発/ );
                $check{haitei} = ( $yaku =~ /河底撈魚|海底撈月/ );
                $check{rinshan} = ( $yaku =~ /嶺上開花/ );

                # 符、はん

                $check{fu} = $fu;
                $check{han} = han_to_num( $han );

                # 点数

                if ( $tehai{$person} =~ /-$/ ) {
                    # ロン
                    my $max_score = - ( $score[1] < $score[2] ? $score[1] :
                                      ( $score[2] < $score[3] ? $score[2] :
                                                                $score[3] ) );
#                    printf "max_score %d, score1 %d, score2 %d, score3 %d\n",
#                        $max_score, $score[1], $score[2], $score[3];

                    $check{score}->{ron} = ( $max_score )
                                           - ( $honba * 300 ) # 積み棒
                                           - ( $reach{$pre_person} ? 1000 : 0 ); # リーチ棒
                } else {
                    my $member_num = scalar keys %jikaze;
#                    printf "  %d members.\n", $member_num;

                    if ( $jikaze{$person} eq '東' ) {
                        # 親

                        # 南家の位置を探す
                        # 自分が一番後ろの場合はスコアでは2番目にいる

                        my $ko_person = $person + 1;
                        my $ko_score;
                        if ( $ko_person > $member_num ) {
                            $ko_person = 1;
                            $ko_score  = 1;
                        } else {
                            $ko_score  = $ko_person - 1;
                        }

                        $check{score}->{all} = - ( $score[$ko_score] )
                                               - ( $honba * 100 ) # 積み棒
                                               - ( $reach{$ko_person} ? 1000 : 0 ); # リーチ棒
                    } else {
                        # 子
                        # 親の位置を探す
                        # 親よりも並びが後ろの場合は、親は後ろに繰り下る
                        #   ex. 西北東南 の順の場合で、南があがったとき ⇒ 南西北東の順になる
                        # 1番目にいる ⇒ いつでも変わらない
                        # 2番目にいる ⇒ 南(2)のときだけ入れかわる (西(3)、北(4)は変わらない)
                        # 3番目にいる ⇒ 西(3)と南(2)のときは入れかわる (北(4)は変わらない)
                        # 4番目にいる ⇒ いつでも入れかわる
                        # したがって、
                        # $person >= kaze_to_num( $jikaze{$person} )
                        # の条件で入れかわりを判別すればよい

                        my $oya_person =
                            ( $member_num + 1
                              - kaze_to_num( $jikaze{$person} ) + $person ) %
                            $member_num;
                        $oya_person = $member_num if ( $oya_person == 0 );
                        my $oya_score = ( $oya_person - 1 ) % $member_num;
                        if ( $person >= kaze_to_num( $jikaze{$person} ) ) {
                            $oya_score ++;
                        }

                        # 次に、自分以外の子を探す
                        # 子は、親よりも下家側で探す
                        # あがったのが南家であれば、西家を探すことになる
                        # 点数は、単に親の次から探す。ただし、親が一番後ろの場合は2番目から

                        my $ko_person  = $oya_person + 1;
                        $ko_person = 1 if ( $ko_person == $member_num + 1 );
                        if ( $ko_person == $person ) {
                            $ko_person ++;
                            $ko_person = 1 if ( $ko_person == $member_num + 1 );
                        }
                        my $ko_score   = $oya_score  + 1;
                        $ko_score = 1 if ( $ko_score == $member_num ); # 配列の 2番目は 1

#                        printf "self %d oya %d ko %d, oya_score %d ko_score %d\n",
#                            $person, $oya_person, $ko_person, $oya_score, $ko_score;

                        $check{score}->{oya} = - ( $score[$oya_score] )
                                               - ( $honba * 100 ) # 積み棒
                                               - ( $reach{$oya_person} ? 1000 : 0 ); # リーチ棒
                        $check{score}->{ko}  = - ( $score[$ko_score ] )
                                               - ( $honba * 100 ) # 積み棒
                                               - ( $reach{$ko_person}  ? 1000 : 0 ); # リーチ棒
                    }
                }

                # 自風、場風

                $check{jikaze} = kaze_to_num( $jikaze{$person} );
                $check{bakaze} = kaze_to_num( $bakaze );

                # ドラ

                my $dora = $dora_omote;
                $dora .= $dora_ura if ( $check{reach} );
                $dora =~ s/($haistr)/$1 /g;
                $check{dora} = convert_hai( $dora );

                # 役

                my @yaku_list =
                    split( ' ',
                           convert_yaku( $yaku, $jikaze{$person}, $bakaze ) );
                $check{yaku} = \@yaku_list;

                if ( scalar @yaku_list > 0 ) {
                    agari_test( \%check,
                                { 'renpu_toitsu4' => 1,
                                  'kuitan'        => $kuitan, },
                                $line_number );
                }
            }                

            $pre_action = $action;
            $pre_person = $person;

            foreach my $reach_person ( keys %reach_temp ) {
                if ( $person != $reach_person ) {
                    # 他の人が何かアクションをした時点でリーチが成立する

                    $reach{$reach_person} = 1;
                    delete $reach_temp{$reach_person};
                }
            }

#            printf "  %s cha tehai %s, action %s\n",
#                $jikaze{$person}, $tehai{$person}, $da;
        }

#        printf "dahai %s\n", $1;
    }
}

done_testing;

close $logfile;

exit 0;

sub agari_test {
    my $test = shift;
    my $rule = shift;
    my $line_number = shift;

    my $mjc = MG->new( 'logfile' => $logfile,
                       'rule'    => $rule, );

    my $result = $mjc->check( $test );

    if ( defined( $result ) ) {
        my $pass = 1;
        my $msg;

        $mjc->log_( 2, "=== RESULT ===" );
        $mjc->log_( 0, sprintf "AGARI-KEI  %s", $result->{tehai} );

        if ( $result->{han} < 5 ) {
            my $base_score = ( $result->{st_fu} * ( 2 ** ( 2 + $result->{han} ) ) );

            if ( $base_score >= 2000 ) {
                # 符ハネ
                # 満貫
                $result->{fu} = 0;
                $result->{han} = 5;
            } else {
                $result->{fu} = $result->{st_fu};
            }
        } else {
            $result->{han} =  6 if ( $result->{han} == 7 );
            $result->{han} =  8 if ( $result->{han} >= 9 && $result->{han} <= 10 );
            $result->{han} = 11 if ( $result->{han} == 12 );
            $result->{han} = 13 if ( $result->{han} >= 14 && $result->{han} <= 99 );

            $result->{fu} = 0;
        }

        is( $result->{fu},  $test->{fu},  "FU  $test->{te} ($line_number)" );
        is( $result->{han}, $test->{han}, "HAN $test->{te} ($line_number)" );

        if ( ( $result->{fu}  == $test->{fu}  ) &&
             ( $result->{han} == $test->{han} ) ) {
            $msg = "OK";
        } else {
            $msg = "NG";
            $pass = 0;
        }
        $msg .= sprintf "  %d fu => %d fu  ", $result->{fu}, $result->{st_fu};
        if ( $result->{han} >= 300 ) {
            $msg .= "Triple-Yakuman($result->{han})";
        } elsif ( $result->{han} >= 200 ) {
            $msg .= "Double-Yakuman($result->{han})";
        } elsif ( $result->{han} >= 100 ) {
            $msg .= "Yakuman($result->{han})";
        } else {
            $msg .= sprintf "%d han", $result->{han};
        }
        $mjc->log_( 0, $msg );

        my $yaku_list = join( ' ', sort @{$result->{yaku}} );
        my $expect_yaku_list = join( ' ', sort @{$test->{yaku}} );
#        $expect_yaku_list = convert_yaku( $expect_yaku_list );

        is( $yaku_list, $expect_yaku_list, "YAKU $test->{te} ($line_number)" );

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
                       sprintf "$result->{fu} fu $result->{han} han (%s) (%s)  ($line_number)",
                               ( $test->{jikaze} == 1 ? 'oya' : 'ko' ),
                               ( $test->{tsumo} ? 'tsumo' : 'ron' ) );
        }

        if ( !$pass ) {
            $mjc->log_( 0, "=== EXPECT ===" );
            $mjc->log_( 0, sprintf "    %d fu => %d fu  %d han",
                $test->{fu}, $test->{st_fu}, $test->{han} );
            $mjc->log_( 0, sprintf "    %s", $expect_yaku_list );
        } else {
            $ok_num ++;
        }
    }
    $mjc->log_( 0, "" );
    $test_num ++;
}


sub convert_hai
{
    my $hai = shift;

    $hai =~ s/東/1z/g;
    $hai =~ s/南/2z/g;
    $hai =~ s/西/3z/g;
    $hai =~ s/北/4z/g;
    $hai =~ s/白/5z/g;
    $hai =~ s/発/6z/g;
    $hai =~ s/中/7z/g;

    my $result = '';

    while ( $hai =~ s/([\d])([mpsz])([ -]+)?//x ) {
        $result .= $2 . $1 . ( $3 || '' );
    }

    return $result;
}

sub kaze_to_num
{
    my $kaze = shift;

    my %kaze_list = (
        '東' => 1,
        '南' => 2,
        '西' => 3,
        '北' => 4,
    );

    return $kaze_list{$kaze};
}

sub han_to_num
{
    my $han = shift;

    my %han_list = (
        '一飜' => 1,
        '二飜' => 2,
        '三飜' => 3,
        '四飜' => 4,
        '満貫' => 5,
        'ハネ満貫' => 6, # 6-7
        '倍満貫' => 8, # 8-10
        '３倍満貫' => 11, # 11-12
        '数え役満' => 13, # 13-
        '役満' => 100,
        'ダブル役満' => 200,

        '一翻' => 1,
        '二翻' => 2,
        '三翻' => 3,
        '四翻' => 4,
    );

    return $han_list{$han};
}

sub convert_yaku
{
    my ( $yaku, $jikaze, $bakaze ) = @_;

    $yaku =~ s/ダブルリーチ/DOUBLE-REACH/;
    $yaku =~ s/リーチ/REACH/;
    $yaku =~ s/ドラ/DORAx/;
    $yaku =~ s/一発/IPPATSU/;
    $yaku =~ s/七対子/CHII-TOITSU/;
    $yaku =~ s/門前清模和/TSUMO/;
    $yaku =~ s/平和/PINFU/;
    $yaku =~ s/清一色/CHIN-ITSU/;
    $yaku =~ s/断ヤオ/TAN-YAO/;
    $yaku =~ s/一気通貫/1-TSUU/;
    $yaku =~ s/一盃口/II-PEI-KO/;
    $yaku =~ s/三色同順/3-SHOKU/;
    $yaku =~ s/自風/$jikaze/;
    $yaku =~ s/場風/$bakaze/;
    $yaku =~ s/$jikaze $jikaze/DOUBLE-$jikaze/;
    $yaku =~ s/混一色/HON-ITSU/;
    $yaku =~ s/対々和/TOI-TOI-HOU/;
    $yaku =~ s/河底撈魚/HAITEI/;
    $yaku =~ s/海底撈月/HAITEI/;
    $yaku =~ s/三暗刻/3-ANKO/;
    $yaku =~ s/純全帯/JUN-CHAN/;
    $yaku =~ s/嶺上開花/RINSHAN-KAIHO/;
    $yaku =~ s/四暗刻単騎待/4-ANKO(TANKI)/;
    $yaku =~ s/四暗刻/4-ANKO/;
    $yaku =~ s/全帯/CHANTA/;
    $yaku =~ s/二盃口/RYAN-PEI-KO/;
    $yaku =~ s/国士無双１３面待/KOKUSHI-MUSOU(13men-chan)/;
    $yaku =~ s/国士無双/KOKUSHI-MUSOU/;
    $yaku =~ s/三色同刻/3-SHOKU-DOUKOU/;
    $yaku =~ s/混老頭/HON-ROU-TOU/;
    $yaku =~ s/大三元/DAI-SAN-GEN/;
    $yaku =~ s/字一色/TSUU-II-SOU/;
    $yaku =~ s/小三元/SHOU-SAN-GEN/;
    $yaku =~ s/小四喜和/SHOU-SUU-SHII/;
    $yaku =~ s/緑一色/RYUU-II-SOU/;
    $yaku =~ s/清老頭/CHIN-ROU-TOU/;

    return $yaku;
}