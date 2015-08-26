package HtmlToApple::Component;

use v5.14;
use strict;
use warnings;

use Moo;

has attr => (is => "ro", default => sub {{}});
has open => (is => "rw", default => sub {1});

sub allowed_attr { [] }

# this is a base class for other components
# so we die if anything is not overridden

sub type { die "has no type" }

sub close {
  my $self = shift;
  $self->open(0);
}

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
