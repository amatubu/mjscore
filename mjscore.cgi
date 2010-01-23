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

open my $log, ">result.log";

MG::init( $log );

print 
    $cgi->header,
    $cgi->start_html( -title=>'Simple Test CGI', -lang=>'ja-JP' ),
    $cgi->h1( 'Simple Test CGI' ),
    $cgi->start_form,
    "手牌? ", $cgi->textfield( -name=>'te', -size=>50, -default=>'p1p1p2p3p4p4p4z5z5z5z6z6z6 p4' ), $cgi->p,
    "あがり牌? ", $cgi->textfield( -name=>'agari', -size=>3 ), $cgi->p,
    "泣き? ", $cgi->textfield( -name=>'naki', -size=>40 ), $cgi->p,
    "自風? ", $cgi->popup_menu( -name=>'jikaze', -values=>[1,2,3,4], -labels=>\%labels ), $cgi->p,
    "場風? ", $cgi->popup_menu( -name=>'bakaze', -values=>[1,2,3,4], -labels=>\%labels ), $cgi->p,
    $cgi->submit,
    $cgi->end_form,
    $cgi->hr,"\n";

if ($cgi->param) {
    my %test;

    $test{'te'} = $cgi->param( 'te' );
    $test{'agari'} = $cgi->param( 'agari' );
    $test{'naki'} = $cgi->param( 'naki' );
    $test{'jikaze'} = $cgi->param( 'jikaze' );
    $test{'bakaze'} = $cgi->param( 'bakaze' );

    my $result = MG::check( \%test );

    if ( $result ) {
        print "Yaku is ", join( ' ', @{$result->{yaku}} ), $cgi->p;
        print MG::st_fu( $result->{fu} ), " fu ", $result->{han}, " han ", $cgi->p;
        print "Your agari-kei is ", print_image( $cgi, $result->{'tehai'} ), $cgi->p;

        # score

        my $score = MG::calc_score(
            $result->{fu},
            $result->{han},
            ( $cgi->param( 'jikaze' ) == 1 ),
            $test{tsumo},
        );

        print "Score is ", ( $score->{ron} ? "$score->{ron} (ron)" : ( $score->{ko} ? "$score->{ko} (ko) $score->{oya} (oya)" : "$score->{all} all" ) ), $cgi->p;
    } else {
        print "ERROR!", $cgi->p,
    }
    print $cgi->hr,"\n";

    print
        "Your te is ", print_image( $cgi, $cgi->param('te') ),$cgi->p,
        "Your agari is ", print_image( $cgi, $cgi->param('agari') ), $cgi->p,
        "Your naki is ", print_image( $cgi, $cgi->param('naki') ), $cgi->p,
        "Your kaze is ",$cgi->img( { src => "images/" . $labels{$cgi->param('jikaze')} . ".gif" }),$cgi->p,
        "Ba's kaze is ",$cgi->img( { src => "images/" . $labels{$cgi->param('bakaze')} . ".gif" }),$cgi->p,
}
print $cgi->end_html;


close $log;

exit 0;

# 画像ファイルを表示する

sub print_image
{
    my ( $cgi, $te ) = @_;

    my $result = '';

    foreach my $m ( split( ' ', $te ) ) {
        if ( $m =~ /^([mps][1-9]|z[1-7])\1\1\1$/ ) {
            $result .= $cgi->img( { src => "images/$images{$1}.gif" } ) .
                       $cgi->img( { src => "images/ura.gif" } ) x 2 .
                       $cgi->img( { src => "images/$images{$1}.gif" } );
        } else {
            while ( $m =~ /([mps][1-9]-?|z[1-7]-?|[\s])/g ) {
                my $hai = $1;
                $hai =~ s/(..)(.)?/$1/;
                my $yoko = ( defined( $2 ) ? 'y' : '' );
                $result .= $cgi->img( { src => "images/$yoko$images{$hai}.gif" } );
            }
        }
        $result .= "&nbsp;"
    }

    return $result;
}

1;
