package HtmlToApple::Component::Empty;

use v5.14;
use strict;
use warnings;

use Moo;

extends "HtmlToApple::Component";

has open => (is => "ro", default => sub {0});

sub type { "Empty" }

1;
