package HtmlToApple::Component::Text;

use v5.14;
use strict;
use warnings;

use Moo;
use List::Util qw{any first sum};

extends "HtmlToApple::Component";

has text => (is => "ro", default => sub {[]});
has styles => (is => "rw", default => sub {[]});

sub can_style { return 1 }
sub accepts_text { return 1 }

sub type { "Text" }

sub text_length {
  my ($self) = @_;
  return sum 0, map {length $_} @{$self->text};
}

sub add_style {
  my ($self, $style, %attr) = @_;
  push @{$self->styles}, [$style, $self->text_length, undef, \%attr];
}

sub end_style {
  my ($self, $style) = @_;
  # find first matching unclosed style
  my $end = first {$_->[0] eq $style && !defined $_->[2]} @{$self->styles};
  $end->[2] = $self->text_length if $end;
}

sub add_text {
  my ($self, $add) = @_;
  push @{$self->text}, $add;
}

sub cleanup {
  my ($self) = @_;

  if ($self->text->[-1] and $self->text->[-1] eq "\n\n") {
    pop @{$self->text};
  }
}

sub as_data {
  my ($self) = @_;
  return {
    $self->attr_data,
    text => join("", @{$self->text}),
    styles => [ grep {defined $_->[2]} @{$self->styles} ],
    type => $self->type,
  };
}

1;
