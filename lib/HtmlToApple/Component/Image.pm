package HtmlToApple::Component::Image;

use v5.14;
use strict;
use warnings;

use Moo;
use List::Util qw{any first sum};

extends "HtmlToApple::Component";

sub type { "Image" }

1;
