use Plack::Builder;
use Plack::Request;
use Text::Xslate;
use HtmlToApple;
use Encode;
use Redis;
use Digest::SHA1 qw{sha1_hex};
use JSON;

my $template = Text::Xslate->new(path => "share/templates");

builder {
  mount "/" => sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $redis = Redis->new;

    if ($req->method eq "POST") {
      my $h = HtmlToApple->new;
      $h->parser->parse(decode utf8 => $req->parameters->{content});
      my $json = JSON->new->pretty->encode($h->dump);
      my $hash = sha1_hex($req->parameters->{content});
      $redis->set("apple-json-$hash", $req->parameters->{content});
      my $res = encode_json({hash => $hash, data => $json});

      return [200, ["Content-Type", "application/json; charset=utf-8"], [$res]];
    }
    else {
      my $content;
      my ($path) = $req->path =~ m{^/(.*)};

      if ($path) {
        $content = $redis->get("apple-json-" . $path);
      }

      if (!$content) {
        $content = do {
          local $/;
          open my $fh, "<:utf8", "t/etsy.html";
          <$fh>;
        };
      }

      my $html = $template->render("index.tx", {content => $content});
      return [200, ["Content-Type", "text/html; charset=utf-8"], [encode utf8 => $html]];
    }
  };
};
