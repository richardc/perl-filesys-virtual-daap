#!perl -w
use lib 'lib', "$ENV{HOME}/hck/acme-svn/Net-DAV-Server/lib",
  "$ENV{HOME}/lab/perl/Net-DAAP-Client-Auth/lib";
use strict;
use warnings;
use Cwd;
use HTTP::Daemon;
use Net::DAV::Server;
use Filesys::Virtual::DAAP;

$| = 1;

#my $filesys = Filesys::Virtual::Plain->new({root_path => cwd});
my $filesys = Filesys::Virtual::DAAP->new({ host      => 'localhost',
                                            root_path => '/',
                                            cwd       => '/' });
my $webdav = Net::DAV::Server->new();
$webdav->filesys($filesys);

my $d = HTTP::Daemon->new( LocalAddr => 'localhost',
                           LocalPort => 4242, ReuseAddr => 1) || die;
print "Please contact me at: <URL:", $d->url, ">\n";
while (my $c = $d->accept) {
    while (my $request = $c->get_request) {

        #die if $request->header('X-Litmus') =~ 'copymove: 5';
        warn '[' . $request->method . " " . $request->uri . "]\n";
        #print $request->as_string;
        my $response = $webdav->run($request);
        $c->send_response ($response);
        #  print "Response:\n" . $response->as_string . "\n";
    }
    $c->close;
    undef($c);
}

