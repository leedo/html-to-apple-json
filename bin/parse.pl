#!/usr/bin/env perl

use JSON;
use HtmlToApple;

my $h = HtmlToApple->new;
open(my $fh, "<:utf8", $ARGV[0]) || die;

$h->parse($_) while (<$fh>);
$h->eof;

print JSON->new->utf8->pretty->encode($h->dump);
