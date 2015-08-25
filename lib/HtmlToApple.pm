package HtmlToApple;

use v5.14;
use strict;
use warnings;

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

sub new {
  my ($class, %args) = @_;
  my $self = bless {
    parents => [],
    components => [HtmlToApple::Component::Empty->new],
    ignore => 0
  }, $class;

  $self->{parser} = $self->_build_parser;
  return $self;
}

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

sub parser { $_[0]->{parser} }
sub components { $_[0]->{components} }

sub parse {
  my ($self, $chunk) = @_;
  $self->parser->parse($chunk);
}

sub eof {
  my ($self) = (@_);;
  $self->parser->eof;
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

  my $component = "HtmlToApple::Component::$type"->new(attr => $args);
  push @{$self->components}, $component;

  # associate this component with the current tag, so we know when
  # the component ends
  $self->{parents}[-1][1] = $component;
}

sub is_style {
  my ($self, $tag) = @_;
  return any {$_ eq $tag} keys %STYLES;
}

sub is_ignore {
  my ($self, $tag) = @_;
  return any {$_ eq $tag} @IGNORE;
}

sub start_tag {
  my ($self, $tag, $attr) = @_;

  if ($self->is_ignore($tag)) {
    $self->{ignore}++;
    return;
  }

  return if $self->{ignore};

  push @{$self->{parents}}, [$tag, undef];

  if ($self->current->type eq "Empty") {
    if (my $type = $self->match_type($tag, $attr)) {
      pop @{$self->components} if $self->current->type eq "Empty";
      $self->new_component($type, $attr);
    }
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
  return if $self->{ignore};
  return if $text =~ /^\s*$/;

  if ($self->current->accepts_text) {
    $self->current->add_text($text);
  }
}

sub end_tag {
  my ($self, $tag) = @_;

  if ($self->is_ignore($tag)) {
    $self->{ignore}--;
    return;
  }

  return if $self->{ignore};

  $self->end_style($tag) if $self->is_style($tag);

  my $closed = pop @{$self->{parents}};

  if ($closed->[1]) {
    push @{$self->{components}}, HtmlToApple::Component::Empty->new;
  }
}

1;
