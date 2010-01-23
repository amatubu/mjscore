use strict;
use warnings;
use Test::More tests => 3;

use MG;

my $logfile;
my $line;

# ログファイルを開く

open $logfile, '>:encoding(euc-jp)', "g2.log";

# STDOUT を保存

#open my $old_stderr, ">&STDOUT";
#open STDOUT, ">temp.tmp";

# 初期化せずにログ出力

my $mjc = MG->new( 'debug' => 0, 'logfile' => undef );
$mjc->log_( 0, "test" );
#MG::log_( 0, "test" );

# 標準出力に出力されたログをチェックする

#close STDOUT;
#open TEMP, "+<temp.tmp";
#$line = <TEMP>;
#close TEMP;
#unlink 'temp.tmp';

#is( $line, "test\n", "log message" );

# ログファイルにログが出力されていないことを確認する

ok( -z "g2.log" );

# 初期化

#open STDOUT, ">temp.tmp";
$mjc = MG->new( 'debug' => 0, 'logfile' => $logfile );
#MG::init( $logfile );

# 初期化後にログ出力

$mjc->log_( 0, "test2" );
#MG::log_( 0, "test2" );

# ログファイルに出力されたログをチェックする

close $logfile;
ok( !-z "g2.log" );

open $logfile, "+<g2.log";
$line = <$logfile>;
close $logfile;
#unlink "g.log";

is( $line, "test2\n", "log message2" );

# 標準出力に出力されたログをチェックする

#close STDOUT;
#sleep 1;
#open TEMP, "+<temp.tmp";
#$line = <TEMP>;

#is( $line, "test2\n", "log message2" );

#close TEMP;
#unlink 'temp.tmp';

# Restore STDERR

#open STDOUT, ">&", $old_stderr;
