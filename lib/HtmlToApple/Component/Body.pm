package HtmlToApple::Component::Body;

use Moo;

extends "HtmlToApple::Component::HTML";

sub type { "Body" }

sub concat {
  my ($self, $comp) = @_;
  push @{$self->html}, @{$comp->html};
}

1;
