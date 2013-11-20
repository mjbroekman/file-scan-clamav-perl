use strict;
use Test;
use constant SKIP => 0; # $^O eq 'linux';
BEGIN { plan tests => SKIP ? 0 : 4 }
SKIP and print "# Skipping - clamd too broken on linux\n";
use File::Scan::ClamAV;
use POSIX ":sys_wait_h";
SKIP and exit(0);

do "t/mkconf.pl";

# start clamd
my $pid = fork;
die "Fork failed" unless defined $pid;
if (!$pid) {
    exec "$ENV{CLAMD_PATH}/clamd -c clamav.conf";
    die "clamd failed to start: $!";
}

for (1..10) {
  last if (-e "clamsock");
  if (kill(0 => $pid) == 0) {
    die "clamd appears to have died";
  }
  sleep(1);
}

my $av = new File::Scan::ClamAV(port => "clamsock"); 
ok($av);

ok($av->quit);
sleep(1);
ok($av->ping, undef, "Ping succeeded after quit");


$SIG{ALRM} = sub { kill(9 => $pid); };

alarm(5);
1 while(waitpid($pid, &WNOHANG) != -1);

ok(kill(9 => $pid), 0);
unlink("clamsock");
