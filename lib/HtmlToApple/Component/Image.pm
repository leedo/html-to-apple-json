package HtmlToApple::Component::Image;

use strict;
use warnings;

use Moo;

extends "HtmlToApple::Component";

has "open" => (is => "rw", default => sub {0});

sub allowed_attr { ["src", "width", "height"] }
sub type { "Image" }

1;
