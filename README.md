This repo holds the content for the [https://searchbits.io](https://searchbits.io) website. It's built using jekyll.

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

and point your browser to `http://localhost:4000/`. Hit `ctrl-c` to end the preview. As you just created a draft, you can work on your draft and commit / push your changes without publishing it. As soon as you're done with your post, move the file from `_drafts` to `_posts`.

### Post Contents

A Blog post has a so called _font matter_ header. The header contains meta data about the author and the post. It is separated from the post using `---`.

    ---
    layout: blog-post                   # do not change
    title: post title
    published: true                     # do not change
    tags: comma,separated,tags
    excerpt: an optional excerpt as workaround \
        for a bug in jekyll when working with footnotes. \
        When in question, leave blank
    email: your.email@s24.com            # will be used for gravatar lookups
    author: Your Full Name
    author-twittername: yourtwittername  # leave blank if you have none
    ---

The first paragraph of your post will be used as a preview on the blog overview and index page. Separate preview from full post text by adding a line with

    <!--more-->

in your post.

## Deployment

Execute the rake deployment task:

    $ rake deploy

