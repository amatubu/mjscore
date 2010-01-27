use strict;
use warnings;
use Test::More tests => 2;

use MG;

my $mjc = MG->new( debug => 0 );
ok( defined $mjc, "MG->new" );
is( ref $mjc, 'MG', "ref MG->new" );

1;
