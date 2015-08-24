package HtmlToApple;

use v5.14;
use strict;
use warnings;

use Moo;
use List::Util qw{any};
use HTML::Parser;

use HtmlToApple::Component;
use HtmlToApple::Component::Empty;
use HtmlToApple::Component::Text;
use HtmlToApple::Component::Quote;
use HtmlToApple::Component::Image;
use HtmlToApple::Component::Heading;
use HtmlToApple::Component::Caption;
use HtmlToApple::Component::Gallery;

has parser => (is => "lazy");
has parents => (is => "rw", default => sub {[]});
has components => (is => "rw", default => sub {[HtmlToApple::Component::Empty->new]});
has ignore => (is => "rw", default => sub {0});

our @IGNORE = qw{aside script style};

our %TYPES = (
  "Text"    => [{tag => "p"}],
  "Quote"   => [{tag => "blockquote"}],
  "Image"   => [{tag => "img"}],
  "Heading" => [{tag => "h1"}, {tag => "h2"}, {tag => "h3"}],
  "Caption" => [{tag => "figcaption"}],
  "Gallery" => [{tag => "div", class=> "gallery"}],
);

our %STYLES = (
  b => "bold",
  strong => "bold",
  em => "italic",
  i => "italic",
  a => "link",
);

sub _build_parser {
  my ($self) = @_;
  HTML::Parser->new(
    api_version => 3,
    start_h => [sub { $self->start_tag(@_) }, "tagname,attr"],
    text_h  => [sub { $self->text_node(@_) },  "dtext"],
    end_h   => [sub { $self->end_tag(@_) },   "tagname"],
  );
}

sub parse {
  my ($self, $chunk) = @_;
  $self->parser->parse($chunk);
}

sub eof {
  my ($self) = (@_);;
  $self->parser->eof;
  $_->cleanup for @{$self->components};
}

sub dump {
  my ($self) = @_;
  $self->eof;
  return [map {$_->as_data} @{$self->components}];
}

sub current {
  my ($self) = @_;
  return $self->components->[-1];
}

sub start_style {
  my ($self, $tag, %attr) = @_;
  if ((my $style = $STYLES{$tag}) && $self->current->can_style ) {
    $self->current->add_style($style, %attr);
  }
}

sub end_style {
  my ($self, $tag) = @_;
  if ((my $style = $STYLES{$tag}) && $self->current->can_style) {
    $self->current->end_style($style);
  }
}

sub new_component {
  my ($self, $type, $args) = @_;

  return if $self->current->type eq $type
      && $self->current->can_concat;

  # if last component is a placeholder, we're replacing it
  pop @{$self->components} if $self->current->type eq "Empty";

  my $component = "HtmlToApple::Component::$type"->new(attr => $args);
  push @{$self->components}, $component;

  # associate this component with the current tag, so we know when
  # the component ends
  $self->parents->[-1][1] = $component;
}

sub is_style {
  my ($self, $tag) = @_;
  return any {$_ eq $tag} keys %STYLES;
}

sub incr_ignore {
  my ($self, $tag) = @_;
  if (any {$_ eq $tag} @IGNORE) {
    $self->ignore($self->ignore + 1);
  }
  return $self->ignore;
}

sub decr_ignore {
  my ($self, $tag) = @_;
  if (any {$_ eq $tag} @IGNORE) {
    $self->ignore($self->ignore - 1);
  }
  return $self->ignore;
}

sub start_tag {
  my ($self, $tag, $attr) = @_;
  return if $self->incr_ignore($tag);

  if ($self->current->eats_child($tag, $attr)) {
    $self->current->start_child($tag, $attr);
    return;
  }

  push @{$self->parents}, [$tag, undef];

  if (my $type = $self->match_type($tag, $attr)) {
    $self->new_component($type, $attr);
  }
  elsif ($self->is_style($tag)) {
    $self->start_style($tag, %$attr);
  }
}

sub match_type {
  my ($self, $tag, $attr) = @_;
  my @classes = split /\s+/, ($attr->{class} || "");
  for my $type (keys %TYPES) {
    for my $test (@{$TYPES{$type}}) {
      if (defined $test->{tag}) {
        next unless $tag eq $test->{tag};
      }

      if (defined $test->{class}) {
        next unless any {$test->{class} eq $_} @classes;
      }

      # passes all tests, so return this type
      return $type;
    }
  }
}

sub text_node {
  my ($self, $text) = @_;
  return if $self->ignore;
  return if $text =~ /^\s*$/;

  if ($self->current->accepts_text) {
    $self->current->add_text($text);
  }
}

sub end_tag {
  my ($self, $tag) = @_;

  return if $self->decr_ignore($tag);

  if (!$self->ignore) {
    $self->end_style($tag) if $self->is_style($tag);
    $self->current->end_child($tag);
  }

  my $closed = pop @{$self->parents};

  # a component ended, put a placeholder on the end
  if ($closed->[1] && !$closed->[1]->can_concat) {
    push @{$self->components}, HtmlToApple::Component::Empty->new;
  }
}

1;
