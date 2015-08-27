package HtmlToApple;

use v5.14;
use strict;
use warnings;

use List::Util qw{any all};
use HTML::Parser;
use Tree::DAG_Node::XPath;
use Scalar::Util qw{refaddr};

# import types of components used in final document
use HtmlToApple::Component::Empty;
use HtmlToApple::Component::Paragraph;
use HtmlToApple::Component::Pullquote;
use HtmlToApple::Component::Tweet;
use HtmlToApple::Component::Quote;
use HtmlToApple::Component::Image;
use HtmlToApple::Component::Heading;
use HtmlToApple::Component::Caption;
use HtmlToApple::Component::Gallery;

# ignore these tags and their children
our @IGNORE = qw{aside script style};

# list of unclosed tags, don't look for matching close tag
our @EMPTY = qw{img br hr meta link base embed param area col input};

# map component types to XPath selector
our @TYPES = (
  ["Paragraph" => "//p"],
  ["Pullquote" => "//blockquote[class=pullquote]"],
  ["Tweet"     => "//blockquote[class=twitter-tweet]"],
  ["Quote"     => "//blockquote"],
  ["Image"     => "//img"],
  ["Heading"   => "//h1 | h2 | h3"],
  ["Caption"   => "//figcaption"],
  ["Gallery"   => "//div[class=gallery]"],
);

# map tag names to style
our %STYLES = (
  b => "bold",
  strong => "bold",
  em => "italic",
  i => "italic",
  a => "link",
);


sub new {
  my ($class, %args) = @_;
  my $self = bless {
    root => Tree::DAG_Node::XPath->new({name => "root"}),
    components => [HtmlToApple::Component::Empty->new],
    ignores => [],
  }, $class;

  $self->{tag} = $self->{root};
  $self->{parser} = $self->_build_parser;
  return $self;
}

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

# remove empty components, and joins
# consective types that can concat

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

  # is this an empty tag?
  my $empty = any {$tag eq $_} @EMPTY;

  my $node = $self->{tag}->new_daughter({
    name => $tag,
    attributes => $attr,
  });

  # already inside an open component
  # style or let it decide what to do with a child tag

  if ($self->current->open) {
    if ($STYLES{$tag} && $self->current->can("add_style")) {
      $self->current->add_style($STYLES{$tag}, $attr);
    }
    elsif ($self->current->can("start_tag")) {
      $self->current->start_tag($tag, $attr);
    }
  }

  # no open component, and this tag matches
  # a selector for a new component

  elsif (my $type = $self->matches_type($node)) {
    my $component = $self->new_component($type, $attr);
    push @{$self->components}, $component;

    # don't add to list of parents if this is an
    # empty tag

    $node->attributes->{component} = $component;
    $component->close if $empty;
  }

  # make this current tag if it is not empty (e.g. <img/>)
  $self->{tag} = $node if !$empty;
}

# go through selectors and try to find one
# that matches the tag and/or attributes

sub matches_type {
  my ($self, $node) = @_;
  for my $type (@TYPES) {
    my @matches = $self->{root}->findnodes($type->[1]);
    if (any {refaddr($node) == refaddr($_)} @matches) {
      return $type->[0];
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

  # update ignore list, and abort if still ignoring
  if (@{$self->{ignores}} and $self->{ignores}[-1] eq $tag) {
    pop @{$self->{ignores}};
    return;
  }

  return if @{$self->{ignores}};

  # close style if one is open
  if ($STYLES{$tag} and $self->current->can("end_style")) {
    $self->current->end_style($STYLES{$tag});
  }

  if ($self->{tag}->attributes->{component}) {
    $self->{tag}->attributes->{component}->close;
  }

  $self->{tag} = $self->{tag}->mother;
}

1;
