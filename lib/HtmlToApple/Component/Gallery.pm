package HtmlToApple::Component::Gallery;

use v5.14;
use strict;
use warnings;

use Moo;
use List::Util qw{any};

extends "HtmlToApple::Component";

has images => (is => "rw", default => sub {[]});

sub type { "Gallery" }

sub eats_child {
  my ($self, $tag, $attr) = @_;
  return any {$tag eq $_} qw{a img};
}

sub start_child {
  my ($self, $tag, $attr) = @_;

  if ($tag eq "a" and $attr->{class} ne "enlarge") {
    push @{$self->images}, $attr;
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
