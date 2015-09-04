use Test::More;
use HtmlToApple::Test qw{test_file};

test_file "data/gallery.html",
  [{type => "Gallery"}],
  sub {
    my $data = shift;

    is $#{$data->[0]{images}}, 17, "has 17 images";

    is $data->[0]{images}[0]{src}, "http://cdn.arstechnica.net/wp-content/uploads/sites/3/2015/09/DSC06472.jpg", "correct image";
    is $data->[0]{images}[0]{width}, 2500, "correct width";
    is $data->[0]{images}[0]{height}, 1667, "correct width";
    is $data->[0]{images}[0]{caption}, "Sony's new Xperia Z5.", "correct caption";
  };
