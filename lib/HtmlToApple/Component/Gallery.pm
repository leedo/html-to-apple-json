package HtmlToApple::Component::Gallery;

use Moo;
extends "HtmlToApple::Component";

sub accepts_types { qw{GalleryImage Caption} }

sub images {
  my ($self) = @_;
  my @images;
  for my $daughter ($self->daughters) {
    if ($daughter->type eq "GalleryImage") {
      push @images, $daughter;
    }
    if ($daughter->type eq "Caption" and @images) {
      $images[-1]->caption($daughter->as_markdown);
    }
  }
  return @images;
}

sub as_data {
  my ($self) = @_;
  return {
    type => $self->name,
    images => [map {$_->as_data} $self->images],
  }
}

1;
