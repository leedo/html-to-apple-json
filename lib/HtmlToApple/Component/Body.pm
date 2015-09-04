package HtmlToApple::Component::Body;

use Moo;

extends "HtmlToApple::Component::Markdown";

sub allowed_tags {
  qw{p ol ul li blockquote pre code a hr b em strong i}
}

sub concat {
  my ($self, $comp) = @_;
  push @{$self->html}, @{$comp->html};
}

1;
