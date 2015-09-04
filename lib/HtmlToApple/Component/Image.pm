package HtmlToApple::Component::Image;

use Moo;

extends "HtmlToApple::Component";

has "caption" => (is => "rw");

sub type { "Image" }

sub as_data {
  my ($self) = @_;
  return {
    width => $self->attributes->{width},
    height => $self->attributes->{height},
    src => $self->attributes->{src},
    caption => $self->caption,
    type => $self->type,
  }
}

1;
