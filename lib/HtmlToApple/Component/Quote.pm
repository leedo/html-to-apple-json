package HtmlToApple::Component::Quote;

use v5.14;
use strict;
use warnings;

use Moo;

extends "HtmlToApple::Component::Text";

sub type { "Quote" }
sub can_concat { 0 }
sub eats_child {
  my ($self, $tag, $attr) = @_;
  return $tag eq "p";
}

1;
