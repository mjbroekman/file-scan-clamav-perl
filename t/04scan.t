use strict;
use Test;
BEGIN { plan tests => 8 }
use File::Scan::ClamAV;
use Cwd;

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

my $av = new File::Scan::ClamAV(port => "clamsock", find_all => 1); 
ok($av);   

my $dir = cwd;
ok($dir);

my $testdir = "$dir/testfiles";
ok(-d $testdir);
print "# Scanning $testdir\n";
my %results = $av->scan($testdir);

print "# Results: ", (map { "$_ => $results{$_}, " } keys(%results)), "\n";
ok(exists($results{"$testdir/clamavtest"}), 1, "Didn't detect $testdir/clamavtest");
ok(exists($results{"$testdir/clamavtest.zip"}), 1, "Didn't detect $testdir/clamavtest.zip");
ok(exists($results{"$testdir/clamavtest.gz"}), 1, "Didn't detect $testdir/clamavtest.gz");
ok(!exists($results{"$testdir/innocent"}), 1, "Accidentally detected $testdir/innocent file");

ok(kill(9 => $pid), 1);
waitpid($pid, 0);
unlink("clamsock");

