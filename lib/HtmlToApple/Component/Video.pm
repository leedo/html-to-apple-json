package HtmlToApple::Component::Video;

use Moo;

extends "HtmlToApple::Component";

has "open" => (is => "rw", default => sub {0});
has "caption" => (is => "rw");

sub as_data {
  my ($self) = @_;
  return {
    caption => $self->caption,
    type => $self->type,
  }
}

1;
