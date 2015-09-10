package HtmlToApple::Component::Text;

use Moo;

extends "HtmlToApple::Component";

has text => (is => "ro", default => sub {[]});

sub add_text {
  my ($self, $text) = @_;
  push @{$self->text}, $text;
}

sub as_data {
  my ($self) = @_;
  my $text = join "", @{$self->text};
  $text =~ s/\s+/ /g;
  $text =~ s/^\s//;
  $text =~ s/\s$//;
  return {
    format => "text",
    text => $text,
    role => $self->role,
  };
}

1;
