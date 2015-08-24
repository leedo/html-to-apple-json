package HtmlToApple::Component::Quote;

use v5.14;
use strict;
use warnings;

use Moo;
use List::Util qw{any first sum};

extends "HtmlToApple::Component::Text";

sub type { "Quote" }

1;
