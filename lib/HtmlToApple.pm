package HtmlToApple;

use strict;
use warnings;

use HTML::Parser;
use Tree::DAG_Node::XPath;
use HTML::Selector::XPath qw{selector_to_xpath};
use List::Util qw{any all};
use Scalar::Util qw{refaddr};

# import types of components used in final document
use HtmlToApple::Component::Empty;
use HtmlToApple::Component::Body;
use HtmlToApple::Component::Heading;
use HtmlToApple::Component::Pullquote;
use HtmlToApple::Component::Tweet;
use HtmlToApple::Component::Image;
use HtmlToApple::Component::Caption;
use HtmlToApple::Component::Gallery;

# ignore anything that matches or falls under these
our @IGNORE = ('aside', 'script', 'style');

# map component types to CSS selector
our @TYPES = (
  [Body      => 'p, ol, ul, blockquote'],
  [Heading   => 'h1, h2, h3, h4'],
  [Pullquote => 'blockquote.pullquote'],
  [Tweet     => 'blockquote.twitter-tweet'],
  [Image     => 'img'],
  [Caption   => 'figcaption'],
  [Gallery   => 'div.gallery'],
);

# empty tags, don't look for matching close tag
our @EMPTY = qw{img br hr meta link base embed param area col input};

# convert CSS selectors to XPath ahead of time
@IGNORE = map {selector_to_xpath($_)} @IGNORE;
$_->[1] = selector_to_xpath($_->[1]) for @TYPES;

sub new {
  my ($class, %args) = @_;
  my $self = bless {
    root => Tree::DAG_Node::XPath->new({name => "root"}),
    components => [HtmlToApple::Component::Empty->new],
  }, $class;

  $self->{tag} = $self->{root};
  $self->{parser} = $self->_build_parser;
  return $self;
}

sub _build_parser {
  my ($self) = @_;
  HTML::Parser->new(
    api_version => 3,
    start_h => [sub { $self->start_tag(@_) }, "tagname,attr,text"],
    text_h  => [sub { $self->text_node(@_) },  "dtext"],
    end_h   => [sub { $self->end_tag(@_) },   "tagname,text"],
  );
}

sub components { $_[0]->{components} }
sub root { $_[0]->{root} }
sub tag { $_[0]->{tag} }
sub current { $_[0]->components->[-1] }

sub parse {
  my ($self, $chunk) = @_;
  $self->{parser}->parse($chunk);
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
  $self->{parser}->eof;
  $self->{root}->delete_tree;
  $self->cleanup;
  return [map {$_->as_data} @{$self->components}];
}

sub start_tag {
  my ($self, $tag, $attr, $raw) = @_;

  my $empty = any {$tag eq $_} @EMPTY;
  my $node = $self->{tag}->new_daughter({
    name => $tag,
    attributes => $attr,
  });

  $self->{tag} = $node unless $empty;

  return if $self->inside_ignore;

  # no open component, and this tag matches selector
  if ($self->current->open) {
    $self->current->start_tag($node, $raw);
  }
  elsif (my $type = $self->matches_type($node)) {
    my $component = "HtmlToApple::Component::$type"->new(attr => $attr);

    push @{$self->components}, $component;
    $node->attributes->{component} = $component;
    $component->start_tag($node, $raw);

    $component->close if $empty;
  }
}

sub matches_type {
  my ($self, $node) = @_;
  for my $type (@TYPES) {
    my @matches = $self->root->findnodes($type->[1]);
    if (any {refaddr($node) == refaddr($_)} @matches) {
      return $type->[0];
    }
  }
}

sub inside_ignore {
  my ($self) = @_;
  for my $ignore (@IGNORE) {
    my @matches = $self->root->findnodes($ignore);
    return 0 unless @matches;
    return 1 if any {refaddr($self->tag) eq refaddr($_)} @matches;

    for my $ancestor ($self->tag->ancestors) {
      return 1 if any {refaddr($ancestor) eq refaddr($_)} @matches;
    }
  }
}

sub text_node {
  my ($self, $text) = @_;
  return if $self->inside_ignore;
  return if $text =~ /^\s*$/;

  if ($self->current->can("add_text")) {
    $self->current->add_text($text);
  }
}

sub end_tag {
  my ($self, $tag, $raw) = @_;

  if ($tag ne $self->tag->name) {
    warn "closing unmatched tag $tag";
    return;
  }

  if ($self->tag->attributes->{component}) {
    $self->tag->attributes->{component}->close;
    $self->current->end_tag($self->tag, $raw);
  }
  elsif (!$self->inside_ignore) {
    $self->current->end_tag($self->tag, $raw);
  }

  $self->{tag} = $self->tag->unlink_from_mother;
}

1;
