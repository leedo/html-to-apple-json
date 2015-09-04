use HtmlToApple::Test qw{test_file};

test_file "data/etsy.html", [
  {
    type => "Body",
    format => "markdown",
    like => [
      qr{\(\[Bloomberg\]\(},
      qr{t\."$}m,
    ],
    unlike => [qr{Further Reading}],
  },
  {
    type => "Heading",
    format => "markdown",
    like => [qr{Totally \*legal\*}]
  },
  {
    type => "Body",
    format => "markdown",
    like => [qr{^> Many}m],
  },
  {
    type => "Heading",
    format => "markdown",
  },
  {
    type => "Body",
    format => "markdown",
  },
];
