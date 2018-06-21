This repo holds the content for the [http://solr.cool](http://solr.cool) website. It's built using Jekyll.

## Setup

Use the official Docker image to fire up a local Jekyll instance:

```
docker run --rm \
     --volume="$PWD:/srv/jekyll" \
     -p "4000:4000" \
     -it jekyll/jekyll:3.8 \
     jekyll serve --watch [--drafts]
```

and point your browser to `http://localhost:4000/`.

## Adding content
We're using [jekyll](http://jekyllrb.com/docs/home/) for content

* [Liquid](https://github.com/Shopify/liquid/wiki/Liquid-for-Designers) for templating
* [Kramdown](http://kramdown.gettalong.org/syntax.html) for content
* [Pygments](http://pygments.org/) for code highlighting

Preview your changes using the Docker command above.

## Deployment

Push to `master` on Github. Done.
