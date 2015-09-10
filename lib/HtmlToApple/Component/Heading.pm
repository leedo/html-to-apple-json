package HtmlToApple::Component::Heading;

use Moo;

extends "HtmlToApple::Component::Markdown";

sub allowed_tags { qw{b em strong i} };

sub role { "heading" }

1;
