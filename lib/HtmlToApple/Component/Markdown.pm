package HtmlToApple::Component::Markdown;

use Moo;
use List::Util qw{any};
use IPC::Open3;
use Symbol 'gensym';
use Encode;

extends "HtmlToApple::Component";

has html => (is => "ro", default => sub {[]});

sub allowed_tags {  }

sub start_tag {
  my ($self, $tag, $raw) = @_;
  $self->add_tag($tag, $raw);
}

sub end_tag {
  my ($self, $tag, $raw) = @_;
  $self->add_tag($tag, $raw);
}

sub add_tag {
  my ($self, $tag, $raw) = @_;
  push @{$self->html}, $raw if $self->allowed_tag($tag);
}

sub allowed_tag {
  my ($self, $tag) = @_;

  if (any {$_ eq $tag->name} $self->allowed_tags) {
    # ignore p tags inside blockquote or li
    return 0 if $tag->name eq "p" and $tag->matches_up(qw{blockquote li});
    return 1;
  }

  return 0;
}

sub add_text {
  my ($self, $text) = @_;
  push @{$self->html}, $text;
}

sub as_markdown {
  my ($self) = @_;

  return "" unless @{$self->html};

  my ($w, $r, $e);
  $e = gensym;

  my $pid = open3 $w, $r, $e, qw{pandoc -f html -t markdown --no-wrap -};

  while (my $chunk = shift @{$self->html}) {
    print $w encode utf8 => $chunk;
  }

  close $w;

  my $md = decode utf8 => join "", <$r>;
  my $error = join "", <$e>;

  warn $error if $error;

  close $r;
  close $e;

  waitpid $pid, 0;

  chomp $md;
  return $md;
}

sub as_data {
  my ($self) = @_;
  return {
    format => "markdown",
    text => join("", @{$self->html}),
    role => $self->role,
  };
}

1;
