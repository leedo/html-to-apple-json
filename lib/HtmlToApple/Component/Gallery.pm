package HtmlToApple::Component::Gallery;

use strict;
use warnings;

use Moo;

extends "HtmlToApple::Component";

has images => (is => "rw", default => sub {[]});

sub type { "Gallery" }

sub start_tag {
  my ($self, $node) = @_;

  if ($node->name eq "a" and $node->attributes->{"data-orig"}) {
    push @{$self->images}, $node->attributes->{"data-orig"};
  }
}

sub as_data {
  my ($self) = @_;
  return {
    $self->attr_data,
    images => $self->images,
    type => $self->type,
  };
}


1;
