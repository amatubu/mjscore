#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Encode;
use CGI qw( -no_xhtml );

use MG;


my %images = (
    'p1' => 'pin1', 'p2' => 'pin2', 'p3' => 'pin3', 'p4' => 'pin4',
    'p5' => 'pin5', 'p6' => 'pin6', 'p7' => 'pin7', 'p8' => 'pin8',
    'p9' => 'pin9',
    'm1' => 'man1', 'm2' => 'man2', 'm3' => 'man3', 'm4' => 'man4',
    'm5' => 'man5', 'm6' => 'man6', 'm7' => 'man7', 'm8' => 'man8',
    'm9' => 'man9',
    's1' => 'sou1', 's2' => 'sou2', 's3' => 'sou3', 's4' => 'sou4',
    's5' => 'sou5', 's6' => 'sou6', 's7' => 'sou7', 's8' => 'sou8',
    's9' => 'sou9',
    'z1' => 'ton',  'z2' => 'nan',  'z3' => 'sha',  'z4' => 'pei',
    'z5' => 'haku', 'z6' => 'hatu', 'z7' => 'tyun',
);

my $image_prefix = "images/";
my $image_suffix = "u.gif";

binmode( STDIN,  ":utf8" );
binmode( STDOUT, ":utf8" );
binmode( STDERR, ":utf8" );

my %labels = (
    1 => 'ton',
    2 => 'nan',
    3 => 'sha',
    4 => 'pei',
);

my $cgi = new CGI;
$cgi->charset( 'utf-8' );

print 
    $cgi->header,
    $cgi->start_html(
        -title => 'Simple Test CGI',
        -lang  => 'ja-JP',
        -meta  => { 'viewport' => 'width = device-width' }, ),
#    $cgi->h3( 'Simple Test CGI' ),
    $cgi->start_form,
    "手牌: ", $cgi->br, $cgi->textfield(
        -name    => 'te',
        -size    => 45,
        -default =>'p1p1p2p3p4p4p4z5z5z5z6z6z6 p4' ), $cgi->br,
    "自風: ", $cgi->radio_group(
        -name   => 'jikaze',
        -values => [ 1, 2, 3, 4 ],
        -labels => \%labels ), $cgi->br,
    "場風: ", $cgi->radio_group(
        -name   => 'bakaze',
        -values => [ 1, 2, 3, 4 ],
        -labels => \%labels ), $cgi->br,
    "ドラ: ", $cgi->textfield(
        -name => 'dora',
        -size => 10, ), $cgi->br,
    $cgi->checkbox( 'reach' ), $cgi->checkbox( 'double-reach' ), $cgi->checkbox( 'ippatsu' ), $cgi->br,
    $cgi->checkbox( 'tsumo' ), $cgi->checkbox( 'haitei' ), $cgi->br,
    $cgi->checkbox( 'rinshan' ), $cgi->checkbox( 'chankan' ), $cgi->br,
    $cgi->checkbox( -name => 'tenho', -label => 'tenho/chiiho', ), $cgi->br,

    $cgi->submit,
    $cgi->end_form,
    $cgi->hr,"\n";

if ($cgi->param) {
    open my $log, ">result.log";

    my $mjc = MG->new( 'logfile' => $log );

    my %test = (
        'te'      => $cgi->param( 'te' ),
        'jikaze'  => $cgi->param( 'jikaze' ),
        'bakaze'  => $cgi->param( 'bakaze' ),
        'dora'    => $cgi->param( 'dora' ),
        'reach'   => ( $cgi->param( 'double-reach' ) eq 'on' ? 2 :
                     ( $cgi->param( 'reach' ) eq 'on' ? 1 : 0 ) ),
        'tsumo'   => ( $cgi->param( 'tsumo' ) eq 'on' ),
        'ippatsu' => ( $cgi->param( 'ippatsu' ) eq 'on' ),
        'haitei'  => ( $cgi->param( 'haitei' ) eq 'on' ),
        'rinshan' => ( $cgi->param( 'rinshan' ) eq 'on' ),
        'chankan' => ( $cgi->param( 'chankan' ) eq 'on' ),
        'tenho'   => ( $cgi->param( 'tenho' ) eq 'on' ), );

    my $result = $mjc->check( \%test );

    if ( $result ) {
        print "Yaku is ", join( ' ', @{$result->{yaku}} ), $cgi->br;
        print MG::st_fu( $result->{fu} ), " fu ", $result->{han}, " han ", $cgi->p;
        print "Your agari-kei is ", $cgi->br,
              print_image( $cgi, $result->{'tehai'} ), $cgi->p;

        # score

        my $score = $mjc->calc_score(
            $result->{fu},
            $result->{han},
            ( $cgi->param( 'jikaze' ) == 1 ),
            $test{tsumo},
        );

        print "Score is ",
              ( $score->{ron} ? "$score->{ron} (ron)" :
                                ( $score->{ko} ? "$score->{ko} (ko) $score->{oya} (oya)" :
                                                 "$score->{all} all" ) ), $cgi->br;
    } else {
        print "ERROR!", $cgi->br,
    }
    print $cgi->hr,"\n";

    print
        "Your te is ", $cgi->br, print_image( $cgi, $cgi->param('te') ), $cgi->br,
        "Your kaze is ", $cgi->img( { src => get_image_path( $labels{$cgi->param('jikaze')} ) } ), $cgi->br,
        "Ba's kaze is ", $cgi->img( { src => get_image_path( $labels{$cgi->param('bakaze')} ) } ), $cgi->br,

    close $log;
}
print $cgi->end_html;


exit 0;

# 画像ファイルを表示する

sub print_image
{
    my ( $cgi, $te ) = @_;

    my $result = '';

    foreach my $m ( split( ' ', $te ) ) {
        if ( $m =~ /^([mps][1-9]|z[1-7])\1\1\1$/ ) {
            $result .= $cgi->img( { src => get_image_path( $images{$1} ) } ) .
                       $cgi->img( { src => get_image_path( "ura" ) } ) x 2 .
                       $cgi->img( { src => get_image_path( $images{$1} ) } );
        } else {
            while ( $m =~ /([mps][1-9]-?|z[1-7]-?|[\s])/g ) {
                my $hai = $1;
                $hai =~ s/(..)(.)?/$1/;
                my $yoko = ( defined( $2 ) ? 'y' : '' );
                $result .= $cgi->img( { src => get_image_path( "$yoko$images{$hai}" ) } );
            }
        }
        $result .= "&nbsp;"
    }

    return $result;
}

sub get_image_path
{
    my $name = shift;

    return "$image_prefix$name$image_suffix";
}

1;
