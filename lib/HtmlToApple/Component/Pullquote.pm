package HtmlToApple::Component::Pullquote;

use Moo;

extends "HtmlToApple::Component::Markdown";

sub allowed_tags { qw{b em strong i} };

sub role { "pullquote" }

1;
