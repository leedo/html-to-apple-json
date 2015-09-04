package HtmlToApple::Component::GalleryImage;

use parent "HtmlToApple::Component";

sub accepts { "Caption" }

sub caption {
  my ($self, $caption) = @_;
  $self->attributes->{caption} = $caption;
}

sub as_data {
  my ($self) = @_;
  return {
    type => $self->name,
    src => $self->attributes->{"data-orig"},
    caption => $self->attributes->{"caption"},
  };
}

1;
