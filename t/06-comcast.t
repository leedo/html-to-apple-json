use HtmlToApple::Test qw{test_file};

test_file "data/comcast-vp.html", [
  {
    type => "Body",
    like => [qr{^\*Why does Comcast Internet service\*}],
  },
  {
    type => "Image",
  }
];
