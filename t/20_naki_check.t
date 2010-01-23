use strict;
use warnings;
use Test::More;

use MG;

my @ok_tests = (
    "p1p1p1",
    "p1p2p3-",
    "z1z1z1",
    "s8s8s8s8",
    "m1m1m1m1-",
    "p3p4p5",
);

my @ng_tests = (
    "p1p1p2",
    "p2p2p3-",
    "z1z2z3",
    "p1s1m1-",
    "a1a2a3",
    "p1p2p3p4",
    "z1z1z1z1z1",
    "p0p1p2",
    "z8z8z8-",
    "s0s0s0",
    "m9m0m1",
    "s8s9s1-",
    "p9p1p2",

    undef,
    'p',
    '5',
    'm2',
    'p8-',
    'p3p3',
    's3s4',
    'z1z',
    'z6z6z',

    "p2p3p1", # TODO
);

plan tests => @ok_tests + @ng_tests;

my $mjc = MG->new;

foreach my $nm ( @ok_tests ) {
    ok(  $mjc->check_naki( $nm ), sprintf "NAKI(OK): %s", $nm || '<undef>' );
}

foreach my $nm ( @ng_tests ) {
    ok( !$mjc->check_naki( $nm ), sprintf "NAKI(NG): %s", $nm || '<undef>' );
}

exit 0;
