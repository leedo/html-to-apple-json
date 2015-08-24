use Plack::Builder;
use Plack::Request;
use Text::Xslate;
use HtmlToApple;
use Encode;
use JSON;

my $template = Text::Xslate->new(path => "share/templates");

builder {
  mount "/" => sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    if ($req->method eq "POST") {
      my $h = HtmlToApple->new;
      $h->parser->parse(decode utf8 => $req->parameters->{content});
      my $json = JSON->new->utf8->pretty->encode($h->dump);
      return [200, ["Content-Type", "application/json; charset=utf-8"], [$json]];
    }
    else {
      if (!defined $req->parameters->{content}) {
        $req->parameters->{content} = do {
          local $/;
          open my $fh, "<:utf8", "t/etsy.html";
          <$fh>;
        };
      }

      my $html = $template->render("index.tx", $req->parameters);
      return [200, ["Content-Type", "text/html; charset=utf-8"], [encode utf8 => $html]];
    }
  };
};
