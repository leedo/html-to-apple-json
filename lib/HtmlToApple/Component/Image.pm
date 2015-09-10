package HtmlToApple::Component::Image;

use Moo;

extends "HtmlToApple::Component";

has "caption" => (is => "rw");

sub as_data {
  my ($self) = @_;
  return {
    width => $self->attributes->{width},
    height => $self->attributes->{height},
    url => $self->attributes->{src},
    caption => $self->caption,
    role => "photo"
  }
}

1;
