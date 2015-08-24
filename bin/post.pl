#!/usr/bin/env perl

use LWP::UserAgent;
use Encode;

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(POST => "http://localhost:5000/");
$req->header("Content-Type", "application/octet-stream");

{
  local $/;
  open(my $fh, "<:raw", $ARGV[0]) or die $!;
  $req->content(<$fh>);
}

my $res = $ua->request($req);
print $res->content;
