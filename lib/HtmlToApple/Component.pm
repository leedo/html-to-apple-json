package HtmlToApple::Component;

use v5.14;
use strict;
use warnings;

use Moo;

has attr => (is => "ro", default => sub {{}});

sub allowed_attr { [] }
sub can_style { return 0 }
sub is_concat { return 0 }
sub has_text  { return 0 }

# this is a base class for other components
# so we die if anything is not overridden

sub type      { die "has no type" }
sub add_style { die "can not style" }
sub end_style { die "can not style " . $_[0]->type }
sub add_text  { die "can not add text" }
sub cleanup   { }

sub attr_data {
  my $self = shift;
  map {$_ => $self->attr->{$_}}
    grep {defined $self->attr->{$_}}
    @{$self->allowed_attr};
}

sub as_data {
  my ($self) = @_;
  return {
    $self->attr_data,
    type => $self->type,
  };
}

1;
