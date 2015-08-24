package HtmlToApple::Component;

use v5.14;
use strict;
use warnings;

use Moo;
use List::Util qw{any first sum};

our @CONCAT = qw{text};

has type => (is => "ro");
has text => (is => "ro", default => sub {[]});
has styles => (is => "ro", default => sub {[]});

sub is_concat {
  my ($self) = @_;
  return any {$self->type eq $_} @CONCAT;
}

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

sub paragraph {
  my ($self) = @_;
  $self->add_text("\n\n");
}

sub cleanup_text {
  my ($self) = @_;

  if ($self->text->[-1] and $self->text->[-1] eq "\n\n") {
    pop @{$self->text};
  }
}

sub as_data {
  my ($self) = @_;
  return {
    text => join("", @{$self->text}),
    styles => $self->styles,
    type => $self->type,
  };
}

1;
