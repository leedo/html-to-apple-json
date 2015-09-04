package HtmlToApple::Component::Caption;

use parent "HtmlToApple::Component::Markdown";

sub allowed_tags { qw{b em strong i} };

1;
