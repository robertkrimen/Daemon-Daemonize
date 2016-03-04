#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;

use Path::Class qw/ tempdir /;
use Daemon::Daemonize;

my $shibboleth = $$ + substr int( rand time ), 6;
my $dollar_0 = "d-d-test-$shibboleth";

my $tmpdir = tempdir(CLEANUP=>1);
my $pid_file = $tmpdir->file($shibboleth)->absolute;
my $stdout_file = $tmpdir->file("stdout")->absolute;
my $stderr_file = $tmpdir->file("stderr")->absolute;
my $want_umask = oct('0027');

Daemon::Daemonize->daemonize(
	umask => $want_umask,
	stdout => $stdout_file,
	stderr => $stderr_file,
	run => sub {
		local $0 = $dollar_0;
		Daemon::Daemonize->write_pidfile($pid_file);
		print STDOUT sprintf("%04o",umask);
		print STDERR "I am stderr";
		sleep 10;
	}
);

sleep 1;

my $pid = Daemon::Daemonize->check_pidfile($pid_file);
ok $pid, "checked pid $pid";

my $umask = $stdout_file->slurp;
is $umask, '0027', "umask $umask is correct";

is $stderr_file->slurp, "I am stderr", "stderr file is correct";

my    $pid_mode =    $pid_file->stat->mode;
ok( (   $pid_mode&$want_umask)==0, sprintf("   PID file mode %o is masked ok",    $pid_mode) );
my $stdout_mode = $stdout_file->stat->mode;
ok( ($stdout_mode&$want_umask)==0, sprintf("STDOUT file mode %o is masked ok", $stdout_mode) );
my $stderr_mode = $stderr_file->stat->mode;
ok( ($stderr_mode&$want_umask)==0, sprintf("STDERR file mode %o is masked ok", $stderr_mode) );

done_testing;
