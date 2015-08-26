package HtmlToApple;

use v5.14;
use strict;
use warnings;

use List::Util qw{any all};
use HTML::Parser;
use Data::Dump qw{pp};

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
    ignores => [],
  }, $class;

  $self->{parser} = $self->_build_parser;
  return $self;
}

our @IGNORE = qw{aside script style};
our @UNCLOSED = qw{img br hr};

our %TYPES = (
  "Text"    => [{tag => "p"}],
  "Quote"   => [{tag => "blockquote"}],
  "Image"   => [{tag => "img"}],
  "Heading" => [{tag => "h1"}, {tag => "h2"}, {tag => "h3"}],
  "Caption" => [{tag => "figcaption"}],
  "Gallery" => [{tag => "div", class => "gallery"}],
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

sub cleanup {
  my ($self) = @_;

  my @clean;
  my @comps = @{$self->components};

  while (my $c = shift @comps) {
    next if $c->type eq "Empty";

    if ($c->can("concat")) {
      while (@comps and $comps[0]->type eq $c->type) {
        $c->concat(shift @comps);
      }
    }

    push @clean, $c;
  }

  $self->{components} = [@clean];
}

sub dump {
  my ($self) = @_;
  $self->parser->eof;
  $self->cleanup;
  return [map {$_->as_data} @{$self->components}];
}

sub current {
  my ($self) = @_;
  return $self->components->[-1];
}

sub new_component {
  my ($self, $type, $args) = @_;
  return"HtmlToApple::Component::$type"->new(attr => $args);
}

sub start_tag {
  my ($self, $tag, $attr) = @_;

  push @{$self->{ignores}}, $tag if any {$_ eq $tag} @IGNORE;
  return if @{$self->{ignores}};

  if (all {$tag ne $_} @UNCLOSED) {
    push @{$self->{parents}}, [$tag, undef];
  }

  if ($self->current->open) {
    if ($STYLES{$tag} && $self->current->can("add_style")) {
      $self->current->add_style($STYLES{$tag}, $attr);
    }
    elsif ($self->current->can("start_tag")) {
      $self->current->start_tag($tag, $attr);
    }
  }
  elsif (my $type = $self->match_type($tag, $attr)) {
    my $component = $self->new_component($type, $attr);
    push @{$self->components}, $component;

    if (all {$tag ne $_} @UNCLOSED) {
      $self->{parents}[-1][1] = $component;
    }
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
  return if @{$self->{ignores}};
  return if $text =~ /^\s*$/;

  if ($self->current->can("add_text")) {
    $self->current->add_text($text);
  }
}

sub end_tag {
  my ($self, $tag) = @_;

  if (@{$self->{ignores}} and $self->{ignores}[-1] eq $tag) {
    pop @{$self->{ignores}};
    return;
  }

  return if @{$self->{ignores}};

  if ($STYLES{$tag} and $self->current->can("end_style")) {
    $self->current->end_style($tag);
  }

  my $closed = pop @{$self->{parents}};

  # close component with openeing tag
  $closed->[1]->close if $closed->[1];
}

1;
