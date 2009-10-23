#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Daemon::Daemonize;

my $shibboleth = $$ + substr int( rand time ), 6;
my $dollar_0 = "d-d-test-$shibboleth";

Daemon::Daemonize->launch_daemon (sub {
    $0 = $dollar_0;
    for( 0 .. 7 ) {
        print "Hello, World.\n";
        sleep 8;
    }
} );

my ($pid);

$pid = `pgrep -f $dollar_0`;
ok( $pid );

diag( "Found $pid" );

kill INT => $pid;
$pid = `pgrep -f $dollar_0`;
ok( ! $pid );

ok( 1 );

1;
