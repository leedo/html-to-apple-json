package HtmlToApple::Component;

use v5.14;
use strict;
use warnings;

use Moo;

sub can_style { return 0 }
sub is_concat { return 0 }
sub has_text  { return 0 }

# this is a base class for other components
# so we die if anything is not overridden

sub type      { die "has no type" }
sub add_style { die "can not style" }
sub end_style { die "can not style" }
sub add_text  { die "can not add text" }

sub as_data {
  my ($self) = @_;
  return { type => $self->type };
}

1;
