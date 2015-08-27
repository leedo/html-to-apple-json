package HtmlToApple::Component::Paragraph;

use Moo;

extends "HtmlToApple::Component::Text";

sub type { "Paragraph" }

sub concat {
  my ($self, $comp) = @_;
  $self->add_text("\n\n");
  my $l = $self->text_length;

  for (@{$comp->text}) {
    $self->add_text($_);
  }

  for (@{$comp->styles}) {
    $_->[1] += $l;
    $_->[2] += $l;
    push @{$self->styles}, $_;
  }
}

1;
