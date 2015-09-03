package HtmlToApple::Tag;

use parent "Tree::DAG_Node::XPath";
use List::Util qw{any all};
use Scalar::Util qw{refaddr};

# empty tags, don't look for matching close tag
our @EMPTY = qw{img br hr meta link base embed param area col input};

sub empty {
  my $self = shift;

  return 1 if any {$self->name eq $_} @EMPTY;

  if (defined $self->attributes->{raw}) {
    return 1 if $self->attributes->{row} =~ m{/>$};
  }

  return 0;
}

sub matches {
  my ($self, $xpath) = @_;

  my @matches = $self->root->findnodes($xpath);
  if (any {refaddr($self) == refaddr($_)} @matches) {
    return 1;
  }

  return 0;
}

sub matches_up {
  my ($self, $xpath) = @_;

  my @matches = $self->root->findnodes($xpath);
  return 0 unless @matches;

  if (any {refaddr($self) == refaddr($_)} @matches) {
    return 1;
  }

  for my $ancestor ($self->ancestors) {
    return 1 if any {refaddr($ancestor) eq refaddr($_)} @matches;
  }
}

1;
