(
  types => [
    [Title        => 'h1.heading'],
    [Heading      => 'h2, h3, h4'],
    [Byline       => 'p.byline'],
    [Pullquote    => 'blockquote.pullquote'],
    [Tweet        => 'blockquote.twitter-tweet'],
    [Image        => 'figure.image img'],
    [Video        => 'figure.video'],
    [Caption      => 'figure figcaption, div.gallery-thumb-copy p'],
    [Gallery      => 'ol.gallery-thumbs'],
    [GalleryImage => 'ol.gallery-thumbs a[data-orig]'],
    [Body         => 'p, ol, ul, blockquote'],
  ],
  ignore => [
    'aside',
    'script',
    'style',
    'div.gallery-main-image',
    '#article-footer-wrap',
    '#corner-info',
  ]
);
