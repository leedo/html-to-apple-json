package HtmlToApple::Component;

use Moo;
use List::Util qw{any};

extends "Tree::DAG_Node";

sub type {
  my ($self) = @_;
  $self->name;
}

sub append {
  my ($self, $type, $attr) = @_;
  my $component = "HtmlToApple::Component::$type"->new;
  $component->name($type);
  $component->attributes($attr);
  $self->add_daughter($component);
  return $component;
}

sub accepts_types { () }
sub accepts {
  my ($self, $type) = @_;
  any {$_ eq $type} $self->accepts_types;
}

sub start_tag { }
sub end_tag { }

sub as_data {
  my $self = shift;
  return {role => $self->type};
}


1;
