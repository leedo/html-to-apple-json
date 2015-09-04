use HtmlToApple::Test qw{test_file};

test_file "data/list.html", [
  {
    type => "Body",
    text => "> hello **friends!**"
  }
];
