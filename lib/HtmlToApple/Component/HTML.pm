package HtmlToApple::Component::HTML;

use Moo;
use List::Util qw{any first sum};

extends "HtmlToApple::Component";

has html => (is => "ro", default => sub {[]});

sub type { "HTML" }

sub allowed_tags { () }

sub start_tag {
  my ($self, $node, $raw) = @_;

  if (!$self->allowed_tags or any {$_ eq $node->name} $self->allowed_tags) {
    push @{$self->html}, $raw;
  }
}

sub add_text {
  my ($self, $text) = @_;
  push @{$self->html}, $text;
}

sub end_tag {
  my ($self, $node, $raw) = @_;

  if (!$self->allowed_tags or any {$_ eq $node->name} $self->allowed_tags) {
    push @{$self->html}, $raw;
  }
}

sub concat {
  my ($self, $comp) = @_;
  push @{$self->html}, @{$comp->html};
}

sub as_markdown {
  my ($self) = @_;

  use IPC::Open3;
  use Symbol 'gensym'; 
  use Encode;

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
