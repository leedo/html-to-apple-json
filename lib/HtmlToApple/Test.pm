package HtmlToApple::Test;

use HtmlToApple;
use Test::More;
use Exporter qw{import};

@EXPORT_OK = qw{test_file};

sub test_file {
  my ($file, $tests, $cb) = @_;

  my %config = do "config.pl";

  my $h = HtmlToApple->new(%config);
  open(my $fh, "<:utf8", "t/$file") || die;

  $h->parse($_) while (<$fh>);
  $h->eof;

  my $data = $h->dump;

  for my $i (0 .. $#{$tests}) {
    my $test = $tests->[$i];
    for $field (qw{type format}) {
      if (defined $test->{$field}) {
        is $data->[$i]{$field}, $test->{$field}, "component $i $field";
      }
    }
    if (defined $test->{like}) {
      for my $pattern (@{$test->{like}}) {
        like $data->[$i]{text}, $pattern, "component $i like $pattern";
      }
    }
    if (defined $test->{unlike}) {
      for my $pattern (@{$test->{unlike}}) {
        unlike $data->[$i]{text}, $pattern, "component $i unlike $pattern";
      }
    }

  }

  $cb->($data) if $cb;
  done_testing();
}

1;
