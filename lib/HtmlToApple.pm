package HtmlToApple;

use v5.14;
use strict;
use warnings;

use Moo;
use List::Util qw{any first};
use HTML::Parser;
use JSON;

use HtmlToApple::Component;
use HtmlToApple::Component::Text;
use HtmlToApple::Component::Quote;
use HtmlToApple::Component::Image;
use HtmlToApple::Component::Heading;

has parser => (is => "lazy");
has parents => (is => "rw", default => sub {[]});
has components => (is => "rw", default => sub {[]});

our @TRACK = qw{figure figcaption p blockquote};
our @IGNORE = qw{aside script style};

our %TYPES = (
  p => "Text",
  blockquote => "Quote",
  img => "Image",
  h1 => "Heading",
  h2 => "Heading",
  h3 => "Heading",
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
    start_h => [sub { $self->start(@_) }, "tagname,attr"],
    text_h  => [sub { $self->text(@_) },  "dtext"],
    end_h   => [sub { $self->end(@_) },   "tagname"],
  );
}

sub run {
  my ($self) = @_;
  open(my $fh, "<:utf8", $ARGV[0]) || die;
  $self->parser->parse_file($fh);
  $_->cleanup for @{$self->components};
  print JSON->new->utf8->pretty->encode([map {$_->as_data} @{$self->components}]);
}

sub trackable_tag {
  my ($self, $tag) = @_;
  return any {$tag eq $_} @TRACK, @IGNORE, keys %STYLES;
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

  return if $self->current
      && $self->current->type eq $type
      && $self->current->is_concat;

  push @{$self->components}, "HtmlToApple::Component::$type"->new(attr => $args);
}

sub inside_ignore {
  my ($self) = @_;
  for my $tag (@{$self->parents}) {
    return 1 if any {$tag eq $_} @IGNORE;
  }
  return 0;
}

sub is_style {
  my ($self, $tag) = @_;
  return any {$_ eq $tag} keys %STYLES;
}

sub start {
  my ($self, $tag, $attr) = @_;

  # need to track even ignored tags, so we can know we're
  # inside an ignorable part of the DOM
  push @{$self->parents}, $tag if $self->trackable_tag($tag);

  # but we don't care about any styles, tags, etc inside the ignore
  return if $self->inside_ignore;

  # hack to allow p inside blockquote
  return if $tag eq "p" and any {$_ eq "blockquote"} @{$self->parents};

  if (my $type = $TYPES{$tag}) {
    $self->new_component($type, $attr);
  }
  elsif ($self->is_style($tag)) {
    $self->start_style($tag, %$attr);
  }
}

sub text {
  my ($self, $text) = @_;
  return if $self->inside_ignore;
  return if $text =~ /^\s*$/;

  if ($self->current->has_text) {
    $self->current->add_text($text);
  }
}

sub end {
  my ($self, $tag) = @_;

  if (!$self->inside_ignore) {
    $self->end_style($tag) if $self->is_style($tag);
    $self->current->paragraph if $tag eq "p";
  }

  pop @{$self->parents} if $self->trackable_tag($tag);
}

1;
