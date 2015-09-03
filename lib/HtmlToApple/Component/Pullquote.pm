package HtmlToApple::Component::Pullquote;

use Moo;

extends "HtmlToApple::Component::HTML";

sub type { "Pullquote" }
sub allowed_tags { qw{b em strong i} };

1;
