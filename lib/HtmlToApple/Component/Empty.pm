package HtmlToApple::Component::Empty;

use Moo;

extends "HtmlToApple::Component";

has open => (is => "ro", default => sub {0});

sub type { "Empty" }

1;
