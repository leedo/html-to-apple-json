package HtmlToApple::Component::Text;

use Moo;
use List::Util qw{any first sum};
use Scalar::Util qw{refaddr};
use HTML::Selector::XPath qw{selector_to_xpath};

extends "HtmlToApple::Component";

has text => (is => "ro", default => sub {[]});
has styles => (is => "rw", default => sub {[]});

our @STYLES = (
  [Bold => 'b, strong'],
  [Italic => 'em, i'],
  [Monospace => 'code'],
  [Link => 'a[href]']
);

$_->[1] = selector_to_xpath($_->[1]) for @STYLES;

sub type { "Text" }

sub start_tag {
  my ($self, $node) = @_;
  if (my $style = $self->matches_style($node)) {
    push @{$self->styles}, [$style, $self->text_length, undef, $node->attributes];
  }
}

sub end_tag {
  my ($self, $node) = @_;

  if (my $style = $self->matches_style($node)) {
    my $end = first {$_->[0] eq $style && !defined $_->[2]} @{$self->styles};
    $end->[2] = $self->text_length if $end;
  }
}

sub matches_style {
  my ($self, $node) = @_;
  for my $style (@STYLES) {
    my @matches = $node->root->findnodes($style->[1]);
    if (any {refaddr($_) eq refaddr($node)} @matches) {
      return $style->[0];
    }
  }
}

sub text_length {
  my ($self) = @_;
  return sum 0, map {length $_} @{$self->text};
}

sub add_text {
  my ($self, $add) = @_;
  push @{$self->text}, $add;
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
