use Plack::Builder;
use Plack::Request;
use Text::Xslate;
use HtmlToApple;
use Encode;
use Redis;
use Digest::SHA1 qw{sha1_hex};
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;

my $template = Text::Xslate->new(path => "share/templates");
my %config = do "config.pl";
my $ua = LWP::UserAgent->new;

builder {
  mount "/" => sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $redis = Redis->new;

    if ($req->method eq "POST") {
      my $h = HtmlToApple->new(%config);
      my $content = "";

      if (defined $req->parameters->{url}) {
        my $res = $ua->request(GET $req->parameters->{url});
        if ($res->is_success) {
          $content = $res->content;
        }
      }
      else {
        $content = $req->parameters->{content} || $req->content;
      }

      $h->parse(decode utf8 => $content);
      $h->eof;
      my $json = JSON->new->pretty->encode($h->dump);
      my $hash = sha1_hex($content);
      $redis->set("apple-json-$hash", $content);
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
          open my $fh, "<:utf8", "t/data/etsy.html";
          <$fh>;
        };
      }

      my $html = $template->render("index.tx", {content => $content});
      return [200, ["Content-Type", "text/html; charset=utf-8"], [encode utf8 => $html]];
    }
  };
};
