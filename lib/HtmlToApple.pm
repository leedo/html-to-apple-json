package HtmlToApple;

use strict;
use warnings;

use HTML::Parser;
use HtmlToApple::Tag;
use HTML::Selector::XPath qw{selector_to_xpath};

# import types of components used in final document
use HtmlToApple::Component::Empty;
use HtmlToApple::Component::Body;
use HtmlToApple::Component::Heading;
use HtmlToApple::Component::Pullquote;
use HtmlToApple::Component::Tweet;
use HtmlToApple::Component::Image;
use HtmlToApple::Component::Video;
use HtmlToApple::Component::Caption;
use HtmlToApple::Component::Gallery;
use HtmlToApple::Component::GalleryImage;

# ignore anything that matches or falls under these
our @IGNORE = ('aside', 'script', 'style', 'div.gallery-main-image');

# if we hit one of these CSS selectors, and the current component
# accepts the new type: we create a new component, append
# it to the current component, make make it the new current component
our @TYPES = (
  [Heading   => 'h1, h2, h3, h4'],
  [Pullquote => 'blockquote.pullquote'],
  [Tweet     => 'blockquote.twitter-tweet'],
  [Image     => 'figure.image img'],
  [Video     => 'figure.video'],
  [Caption   => 'figure figcaption, div.gallery-thumb-copy p'],
  [Gallery   => 'div.gallery'],
  [GalleryImage => 'ol.gallery-thumbs a[data-orig]'],
  [Body      => 'p, ol, ul, blockquote'],
);

# convert CSS selectors to XPath ahead of time
@IGNORE = map {selector_to_xpath($_)} @IGNORE;
$_->[1] = selector_to_xpath($_->[1]) for @TYPES;

sub new {
  my ($class) = @_;
  my $tag = HtmlToApple::Tag->new({name => "body"});
  my $component = HtmlToApple::Component::Empty->new;

  return bless {
    tag => $tag,
    component => $component,
  }, $class;
}

sub parser {
  my ($self) = @_;
  if (!defined $self->{parser}) {
    $self->{parser} = HTML::Parser->new(
      api_version => 3,
      start_h => [sub { $self->start_tag(@_) }, "tagname,attr,text"],
      text_h  => [sub { $self->text_node(@_) }, "dtext"],
      end_h   => [sub { $self->end_tag(@_) },   "tagname,text"],
    );
  }
  return $self->{parser};
}

sub tag { $_[0]->{tag} }
sub component { $_[0]->{component} }

sub parse {
  my ($self, $chunk) = @_;
  $self->parser->parse($chunk);
}

sub eof {
  my ($self) = @_;
  $self->parser->eof;
  $self->{tag}->root->delete_tree;
  delete $self->{tag};
}

sub dump {
  my ($self) = @_;
  return $self->component->root->as_data;
}

sub start_tag {
  my ($self, $name, $attr, $raw) = @_;

  # create new tag as a child of current tag
  my $tag = $self->{tag} = $self->{tag}->append($name, $attr, $raw);

  if (!$self->inside_ignore) {
    if (my $type = $self->matches_type($tag)) {
      if ($self->component->accepts($type)) {
        my $component = $self->component->append($type, $attr);
        $tag->attributes->{component} = $component;
        $self->{component} = $component;
      }
      else {
        warn sprintf "matched %s inside a %s\n", $type, $self->component->type;
      }
    }

    $self->component->start_tag($tag, $raw);
  }

  # manually end the tag if it is an "empty tag" (e.g. img)
  $self->end_tag($name, "") if $tag->empty;
}

sub matches_type {
  my ($self, $tag) = @_;
  for my $type (@TYPES) {
    return $type->[0] if $tag->matches($type->[1]);
  }
}

sub inside_ignore {
  my ($self) = @_;
  for my $ignore (@IGNORE) {
    return 1 if $self->tag->matches_up($ignore);
  }
}

sub text_node {
  my ($self, $text) = @_;
  return if $self->inside_ignore;
  return if $text =~ /^\s*$/;

  if ($self->component->can("add_text")) {
    $self->component->add_text($text);
  }
}

sub end_tag {
  my ($self, $name, $raw) = @_;

  if ($name ne $self->tag->name) {
    warn sprintf "closing unmatched tag %s vs %s", $name, $self->tag->name;
    return;
  }

  if (!$self->inside_ignore) {
    $self->component->end_tag($self->tag, $raw);
  }

  if ($self->tag->attributes->{component}) {
    $self->{component} = $self->tag->attributes->{component}->mother;
  }

  $self->{tag} = $self->tag->unlink_from_mother;
}

1;
