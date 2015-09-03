package HtmlToApple::Component::Image;

use Moo;

extends "HtmlToApple::Component";

has "open" => (is => "rw", default => sub {0});
has "caption" => (is => "rw");

sub type { "Image" }

sub as_data {
  my ($self) = @_;
  return {
    width => $self->attr->{width},
    height => $self->attr->{height},
    src => $self->attr->{src},
    caption => $self->caption,
    type => $self->type,
  }
}

1;
