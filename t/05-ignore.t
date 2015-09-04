use HtmlToApple::Test qw{test_file};

test_file "data/ignore.html", [
  {
    type => "Body",
    text => "tots",
    unlike => [qr{farts}],
  }
];
