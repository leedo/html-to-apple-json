package HtmlToApple::Component::Heading;

use Moo;

extends "HtmlToApple::Component::Markdown";

sub allowed_tags { qw{b em strong i} };

sub level {
  my ($self) = @_;
  if (defined $self->attributes->{tagname} and $self->attributes->{tagname} =~ /^h([1-6])$/) {
    return $1;
  }
  return 3;
}

sub role { "heading" . $_[0]->level }

1;
