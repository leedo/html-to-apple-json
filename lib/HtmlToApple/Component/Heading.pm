package HtmlToApple::Component::Heading;

use v5.14;
use strict;
use warnings;

use Moo;
use List::Util qw{any first sum};

extends "HtmlToApple::Component::Text";

sub type { "Heading" }

1;
