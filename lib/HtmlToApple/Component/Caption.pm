package HtmlToApple::Component::Caption;

use parent "HtmlToApple::Component::Markdown";

sub type { "Caption" }
sub allowed_tags { qw{b em strong i} };

1;
