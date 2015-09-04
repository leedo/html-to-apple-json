package HtmlToApple::Component::Empty;

use Moo;
extends "HtmlToApple::Component";

sub accepts { 1 }

sub clean {
  my ($self) = @_;

  my @clean;
  my @comps = $self->daughters;

  while (my $c = shift @comps) {
    # skip lone captions
    next if $c->name eq "Caption";

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

  return @clean;
}

sub as_data {
  my $self = shift;
  return [map {$_->as_data} $self->clean];
}

1;
