package HtmlToApple::Component::Pullquote;

use Moo;

extends "HtmlToApple::Component::Markdown";

sub type { "Pullquote" }
sub allowed_tags { qw{b em strong i} };

1;
