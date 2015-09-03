package HtmlToApple::Component::Caption;

use Moo;

extends "HtmlToApple::Component::HTML";

sub type { "Caption" }
sub allowed_tags { qw{b em strong i} };

1;
