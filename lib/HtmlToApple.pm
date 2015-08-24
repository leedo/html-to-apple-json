package HtmlToApple;

use v5.14;
use strict;
use warnings;

use Moo;
use List::Util qw{any first};
use HTML::Parser;
use JSON;

use HtmlToApple::Component;

has parser => (is => "lazy");
has parents => (is => "rw", default => sub {[]});
has components => (is => "rw", default => sub {[]});

our @TRACK = qw{figure figcaption p blockquote};
our @IGNORE = qw{aside script style};

our %TYPES = (
  p => "text",
  blockquote => "quote",
  img => "image",
  h1 => "heading",
  h2 => "heading",
  h3 => "heading",
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
  $_->cleanup_text for @{$self->components};
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
  if (my $style = $STYLES{$tag}) {
    $self->current->add_style($style, %attr);
  }
}

sub end_style {
  my ($self, $tag) = @_;
  if (my $style = $STYLES{$tag}) {
    $self->current->end_style($style);
  }
}

sub new_component {
  my ($self, $type, %args) = @_;
  return if $self->current && $self->current->is_concat;
  push @{$self->components}, HtmlToApple::Component->new(type => $type, %args);
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

  push @{$self->parents}, $tag if $self->trackable_tag($tag);
  return if $self->inside_ignore;

  # hack to allow p inside blockquote
  return if $tag eq "p" and any {$_ eq "blockquote"} @{$self->parents};

  if (my $type = $TYPES{$tag}) {
    $self->new_component($type, %$attr);
  }
  elsif ($self->is_style($tag)) {
    $self->start_style($tag, %$attr);
  }
}

sub text {
  my ($self, $text) = @_;
  return if $self->inside_ignore;
  return if $text =~ /^\s*$/;

  if ($self->current->type =~ /^text|quote|heading$/) {
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