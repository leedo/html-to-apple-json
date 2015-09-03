package HtmlToApple::Component::Heading;

use Moo;

extends "HtmlToApple::Component::Markdown";

sub type { "Heading" }
sub allowed_tags { qw{b em strong i} };

1;
