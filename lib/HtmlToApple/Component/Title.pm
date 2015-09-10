package HtmlToApple::Component::Title;

use Moo;

extends "HtmlToApple::Component::Markdown";

sub allowed_tags { qw{b em strong i} };

sub role { "title" }

1;
