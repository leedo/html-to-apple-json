#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;

use List::Util qw{any first};
use HTML::Parser;
use Data::Dump qw{pp};

my $parser = HTML::Parser->new(
  api_version => 3,
  start_h => [\&start, "tagname,attr"],
  text_h => [\&text, "dtext"],
  end_h => [\&end, "tagname"],
);

my (@parents, @components);

our @TRACK = qw{figure figcaption p blockquote};
our @IGNORE = qw{aside script style};
our @CONCAT = qw{text};

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

$parser->parse($_) while (<>);
$parser->eof;
cleanup_text();

say pp \@components;

sub cleanup_text {
  for (grep {$_->{text}} @components) {
    $_->{text} =~ s/\n\n$//g;
  }
}

sub track_tag {
  my $tag = shift;
  return any {$tag eq $_} @TRACK, @IGNORE, keys %STYLES;
}

sub start_style {
  my ($tag, %attr) = @_;

  if (my $style = $STYLES{$tag}) {
    my $current = current();
    push @{$current->{styles}}, [$style, text_length(), undef, \%attr];
  }
}

sub text_length {
  my $current = current();
  if ($current && $current->{text}) {
    return length $current->{text};
  }

  return 0;
}

sub end_style {
  my $tag = shift;
  if (my $style = $STYLES{$tag}) {
    my $current = current();

    # find first matching unclosed style
    my $style = first {$_->[0] eq $style && !defined $_->[2]} @{$current->{styles}};

    $style->[2] = text_length() if $style;
  }
}

sub new_component {
  my ($type, %args) = @_;

  if (@components) {
    # this type concatenates (e.g. consecutive paragraphs)
    return if $type eq $components[-1]->{type} and any {$type eq $_} @CONCAT;
  }

  push @components, {
    type => $type,
    styles => [],
    %args
  };
}

sub current {
  return $components[-1];
}

sub inside_ignore {
  for my $tag (@parents) {
    return 1 if any {$tag eq $_} @IGNORE;
  }
  return 0;
}

sub is_style {
  my $tag = shift;
  return any {$_ eq $tag} keys %STYLES;
}

sub start {
  my ($tag, $attr) = @_;

  push @parents, $tag if track_tag($tag);
  return if inside_ignore();

  # hack to allow p inside blockquote
  return if $tag eq "p" and any {$_ eq "blockquote"} @parents;

  if (my $type = $TYPES{$tag}) {
    new_component($type, %$attr);
  }
  elsif (is_style($tag)) {
    start_style($tag, %$attr);
  }
}

sub text {
  my $text = shift;

  return if inside_ignore();
  return if $text =~ /^\s*$/;

  if (current()->{type} =~ /^text|quote|heading$/) {
    current()->{text} .= $text;
  }
}

sub end {
  my $tag = shift;

  end_style($tag) if is_style($tag);
  current()->{text} .= "\n\n" if $tag eq "p" and !inside_ignore();

  pop @parents if track_tag($tag);
}
