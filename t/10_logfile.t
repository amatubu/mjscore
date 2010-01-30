use strict;
use warnings;
use Test::More tests => 3;

use MG;

my $logfile;
my $line;

# ログファイルを開く

open $logfile, '>:encoding(euc-jp)', "g.log";

# 初期化せずにログ出力

my $mjc = MG->new( 'debug' => 0, 'logfile' => undef );
$mjc->log_( 0, "test" );

# ログファイルにログが出力されていないことを確認する

ok( -z "g.log" );

# 初期化

$mjc = MG->new( 'debug' => 1, 'logfile' => $logfile );

# 初期化後にログ出力

$mjc->log_( 0, "test2" );

# ログファイルに出力されたログをチェックする

close $logfile;
ok( !-z "g.log" );

open $logfile, "+<g.log";
$line = <$logfile>;
close $logfile;
unlink "g.log";

is( $line, "test2\n", "log message2" );

