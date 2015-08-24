use Plack::Builder;
use HtmlToApple;
use JSON;

builder {
  mount "/" => sub {
    my $env = shift;
    my $h = HtmlToApple->new;
    
    binmode($env->{'psgi.input'}, ":utf8");
    $h->parser->parse_file($env->{'psgi.input'});

    my $json = JSON->new->utf8->pretty->encode($h->dump);
    return [200, ["Content-Type", "application/json; charset=utf-8"], [$json]];
  };
};
