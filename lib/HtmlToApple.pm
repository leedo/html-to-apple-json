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

# ignore anything that matches or falls under these
our @IGNORE = ('aside', 'script', 'style');

# map component types to CSS selector
our @TYPES = (
  [Body      => 'p, ol, ul, blockquote'],
  [Heading   => 'h1, h2, h3, h4'],
  [Pullquote => 'blockquote.pullquote'],
  [Tweet     => 'blockquote.twitter-tweet'],
  [Image     => 'figure.image img'],
  [Video     => 'figure.video'],
  [Caption   => 'figure figcaption'],
  [Gallery   => 'div.gallery'],
);

# convert CSS selectors to XPath ahead of time
@IGNORE = map {selector_to_xpath($_)} @IGNORE;
$_->[1] = selector_to_xpath($_->[1]) for @TYPES;

sub new {
  my ($class) = @_;
  my $root = HtmlToApple::Tag->new({name => "root"});

  return bless {
    root => $root,
    tag => $root,
    components => [HtmlToApple::Component::Empty->new],
  }, $class;
}

sub parser {
  my ($self) = @_;
  if (!defined $self->{parser}) {
    $self->{parser} = HTML::Parser->new(
      api_version => 3,
      start_h => [sub { $self->start_tag(@_) }, "tagname,attr,text"],
      text_h  => [sub { $self->text_node(@_) },  "dtext"],
      end_h   => [sub { $self->end_tag(@_) },   "tagname,text"],
    );
  }
  return $self->{parser};
}

sub components { $_[0]->{components} }
sub root { $_[0]->{root} }
sub tag { $_[0]->{tag} }
sub current { $_[0]->components->[-1] }

sub parse {
  my ($self, $chunk) = @_;
  $self->parser->parse($chunk);
}

# fix up the final list of components
sub cleanup {
  my ($self) = @_;

  my @clean;
  my @comps = @{$self->components};

  while (my $c = shift @comps) {
    # skip empty or lone captions
    next if $c->type eq "Empty";
    next if $c->type eq "Caption";

    # join consecutive bodies
    if ($c->can("concat")) {
      while (@comps and $comps[0]->type eq $c->type) {
        $c->concat(shift @comps);
      }
    }

    # look for captions following image/video/etc
    if ($c->can("caption")) {
      if (@comps and $comps[0]->type eq "Caption") {
        $c->caption((shift @comps)->as_markdown);
      }
    }

    push @clean, $c;
  }

  $self->{components} = [@clean];
}

sub dump {
  my ($self) = @_;
  $self->parser->eof;
  $self->{root}->delete_tree;
  $self->cleanup;
  return [map {$_->as_data} @{$self->components}];
}

sub start_tag {
  my ($self, $name, $attr, $raw) = @_;

  # create new tag as a child of current tag
  my $tag = $self->{tag} = $self->{tag}->append($name, $attr, $raw);

  # feed to current component, or try to make a new one
  if (!$self->inside_ignore) {
    if ($self->current->open) {
      $self->current->start_tag($tag, $raw);
    }
    elsif (my $type = $self->matches_type($tag)) {
      my $component = "HtmlToApple::Component::$type"->new(attr => $attr);

      push @{$self->components}, $component;
      $tag->attributes->{component} = $component;
      $component->start_tag($tag, $raw);
    }
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

  if ($self->current->can("add_text")) {
    $self->current->add_text($text);
  }
}

sub end_tag {
  my ($self, $name, $raw) = @_;

  if ($name ne $self->tag->name) {
    warn "closing unmatched tag $name";
    return;
  }

  if (!$self->inside_ignore) {
    $self->current->end_tag($self->tag, $raw);
  }

  if ($self->tag->attributes->{component}) {
    $self->tag->attributes->{component}->close;
  }

  $self->{tag} = $self->tag->unlink_from_mother;
}

1;
