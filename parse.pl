#!/usr/bin/env perl

use HtmlToApple;

my $h = HtmlToApple->new;
open(my $fh, "<:utf8", $ARGV[0]) || die;

$h->parse($_) while (<$fh>);
$h->dump;
