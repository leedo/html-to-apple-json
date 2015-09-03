package HtmlToApple::Component::Markdown;

use Moo;
use List::Util qw{any};
use IPC::Open3;
use Symbol 'gensym';
use Encode;

extends "HtmlToApple::Component";

has html => (is => "ro", default => sub {[]});

sub type { "Markdown" }
sub allowed_tags { () }

sub start_tag {
  my ($self, $tag, $raw) = @_;
  $self->add_tag($tag, $raw);
}

sub allowed_tag {
  my ($self, $name) = @_;
  !$self->allowed_tags or any {$_ eq $name} $self->allowed_tags
}

sub add_tag {
  my ($self, $tag, $raw) = @_;
  push @{$self->html}, $raw if $self->allowed_tag($tag->name);
}

sub add_text {
  my ($self, $text) = @_;
  push @{$self->html}, $text;
}

sub end_tag {
  my ($self, $tag, $raw) = @_;
  $self->add_tag($tag, $raw);
}

sub as_markdown {
  my ($self) = @_;

  my ($w, $r, $e);
  $e = gensym;

  my $pid = open3 $w, $r, $e, "/usr/bin/pandoc -f html -t markdown --no-wrap -";

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

  return $md;
}

sub as_data {
  my ($self) = @_;
  return {
    markdown => $self->as_markdown,
    type => $self->type,
  };
}

1;
