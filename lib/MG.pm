package MG;

use strict;
use warnings;
use utf8;

our $VERSION = '0.01';

# --------------------------------------------------------------------------
# 定数
# --------------------------------------------------------------------------

# 字牌の名前

my %ji_name = (
    '1' => "東",
    '2' => "南",
    '3' => "西",
    '4' => "北",
    '5' => "白",
    '6' => "発",
    '7' => "中",
);

# --------------------------------------------------------------------------
# 初期化ルーチン
# --------------------------------------------------------------------------

sub new
{
    my $class = shift;
    my %param = @_;
    my $self = {};

    $self->{name} = 'Mahjong::Calculator';
    $self->{errstr} = "";

    $self->{DEBUG} = $param{debug} || 0;
    $self->{logfile} = $param{logfile};

    # TODO: 利用ルールの充実
    # Supported rules:
    #   ->{renpu_toitsu4}      連風対子を 4符とするかどうか（デフォルトオフ）
    #   ->{kuitan}             食いタンありかどうか（デフォルトオフ）
    #   ->{no_double_yakuman}  ダブル役満なしかどうか（デフォルトあり）
    #   ->{no_triple_yakuman}  トリプル役満なしかどうか（デフォルトあり）
    #   ->{no_4anko_tanki_double} 四暗刻単騎待ちをダブル役満とするかどうか (デフォルトはする)
    #   ->{no_daisuushii_double}  大四喜をダブル役満とするかどうか (デフォルトはする)
    #   ->{no_kokusi13_double} 国士無双13面待ちをダブル役満とするかどうか (デフォルトはする)
    #   ->{no_4kantsu_double}  四槓子をダブル役満とするかどうか (デフォルトはする)
    #   ->{no_chuurenpoto9_double} 九連宝燈9面待ちをダブル役満とするかどうか (デフォルトはする)

    $self->{rule} = $param{rule};

    bless $self, $class;
    return $self;
}

# --------------------------------------------------------------------------
# チェックルーチン
# --------------------------------------------------------------------------

sub check
{
    my $self = shift;
    my $test = shift;
    my $rest = $test->{te};
    my %pc;
    my $ok = 0;
    my $chiitoitsu = 0;
    my $kokushi = 0;
    my $max;
    my $max_fu = 0;
    my $max_han = 0;
    my $han = 0;
    my @yaku;

    $self->{errstr} = "";

    # TODO: エラーチェックに他に必要なものはないか？
    # ex.
    #   文字数が正しいこと (done)
    #   正しい文字のみで構成されていること (done)
    #   あがり牌が手の中に存在していること (done)
    #   泣きが正しい形式であること (done)
    #   刻子、順子の泣きは、「-」の省略可とする（ここで加える） (done)
    #   泣いた牌が手の中に存在していること (done)
    #   牌が多いのはカンしている場合のみであること (done)
    #   同じ牌が5枚以上存在しないこと (done)
    #   カンしている牌があがり牌というのはありえない (done)
    #   泣いている牌以外にあがり牌がないというのはありえない (done)

    my @m;
    my $error = 0;
    my $mc = 0;

    if ( $test->{te} =~ / / ) {
        # 泣き・あがり牌形式
        # m2m3m4m4m5m6m7 m1m2m3- m5m6m7- m1
        # z7z7p1p2z6z6z6 p8p8p8p8 m9m9m9- p3
        # 一番左に手牌、一番右にあがり牌を置き、その間に（あれば）フーロした
        # ものを並べた形式
        # この形式の場合は、agari naki が未定義でよい
        # ツモも未定義でよい（あがり牌に「-」が入ってなければツモ）
        # 面前も未定義でよい（暗カン以外の泣きがなければ面前）

        my @tehai = split( ' ', $test->{te} );

        $test->{agari} = pop @tehai;
        if ( ( $test->{agari} =~ s/-// ) || $test->{chankan} ) {
            # チャンカンの場合は必ずロンあがり

            delete $test->{tsumo};
        } else {
            $test->{tsumo} = 1;
        }

        $test->{te} = ( shift @tehai ) . $test->{agari};
        $test->{naki} = join( ' ', map { s/^(([mpsz]\d){3})$/$1-/; $_ } @tehai );
        $test->{te} .= $test->{naki};
        $test->{menzen} = ( $test->{naki} !~ /-/ );
        $test->{te} =~ s/[- ]//g;
    } else {
        # あがりが未定義ならエラー

        if ( !defined( $test->{agari} ) ) {
            $self->{errstr} = "agari is not defined";
            return undef;
        }

        # あがり牌が手中に存在しなければエラー

        if ( $test->{te} !~ /$test->{agari}/ ) {
            $self->{errstr} = "agari hai does not exist in te";
            return undef;
        }
    }

    $self->log_( 0, sprintf "手(%s) 泣き(%s) %s(%s) 風(%s,%s) ドラ(%s)",
        $test->{te},
        $test->{naki} || '-',
        ( $test->{tsumo} ? "ツモ" : "ロン" ),
        $test->{agari},
        $ji_name{$test->{jikaze}},
        $ji_name{$test->{bakaze}},
        $test->{dora} || '' );

    # あがり牌が正しい文字だけで構成されているかどうかをチェック

    if ( $test->{agari} !~ /^([mps][1-9]|z[1-7])$/ ) {
        $self->{errstr} = "Invalid agari hai ($test->{agari})";
        return undef;
    }

    # 正しい文字だけで構成されているかどうかをチェック

    if ( $test->{te} !~ /^([mps][1-9]|z[1-7])+$/ ) {
        $self->{errstr} = "Invalid character exists in te ($test->{te})";
        return undef;
    }

    # 牌の数を数える

    while ( $test->{te} =~ /([mps][1-9]|z[1-7])/g ) {
        $pc{$1}++;
    }
    foreach my $p ( sort keys %pc ) {
        # 同じ牌が 5枚以上あればエラー

        if ( $pc{$p} > 4 ) {
            $self->{errstr} = "Too many $p";
            return undef;
        }
    }

    $self->debug_print( \%pc );

    # 泣き処理

    if ( defined( $test->{naki} ) ) {
        foreach my $nm ( split( ' ', $test->{naki} ) ) {
            # 泣きが面子の形になっているかどうか

            if ( !$self->check_naki( $nm ) ) {
                $error = $nm;
                last;
            }

            # 暗カン以外で「-」が省略されている場合は、ここで加える

            if ( ( $nm !~ /([mpsz]\d)\1{3}/ ) && ( $nm !~ /-/ ) ) {
                $nm .= "-";
            }

            push @m, $nm;
            $mc++;
            $self->log_( 1, "NAKI: $nm" );

            while ( $nm =~ s/([mpsz]\d)// ) {
                my $p = $1;
                if ( defined( $pc{$p} ) && $pc{$p} > 0 ) {
                    $pc{$p}--;
                    delete $pc{$p} if ( $pc{$p} == 0 );
                } else {
                    $error = $nm;
                    last;
                }
            }
            last if ( $error );
        }

        if ( $error ) {
            $self->log_( 0, "ERROR: naki ($error)" );
            $self->{errstr} = "Invalid naki ($error)";
            return undef;
        }

        $self->debug_print( \%pc );

        # 暗カン以外の泣きが入っている場合は面前じゃない

        if ( $test->{naki} =~ /-/ ) {
            delete $test->{menzen};
        }
    }

    # 残りの牌の数が正しいかどうか

    my $hc = 0;
    foreach my $p ( sort keys %pc ) {
        $hc += $pc{$p};
    }
    if ( $hc != 14 - 3 * $mc ) {
        $self->{errstr} = ( $hc < 14 - 3 * $mc ? "Too few hais" : "Too many hais" );
        return undef;
    }

    # 残りの牌にあがり牌があるかどうか

    if ( !defined( $pc{$test->{agari}} ) || ( $pc{$test->{agari}} < 1 ) ) {
        $self->{errstr} = "agari hai does not exist in te";
        return undef;
    }

    if ( $test->{menzen} ) {
        # chii-toitsu

        my $toitsu_num = 0;

        foreach my $p ( sort keys %pc ) {
            if ( $pc{$p} == 2 ) {
                $toitsu_num++;
            } else {
                $toitsu_num = -1;
                last;
            }
        }
        if ( $toitsu_num == 7 ) {
            $chiitoitsu = 1;

            $max = join( ' ', map { $_ x 2 } sort keys %pc );
            $max_fu = 25;
        } else {
            # kokushi-musou

            if ( join( '', sort keys %pc ) eq 'm1m9p1p9s1s9z1z2z3z4z5z6z7' ) {
                $kokushi = 1;
                $max = join( ' ', map { $_ x $pc{$_} } sort keys %pc );
                $max_fu = 0;

                $ok = 1;

                if ( $pc{$test->{agari}} == 2 ) {
                    # 13men-chan
                    push @yaku, "KOKUSHI-MUSOU(13men-chan)";
                    $han += 200;
                } else {
                    push @yaku, "KOKUSHI-MUSOU";
                    $han += 100;
                }
            }
        }
    }

    if ( !$kokushi ) {
        # 字処理

        my $head = '';

        foreach my $p ( keys %pc ) {
            if ( $p =~ /^z.$/ ) {
                if ( $pc{$p} eq 3 ) {
                    push @m, $p x 3;
                    delete $pc{$p};
                    $mc ++;
                } elsif ( $pc{$p} eq 2 ) {
                    $head = $p x 2;
                    delete $pc{$p};
                } else {
                    $error = 1;
                    last;
                }
            }
        }

        $self->log_( 1, "mentsu @m" ) if ( scalar @m >= 1 );
        $self->log_( 1, sprintf "head %s", $head ) if ( $head ne '' );
        $self->log_( 1, sprintf "error %d", $error ) if ( $error );

        if ( $error ne 0 ) {
            $self->{errstr} = "Go-ron (invalid jihai)";
            return undef;
        }

        $self->debug_print( \%pc );

        my @ok_pat;

        if ( $head eq '' ) {
            # search for head

            foreach my $p ( sort keys %pc ) {
                if ( $pc{$p} >= 2 ) {
                    my $kari_head;
                    my %kari = %pc;
                    my @kari_m = @m;
                    my $kari_mc = $mc;

                    $kari_head = $p x 2;
                    $self->log_( 1, sprintf "kari head = %s", $kari_head );

                    $kari{$p} -= 2;
                    if ( $kari{$p} == 0 ) {
                        delete $kari{$p};
                    }

                    # search mentsu

                    my %params;
                    $params{kari} = \%kari;
                    my $result = $self->search_mentsu( \%params );
                    $kari_mc += $result->{mc};
                    push @kari_m, @{$result->{m}};

                    if ( $kari_mc ne 4 ) {
                        # NG

                        $self->log_( 1, "mentsu NG" );
                    } else {
                        # OK

                        $self->log_( 1, "mentsu OK" );
                        push @ok_pat, sprintf "%s %s", $kari_head, join( ' ', @kari_m );
                        $ok = 1;
                    }
                }
            }
        } else {
            my %kari = %pc;
            my @kari_m = @m;
            my $kari_mc = $mc;
            my $kari_head = $head;

            # search mentsu

            my %params;
            $params{kari} = \%kari;
            my $result = $self->search_mentsu( \%params );
            $kari_mc += $result->{mc};
            push @kari_m, @{$result->{m}};

            if ( $kari_mc ne 4 ) {
                # NG

                $self->log_( 1, "result NG" );
            } else {
                # OK

                $self->log_( 1, "result OK" );
                push @ok_pat, sprintf "%s %s", $kari_head, join( ' ', @kari_m );
                $ok = 1;
            }
        }

        if ( $ok ) {
            my %result;

            # 複数のパターンが存在する場合はそれぞれを調べる

            foreach my $pat ( @ok_pat ) {

                while ( $pat =~ /(^|\s)(([mps])(\d))\2{2} \s (\3([^\4]))\5{2} \s (\3([^\4\6]))\7{2}(\s|$)/gx ) {
                    next if ( $6 != $4 + 1 || $8 != $6 + 1 );

                    # シュンツのパターンがある
                    # 例えば、p1p2p3 p1p2p3 p1p3 m1m1 m7m8m9 で p2 でツモあるいはロンあがりしたケース
                    # ツモの場合
                    #   p1p1p1 p2p2p2 p3p3p3 の刻子と見れば、ツモ三暗刻で 40符3はん
                    #   p1p2p3 p1p2p3 p1p2p3 の順子と見れば、ツモ純チャン一盃口で 30符5はん（満貫）
                    # ロンの場合
                    #   p1p1p1 p2p2p2 p3p3p3 の刻子と見ると、役なし
                    #   p1p2p3 p1p2p3 p1p2p3 の順子と見れば、純チャン一盃口で 40符4はん（満貫）
                    # 面前でなく一盃口が成立しない場合（m7m8m9を泣いている場合）は純チャン（食い下がり2はん）が成立
                    # ツモの場合は、三暗刻と見れば 40符2はん、純チャンと見れば 30符2はんなので、三暗刻が選択される
                    # ロンの場合は三暗刻が成立しないため、純チャンで 30符2はん

                    my $shuntsu_pat = $pat;
                    $shuntsu_pat =~ s/(^|\s)(([mps])(\d))\2{2} \s (\3([^\4]))\5{2} \s (\3([^\4\6]))\7{2}(\s|$)
                                     /$1$3$4$3$6$3$8 $3$4$3$6$3$8 $3$4$3$6$3$8$9/x;
                    $self->log_( 1, "     SHUNTSU $shuntsu_pat" );

                    push @ok_pat, $shuntsu_pat;
                    last;
                }

                # ロンあがりで、あがり牌で刻子ができている場合は、明刻扱いにする

                # ただし、p1p2p3 p1p1 m1m1 m5m6m7 s6s7s8 から p1 であがった（ロン）場合、
                # p1p2p3 のメンツができたと見れば p1p1p1 は暗刻扱いで、8符
                # p1p1p1 のメンツができたと見れば p1p1p1 は明刻扱いで、4符
                # この場合は暗刻扱いにする
                # 要は、刻子にあがり牌が含まれている場合は他のメンツもチェックにも含まれているか
                # どうかをチェックして、含まれていれば暗刻扱いにすればよいということだろう
                # p2p3p3p3p4 p5p5 で p3 をロンした場合については、
                # p2p3p4 のメンツができたと見れば p3p3p3 は暗刻扱いで 4符、p2p3p4 は間ちゃんなので 2符、計6符
                # p3p3p3 のメンツができたと見れば p3p3p3 は明刻扱いで 2符、p2p3p4 は両面ちゃんなので 0符、計2符
                # この場合も、やはり暗刻として扱ってよい
                # ツモあがりの場合もやはり暗刻とすればよい

                if ( !$test->{tsumo} && $pat =~ /^(.*)\s($test->{agari}){3}(\s|$)(.*)$/ ) {
                    $self->log_( 1, "PON: ($1) ($2) ($3) ($4)" );
                    if ( $1 !~ /$test->{agari}/ && $4 !~ /$test->{agari}/ ) {
                        $pat =~ s/(?<=\s($test->{agari}){3})/-/;
                    }
                }

                $self->log_( 1, "TEHAI pattern : $pat" );

                # 符を計算する

                my ( $fu, $pinfu ) = $self->calc_fu( {
                    'pat'    => $pat, 
                    'agari'  => $test->{agari},
                    'menzen' => $test->{menzen},
                    'tsumo'  => $test->{tsumo},
                    'jikaze' => $test->{jikaze},
                    'bakaze' => $test->{bakaze}
                } );

                # 役とはん数を調べる

                my ( $yaku_, $han_ ) = $self->check_yaku( {
                    'tehai'   => $pat,
                    'reach'   => $test->{reach},
                    'ippatsu' => $test->{ippatsu},
                    'agari'   => $test->{agari},
                    'menzen'  => $test->{menzen},
                    'tsumo'   => $test->{tsumo},
                    'jikaze'  => $test->{jikaze},
                    'bakaze'  => $test->{bakaze},
                    'haitei'  => $test->{haitei},
                    'rinshan' => $test->{rinshan},
                    'chankan' => $test->{chankan},
                    'tenho'   => $test->{tenho},
                } );

                $result{$pat}{fu} = $fu;
                $result{$pat}{han} = $han_;
                $result{$pat}{yaku} = $yaku_;

                if ( $pinfu ) {
                    $han_ ++;
                    push @{$yaku_}, "PINFU";
                }

                $self->log_( 1, "  $fu fu $han_ han (@{$yaku_})" );

                if ( $han_ > $max_han ) {
                    $max = $pat;
                    $max_han = $han_;
                    $max_fu = $fu;
                    @yaku = @{$yaku_};
                    next;
                }
                if ( $max_han == $han_ && $fu > $max_fu ) {
                    $max = $pat;
                    $max_fu = $fu;
                    @yaku = @{$yaku_};
                    next;
                }
            }
        }
        $han = $max_han;
    }

    # 七対子としかみなせない場合は、そのように処理する

    if ( !$ok && $chiitoitsu  ) {
        $ok = 1;

        # 七対子以外の役を探す

        my ( $yaku_, $han_ ) = $self->check_yaku( {
            'tehai'  => $max,
            'reach'  => $test->{reach},
            'ippatsu' => $test->{ippatsu},
            'agari'  => $test->{agari},
            'menzen' => $test->{menzen},
            'tsumo'  => $test->{tsumo},
            'jikaze' => $test->{jikaze},
            'bakaze' => $test->{bakaze},
            'haitei'  => $test->{haitei},
            'rinshan' => $test->{rinshan},
            'chankan' => $test->{chankan},
            'tenho'   => $test->{tenho},
        } );

        @yaku = @{$yaku_};
        $han = $han_;

        # 役満でなければ、役を加える

        if ( $han < 100 ) {
            push @yaku, "CHII-TOITSU";
            $han += 2;
        }
    }

    if ( $ok ) {
        # ドラを数える
        # 役なしの場合や、役満の場合はドラは考慮しない

        my $dora = 0;
        if ( ( $han > 0 ) && ( $han < 100 ) ) {
            if ( defined( $test->{dora} ) ) {
                foreach my $d ( split( ' ', $test->{dora} ) ) {
                    while ( $max =~ /$d/g ) {
                        $dora ++;
                    }
                }
            }

            if ( $dora > 0 ) {
                $han += $dora;
                push @yaku, "DORAx" . $dora;
            }
        }

        # ダブル役満やトリプル役満がありかどうか

        if ( $self->{rule}->{no_double_yakuman} ) {
            $han = 100 if ( $han >= 100 );
        }
        if ( $self->{rule}->{no_triple_yakuman} ) {
            $han = 200 if ( $han >= 200 );
        }

        my %result;

        if ( $han > 0 ) {
            $result{fu} = $max_fu;
            $result{han} = $han;
            $result{dora} = $dora;
            $result{yaku} = \@yaku;
            $result{tehai} = $max;

            return \%result;
        } else {
            $self->{errstr} = "No yaku";
            return undef;
        }
    } else {
        $self->log_( 0, "NO OK PATTERNS !!!" );
        $self->{errstr} = "Go-ron";
        return undef;
    }
}

# --------------------------------------------------------------------------
# 面子とみなせる牌の組み合わせを探す
#
# <INPUT>
#   $params      パラメータ
#     ->{kari}   現在残っている手牌の内容（ハッシュ）
# <OUTPUT>
#   $result
#     ->{m}      見つかった面子のリストへの参照
#     ->{mc}     見つかった面子の数
# --------------------------------------------------------------------------

sub search_mentsu
{
    my $self = shift;
    my $params = shift;

    my $kari = $params->{kari};
    my @kari_m;
    my $kari_mc = 0;
    my %result;

    # 基本的に刻子を優先して探す
    # p1p2p3p1p2p3p1p2p3 のように、刻子×3 とも 順子×3 とも見なせるケースについては
    # 別途対応する

    # 刻子を探す

    foreach my $p2 ( sort keys %{$kari} ) {
        if ( $kari->{$p2} >= 3 ) {
            # 刻子を見つけた

            $self->log_( 1, sprintf "  found kotsu %s", $p2 x 3 );
            push @kari_m, $p2 x 3;
            $kari->{$p2} -= 3;
            if ( $kari->{$p2} == 0 ) {
                delete $kari->{$p2};
            }
            $kari_mc ++;
        }
    }

    # 順子を探す

    foreach my $p2 ( sort keys %{$kari} ) {
        next if ( $p2 =~ /[z89]/ );

        while ( $kari->{$p2} > 0 ) {
            my ( $p2_2, $p2_3 ) = ( $p2, $p2 );
            $p2_2 =~ s/(\d)$/$1+1/e;
            $p2_3 =~ s/(\d)$/$1+2/e;
#            $self->log_( 1, sprintf "  search for %s%s%s ...", $p2, $p2_2, $p2_3 );
#            $self->debug_print( \%{$kari} );

            if ( defined( $kari->{$p2_2} ) && defined( $kari->{$p2_3} ) &&
                 $kari->{$p2_2} > 0 && $kari->{$p2_3} > 0 ) {
                # 順子を見つけた

                $self->log_( 1, sprintf "  found shuntsu %s", $p2 . $p2_2 . $p2_3 );
                push @kari_m, $p2 . $p2_2 . $p2_3;
                $kari->{$p2}--;
                $kari->{$p2_2}--;
                $kari->{$p2_3}--;

                $kari_mc++;
            } else {
                last;
            }
        }
    }

    $result{mc} = $kari_mc;
    $result{m} = \@kari_m;

    return \%result;
}

# --------------------------------------------------------------------------
# 泣きの内容が正しいかどうかをチェックする
#
# <INPUT>
#   $nm           泣き面子
# <OUTPUT>
#   $result       正しいかどうか（正しい=1）
# --------------------------------------------------------------------------

sub check_naki
{
    my $self = shift;
    my $nm = shift;

    return 0 if ( !defined( $nm ) );

    # 正しい面子とは、刻子、カン子、順子のいずれか。

    # 刻子またはカン子かどうか

    return 1 if ( $nm =~ /^([mps][1-9]|z[1-7])\1{2,3}-?$/ );

    # 順子かどうか
    # TODO: 順番が入れ替わっているケースをどうする？

    if ( $nm =~ /^([mps])([1-9])\1([1-9])\1([1-9])-?$/ ) {
        return 1 if ( $3 == $2 + 1 && $4 == $3 + 1 );
    }

    $self->log_( 0, "NG-NAKI: $nm" );
    return 0;
}


# --------------------------------------------------------------------------
# 符の計算をする（同時に平和判定）
#
# <INPUT>
#   $param        パラメータ
#     ->{pat}     あがり形の手牌のパターン
#     ->{agari}   あがり牌
#     ->{menzen}  面前かどうか（1=面前）
#     ->{tsumo}   ツモあがりかどうか（1=ツモ）
#     ->{jikaze}  自風（1=東/2=南/3=西/4=北）
#     ->{bakaze}  場風（1=東/2=南/3=西/4=北）
# --------------------------------------------------------------------------

sub calc_fu
{
    my $self = shift;
    my $param = shift;
    my $fuutei = 20; # 副底
    my $pinfu = 0;

    # 手牌

    my $fu_te = 0;

    my @m = split( ' ', $param->{pat} );

    foreach my $m ( @m ) {
        my $to = "[$param->{jikaze}$param->{bakaze}5-7]";

        if ( $m =~ /^(z$to)\1$/ ) {
            # 役牌の頭

            $self->log_( 1, sprintf "HEAD %s 2 fu", $m );

            $fu_te += 2;
            if ( $self->{rule}->{renpu_toitsu4} ) {
                if ( $param->{jikaze} eq $param->{bakaze} && $m =~ /^(z$param->{jikaze})\1$/ ) {
                    $fu_te += 2;
                }
            }
            next;
        }

        if ( $m =~ /^([mpsz]\d)\1\1(\1)?(-)?$/ ) {
            # 刻子または槓子

            my $p = $1;
            my $kan = ( defined( $2 ) ? 4 : 1 ); # 槓子
            my $an = ( !defined( $3 ) ? 2 : 1 ); # 暗刻 or 暗槓
            my $fu_mentsu;

            if ( $p =~ /[z19]/ ) {
                # ヤオ九牌
                $fu_mentsu = 4 * $kan * $an;
            } else {
                $fu_mentsu = 2 * $kan * $an;
            }

            $self->log_( 1, sprintf "MENTSU %s ( KAN : %s %d ) ( ANKO : %s %d ) %d fu",
                $m, $2 || '', $kan, $3 || '', $an, $fu_mentsu );

            $fu_te += $fu_mentsu;
        }
    }

    # menzen ron

    my $fu_menzen = 0;
    if ( $param->{menzen} && !$param->{tsumo} ) {
        $fu_menzen = 10;
    }

    # tsumo

    my $fu_tsumo = 0;
    if ( $param->{tsumo} ) {
        $fu_tsumo += 2;
    }

    # machi

    my $fu_machi = 0;
    my $machi_max = 0;
    my $machi_min = 2;

    $param->{agari} =~ m/([mpsz])(\d)/;
    my $kind = $1;
    my $num = $2;
    my $d_machi = $param->{agari} x 2; # tanki
    my $e_machi = ( $param->{agari} x 3 ) . '-?'; # shabo
    my $machi_max_str = '';
    my $machi_min_str = '';

    if ( $param->{agari} !~ /^z/ ) {
        if ( $num == 3 ) {
            $d_machi .= "|" . sprintf "%s1%s2%s3", $kind, $kind, $kind; # pen-chan
        } elsif ( $num == 7 ) {
            $d_machi .= "|" . sprintf "%s7%s8%s9", $kind, $kind, $kind; # pen-chan
        }
        if ( $num >= 2 && $num <= 8 ) {
            $d_machi .= "|" . sprintf "%s%d%s%d%s%d", $kind, $num - 1, $kind, $num, $kind, $num + 1; # kan-chan
        }
        if ( $num <= 6 ) {
            $e_machi .= "|" . sprintf "%s%d%s%d%s%d", $kind, $num, $kind, $num + 1, $kind, $num + 2; # ryan-men
        }
        if ( $num >= 4 ) {
            $e_machi .= "|" . sprintf "%s%d%s%d%s%d", $kind, $num - 2, $kind, $num - 1, $kind, $num; # ryan-men
        }
    }
    $self->log_( 1, "MACHI : $d_machi (DIFFICULT : fu=2) / $e_machi (EASY : fu=0)" );

    if ( $param->{pat} =~ /(\s|^)($d_machi)(\s|$)/ ) {
        $machi_max = 2;
        $machi_max_str = $2;
        $machi_max_str =~ s/($param->{agari})/<$1>/;
    }
    if ( $param->{pat} =~ /(\s|^)($e_machi)(\s|$)/ ) {
        $machi_min = 0;
        $machi_min_str = $2;
        $machi_min_str =~ s/($param->{agari})/<$1>/;
    }

    $self->log_( 1, sprintf "MACHI-FU : %d (%s) - %d (%s)", $machi_min, $machi_min_str, $machi_max, $machi_max_str );

    # pinfu hantei

    if ( $param->{menzen} && ( $fu_te == 0 ) && ( $machi_min == 0 ) ) {
        # pinfu

        $fu_machi = 0;
        $fu_tsumo = 0;
        $pinfu = 1;
    } else {
        $fu_machi = $machi_max;
    }

    # kui-pinfu kei

    if ( !$param->{menzen} && ( $fu_te == 0 ) && ( $machi_max == 0 ) && ( $fu_tsumo == 0 ) ) {
        $fu_te = 10;
    }

    my $fu_total = ( $fuutei + $fu_te + $fu_menzen + $fu_tsumo + $fu_machi);
    my $pinfu_name = ( $pinfu ? "(PINFU)" : "" );

    $self->log_( 1, sprintf "  符: 副底(%d) + 手牌(%d) + 面前ロン(%d) + ツモ(%d) + 待ち(%d) = %d %s",
           $fuutei, $fu_te, $fu_menzen, $fu_tsumo, $fu_machi, $fu_total, $pinfu_name );

    return ( $fu_total, $pinfu ) ;
}

# --------------------------------------------------------------------------
# 符を一桁目で切り上げる
# ただし、25 符（七対子）の場合はそのままにする
#
# <INPUT>
#   $fu          符
# <OUTPUT>
#                切り上げた符
# --------------------------------------------------------------------------

sub st_fu
{
    my $fu = shift;

    return ( $fu == 25 ? $fu : int( ( $fu + 9 ) / 10 ) * 10 );
}

# --------------------------------------------------------------------------
# 成立している役を調べる（平和以外）
# <INPUT>
#   $param        パラメータ
#     ->{tehai}   あがり形の面子ごとに分割した手牌
#     ->{menzen}  面前かどうか（1=面前）
#     ->{agari}   あがり牌
#     ->{reach}   リーチしたかどうか（1=リーチ、2=ダブルリーチ）
#     ->{ippatsu} リーチ一発かどうか（1=リーチ一発）
#     ->{tsumo}   ツモあがりかどうか
#     ->{jikaze}  自風（1=東/2=南/3=西/4=北）
#     ->{bakaze}  場風（1=東/2=南/3=西/4=北）
#     ->{haitei}  ハイテイツモかどうか
#     ->{rinshan} リンシャンツモかどうか
#     ->{chankan} チャンカンかどうか
#     ->{tenho}   天和／地和かどうか
# <OUTPUT>
#   \@yaku        成立した役のリスト
#   $han          成立した役のはん数（合計）
# --------------------------------------------------------------------------

sub check_yaku
{
    my $self = shift;
    my $param = shift;
    my @yaku;
    my $han = 0;

    # 手牌を並び替える

    my @mentsu = split( ' ', $param->{tehai} );
    my $head = shift @mentsu;
    $param->{tehai} = $head . ' ' . join( ' ', sort @mentsu );
    $self->log_( 1, "SORTED: $param->{tehai}" );

    # 天和・地和

    if ( $param->{menzen} && $param->{tsumo} && $param->{tenho} ) {
        if ( $param->{jikaze} eq 1 ) {
            push @yaku, "TENHO";
        } else {
            push @yaku, "CHIIHO";
        }
        $han += 100;
    }

    # 字一色

    if ( $param->{tehai} !~ /[mps]/ ) {
        push @yaku, "TSUU-II-SOU";
        $han += 100;
    }

    # 清老頭

    if ( $param->{tehai} !~ /[z2-8]/ ) {
        push @yaku, "CHIN-ROU-TOU";
        $han += 100;
    }

    # 大三元

    if ( $param->{tehai} =~ /z5z5z5/ &&  # HAKU
         $param->{tehai} =~ /z6z6z6/ &&  # HATSU
         $param->{tehai} =~ /z7z7z7/ ) { # CHUN
        push @yaku, "DAI-SAN-GEN";
        $han += 100;
    }

    # 大四喜・小四喜

#    if ( $param->{tehai} =~ /z1z1z1/ &&  # TON
#         $param->{tehai} =~ /z2z2z2/ &&  # NAN
#         $param->{tehai} =~ /z3z3z3/ &&  # SHAA
#         $param->{tehai} =~ /z4z4z4/ ) { # PEI
    if ( $param->{tehai} =~ /(z[1-4])\1(\1)?-? \s([\w-]+\s)?
                             (z[1-4])\4{2,3}-? \s([\w-]+\s)?
                             (z[1-4])\6{2,3}-? \s([\w-]+\s)?
                             (z[1-4])\8{2,3}-?/x ) {
        if ( defined( $2 ) ) {
            push @yaku, "DAI-SUU-SHII";
            if ( !$self->{rule}->{no_daisuushii_double} ) {
                $han += 200;
            } else {
                $han += 100;
            }
        } else {
            push @yaku, "SHOU-SUU-SHII";
            $han += 100;
        }
    }

    # 四暗刻

    if ( $param->{menzen} && 
         ( $param->{tehai} =~ /([mpsz]\d)\1{2,3} \s
                               ([mpsz]\d)\2{2,3} \s
                               ([mpsz]\d)\3{2,3} \s
                               ([mpsz]\d)\4{2,3}$/x ) ) {
        if ( $param->{tehai} =~ /^($param->{agari}){2}\s/ ) {
            push @yaku, "4-ANKO(TANKI)";
            if ( !$self->{rule}->{no_4anko_tanki_double} ) {
                $han += 200;
            } else {
                $han += 100;
            }
        } else {
            push @yaku, "4-ANKO";
            $han += 100;
        }
    }

    # 4-KANTSU

    if ( $param->{tehai} =~ /([mpsz]\d)\1{3}-? \s
                             ([mpsz]\d)\2{3}-? \s
                             ([mpsz]\d)\3{3}-? \s
                             ([mpsz]\d)\4{3}-?$/x ) {
        push @yaku, "4-KANTSU";
        if ( !$self->{rule}->{no_4kantsu_double} ) {
            $han += 200;
        } else {
            $han += 100;
        }
    }

    # 緑一色

    if ( $param->{tehai} =~ /^(s[23468]|z6|-|\s)+$/ ) {
        push @yaku, "RYUU-II-SOU";
        $han += 100;
    }

    # CHUU-REN-POU-TOU

    if ( $param->{menzen} ) {
        my $te = $param->{tehai};
#        $te =~ s/ //g;
        if ( $te =~ s/(([mps])[1])(.*)\1(.*)\1/$3$4/ &&
             $te =~ s/($2)[2]// &&
             $te =~ s/($1)[3]// &&
             $te =~ s/($1)[4]// &&
             $te =~ s/($1)[5]// &&
             $te =~ s/($1)[6]// &&
             $te =~ s/($1)[7]// &&
             $te =~ s/($1)[8]// &&
             $te =~ s/(($1)[9])(.*)\1(.*)\1/$3$4/ ) {

            if ( $te =~ /$param->{agari}/ ) {
                push @yaku, "CHUUREN-POTO(9men-chan)";
                if ( !$self->{rule}->{no_chuurenpoto9_double} ) {
                    $han += 200;
                } else {
                    $han += 100;
                }
            } else {
                push @yaku, "CHUUREN-POTO";
                $han += 100;
            }
        }
    }

    if ( $han >= 100 ) {
        # 役満ならもう調べる必要なし

        return ( \@yaku, $han )
    }

    # 役満以外

    # REACH / DOUBLE-REACH

    if ( $param->{menzen} && $param->{reach} ) {
        if ( $param->{reach} == 1 ) {
            push @yaku, "REACH";
            $han += 1;
        } else {
            push @yaku, "DOUBLE-REACH";
            $han += 2;
        }

        # IPPATSU

        if ( $param->{ippatsu} ) {
            push @yaku, "IPPATSU";
            $han += 1;
        }
    }

    # TSUMO

    if ( $param->{menzen} && $param->{tsumo} ) {
        push @yaku, "TSUMO";
        $han += 1;
    }

    # HAITEI

    if ( $param->{haitei} ) {
        push @yaku, "HAITEI";
        $han += 1;
    }

    # RINSHAN-KAIHO

    if ( $param->{rinshan} && $param->{tsumo} ) {
        if ( $param->{tehai} =~ /([mpsz]\d)\1{3}-?/ ) {
            push @yaku, "RINSHAN-KAIHO";
            $han += 1;
        }
    }

    # CHAN-KAN

    if ( $param->{chankan} ) {
        push @yaku, "CHANKAN";
        $han += 1;
    }

    # TAN-YAO

    if ( $param->{tehai} !~ /[mps][19]|z/ ) {
        if ( $param->{menzen} || $self->{rule}->{kuitan} ) {
            push @yaku, "TAN-YAO";
            $han += 1;
        }
    }

    # FAN-PAI

    while ( $param->{tehai} =~ /(z([$param->{jikaze}$param->{bakaze}5-7]))\1\1/g ) {
        if ( ( $param->{jikaze} == $param->{bakaze} ) && ( $param->{jikaze} == $2 ) ) {
            push @yaku, "DOUBLE-$ji_name{$2}";
            $han += 2;
        } else {
            push @yaku, $ji_name{$2};
            $han += 1;
        }
    }

    # II-PEI-KO / RYAN-PEI-KO

    if ( $param->{menzen} ) {
        my $hei_ko = 0;
        while ( $param->{tehai} =~ /(([mps])(\d)\2(\d)\2(\d)) \s \1/xg ) {
            if ( $4 == $3 + 1 && $5 == $4 + 1 ) {
                $hei_ko ++;
            }
        }
        if ( $hei_ko == 1 ) {
            push @yaku, "II-PEI-KO";
            $han += 1;
        } elsif ( $hei_ko == 2 ) {
            push @yaku, "RYAN-PEI-KO";
            $han += 3;
        }
    }

    # 3-SHOKU

    if ( $param->{tehai} =~ /m(\d)m(\d)m(\d)-? \s([\w-]+\s)?
                             p \1 p \2 p \3-? \s([\w-]+\s)?
                             s \1 s \2 s \3-?/x ) {
        if ( $2 == $1 + 1 && $3 == $2 + 1 ) {
            push @yaku, "3-SHOKU";
            $han += ( $param->{menzen} ? 2 : 1 );
        }
    }

    # 1-TSUU

    if ( $param->{tehai} =~ /([mps])[1]\1[2]\1[3]-? \s([\w-]+\s)?
                                \1  [4]\1[5]\1[6]-? \s([\w-]+\s)?
                                \1  [7]\1[8]\1[9]-?/x ) {
        push @yaku, "1-TSUU";
        $han += ( $param->{menzen} ? 2 : 1 );
    }

    # CHANTA / JUN-CHAN

    if ( $param->{tehai} =~ /[mps][2-37-8]/ ) {
        my $chanta = 1;
        my $jun_chan = 1;
        foreach my $m ( split( ' ', $param->{tehai} ) ) {
            if ( $m !~ /[mps][19]/ ) {
                if ( $m !~ /z/ ) {
                    $chanta = $jun_chan = 0;
                    last;
                } else {
                    $jun_chan = 0;
                }
            }
        }

        if ( $jun_chan ) {
            push @yaku, "JUN-CHAN";
            $han += ( $param->{menzen} ? 3 : 2 );
        } elsif ( $chanta ) {
            push @yaku, "CHANTA";
            $han += ( $param->{menzen} ? 2 : 1 );
        }
    }

    # TOI-TOI-HOU

    if ( $param->{tehai} =~ /([mpsz]\d)\1{2,3}-? \s
                             ([mpsz]\d)\2{2,3}-? \s
                             ([mpsz]\d)\3{2,3}-? \s
                             ([mpsz]\d)\4{2,3}-?/x ) {
        push @yaku, "TOI-TOI-HOU";
        $han += 2;
    }

    # 3-ANKO

    if ( $param->{tehai} =~ /([mpsz]\d)\1{2,3} \s([\w-]+\s)?
                             ([mpsz]\d)\3{2,3} \s([\w-]+\s)?
                             ([mpsz]\d)\5{2,3} (\s|$)/x ) {
        push @yaku, "3-ANKO";
        $han += 2;
    }

    # HON-ROU-TOU

    if ( $param->{tehai} !~ /[mps][2-8]/ ) {
        push @yaku, "HON-ROU-TOU";
        $han += 2;
    }

    # 3-SHOKU-DOUKOU

    if ( $param->{tehai} =~ /m(\d)m\1m\1(m\1)?-? \s([\w-]+\s)?
                             p \1 p\1p\1(p\1)?-? \s([\w-]+\s)?
                             s \1 s\1s\1(s\1)?-? (\s|$)/x ) {
        push @yaku, "3-SHOKU-DOUKOU";
        $han += 2;
    }

    # 3-KANTSU

    if ( $param->{tehai} =~ /([mpsz]\d)\1{3}-? \s([\w-]+\s)?
                             ([mpsz]\d)\3{3}-? \s([\w-]+\s)?
                             ([mpsz]\d)\5{3}-?/x ) {
        push @yaku, "3-KANTSU";
        $han += 2;
    }

    # SHOU-SAN-GEN

    if ( $param->{tehai} =~ /(z[5-7])\1 \s([\w-]+\s)+?
                             (z[5-7])\3{2,3}-? \s([\w-]+\s)?
                             (z[5-7])\5{2,3}-?/x ) {
        push @yaku, "SHOU-SAN-GEN";
        $han += 2;
    }

    # HON-ITSU / CHIN-ITSU

    if ( $param->{tehai} =~ /[mps]/ && 
         ( $param->{tehai} !~ /[mp]/ || $param->{tehai} !~ /[ms]/ || $param->{tehai} !~ /[sp]/ ) ) {
        if ( $param->{tehai} =~ /z/ ) {
            push @yaku, "HON-ITSU";
            $han += ( $param->{menzen} ? 3 : 2 );
        } else {
            push @yaku, "CHIN-ITSU";
            $han += ( $param->{menzen} ? 6 : 5 );
        }
    }

    return ( \@yaku, $han );
}

# --------------------------------------------------------------------------
# 点数の計算
#
# <INPUT>
#   $fu          符
#   $han
#   $oya
#   $tsumo
# --------------------------------------------------------------------------
sub calc_score
{
    my $self = shift;
    my ( $fu, $han, $oya, $tsumo ) = @_;

    $self->{errstr} = "";
    my $base = st_fu( $fu ) * ( 2 ** ( 2 + $han ) );

    if ( $fu == 0 || $base >= 2000 ) {
        if ( $han <= 5 ) {
            $base = 2000; # Mangan
        } elsif ( $han <= 7 ) {
            $base = 3000; # Hane-man
        } elsif ( $han <= 10 ) {
            $base = 4000; # Bai-man
        } elsif ( $han <= 12 ) {
            $base = 6000; # 3-bai-man
        } elsif ( $han < 200 ) {
            $base = 8000; # Yaku-man
        } elsif ( $han < 300 ) {
            $base = 16000; # Double-yaku-man
        } else {
            $base = 24000; # Triple-yaku-man
        }
    }

    if ( $self->{rule}->{no_double_yakuman} ) {
        $base = 8000 if ( $base >= 8000 );
    }
    if ( $self->{rule}->{no_triple_yakuman} ) {
        $base = 16000 if ( $base >= 16000 );
    }

    my %score;

    if ( $oya ) {
        # oya
        if ( $tsumo ) {
            $score{all} = st_score( $base * 2 );
        } else {
            $score{ron} = st_score( $base * 6 );
        }
    } else {
        # ko
        if ( $tsumo ) {
            $score{ko}  = st_score( $base * 1 );
            $score{oya} = st_score( $base * 2 );
        } else {
            $score{ron} = st_score( $base * 4 );
        }
    }

    return \%score;
}

sub st_score
{
    my $score = shift;

    return ( int( ( $score + 99 ) / 100 ) * 100 );
}

# --------------------------------------------------------------------------
# エラーメッセージの取得
#
# <INPUT>
#   none
# <OUTPUT>
#   直前に起きたエラーの内容
# --------------------------------------------------------------------------

sub errstr
{
    my $self = shift;

    return $self->{errstr};
}

# --------------------------------------------------------------------------
# 残っている牌の種類と枚数を表示する（デバッグ用ルーチン）
#
# <INPUT>
#   $kari        残っている牌のハッシュへの参照
# <OUTPUT>
#   なし
# --------------------------------------------------------------------------

sub debug_print
{
    my $self = shift;
    my $kari = shift;

    my $msg = '';

    foreach my $p ( sort keys %{$kari} ) {
        $msg .= "$p ($kari->{$p}) ";
    }
    $self->log_( 2, $msg );
}

# --------------------------------------------------------------------------
# ログを出力する
# デバッグレベルによっては、標準出力へログを出力する
#
# <INPUT>
#   $level       メッセージのレベル（デバッグレベル以下であれば出力される）
#   $msg         ログに出力するメッセージ
# <OUTPUT>
#   なし
# --------------------------------------------------------------------------

sub log_
{
    my $self = shift;
    my ( $level, $msg ) = @_;

    if ( $level <= $self->{DEBUG} ) {
#        print STDOUT "$msg\n";
    }
    my $logfile = $self->{logfile};
    print $logfile "$msg\n" if ( defined( $logfile ) );
}

1;

__END__

=head1 NAME

MG - Marjang calculator written in Perl

=head1 VERSION

Version 0.01

=cut

