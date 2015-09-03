package HtmlToApple::Component;

use Moo;

has attr => (is => "ro", default => sub {{}});
has open => (is => "rw", default => sub {1});

sub start_tag { }
sub end_tag { }

# this is a base class for other components
# so we die if anything is not overridden

sub type { die "has no type" }

sub close {
  my $self = shift;
  $self->open(0);
}

sub as_data {
  my ($self) = @_;
  return {
    type => $self->type,
  };
}

1;
