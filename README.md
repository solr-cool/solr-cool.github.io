This repo holds the content for the [http://solr.cool](http://solr.cool) website. It's built using jekyll.

## Setup
Make sure you have `ruby` installed properly. For example by using [rbenv](https://github.com/sstephenson/rbenv)

    $ brew install rbenv rbenv-gemset ruby-build

Install a recent stable ruby version and activate it for this repo

    $ rbenv install 2.1.2
    $ echo "2.1.2" > .rbenv-version

Create a gemset to ease the ruby gem management

    $ rbenv gemset create 2.1.2 jekyll
    $ echo "jekyll" > .rbenv-gemsets

Install [bundler](http://bundler.io/)

    $ gem install bundler --no-ri --no-rdoc
    $ rbenv rehash

The next step is to install jekyll

    $ bundle install
    $ rbenv rehash
    $ jekyll -version
    jekyll 2.4.0

## Updating jekyll
Edit the Gemfile, enter the desired version and run [bundler](http://bundler.io/)

    $ bundle update

Note: if you receive a Gemfile update via `git pull` just run `bundle update`. Check
the [github dependency pages](https://pages.github.com/versions/) for latest versions

## Adding content
We're using [jekyll](http://jekyllrb.com/docs/home/) for content

* [Liquid](https://github.com/Shopify/liquid/wiki/Liquid-for-Designers) for templating
* [Kramdown](http://kramdown.gettalong.org/syntax.html) for content
* [Pygments](http://pygments.org/) for code highlighting

Preview your changes:

    $ bundle exec jekyll serve

and point your browser to `http://localhost:4000/`.
 
## Deployment

Push to `master` on Github. Done.
