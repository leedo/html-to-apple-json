use HtmlToApple::Test qw{test_file};

test_file "data/boldlink.html", [
  {
    type => "Body",
    text => "[some link **with bold text** and not bold](farts)"
  }
];
