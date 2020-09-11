[![Travis Build Status](https://travis-ci.org/solr-cool/solr-cool.github.io.svg?branch=master)](https://travis-ci.org/github/solr-cool/solr-cool.github.io)

This repo holds the content for the [solr.cool](https://solr.cool) website
and Solr Package repository.

## Building

The website is built using [Jekyll](https://jekyllrb.com/) and
hosted on Github Pages. Use the official Docker image to fire 
up a local Jekyll instance and point your browser to [localhost:4000](http://localhost:4000/).

```
docker run --rm \
     --volume="$PWD:/srv/jekyll" \
     -p "4000:4000" \
     -it jekyll/jekyll:3.8 \
     jekyll serve --watch [--drafts]
```

### Structure of package meta data

Solr package information and scraped meta data is checked in into
the [Jekyll `_data` folder](https://jekyllrb.com/docs/datafiles/)
in this repo:

* `_data/packages` – basic package information (manually curated)
* `_data/repos` (_generated_) – scraped repository information of each package
* `_data/versions` (_generated_) – scraped release version information of each package

### Updating scraped package meta data

> ☝️ The update process is triggered by Travis CI on a daily basis.

To update package repository, release and version information, run
the `build.sh` script. For each package it will:

1. collect repository meta data from Github
1. collect release information from Github
1. collect build status information from Github (if applicable)
1. compile a Solr package manager inventory file
1. download and sign the release JARs
1. test installation and deinstallation of the package in a vanilla Solr installation

To run the `build.sh` locally, you need a [personal Github access token](https://github.com/settings/tokens)
and a public/private key pair:

```bash
export GH_USER=<your-github-username>
export GH_ACCESS_TOKEN=<your-github-access-token>
openssl genrsa -out solr.cool.pem 4096
openssl rsa -in solr.cool.pem -pubout -outform DER -out publickey.der
```

## Adding content

> 💡 You are very welcome to add your Solr package to solr.cool. We
> are open to both FOSS and commercially licensed packages.

[Please read the contributing guidelines how to add your package to the repository](CONTRIBUTING.md).
It's pretty easy, I swear!

## Deployment

Push to `master` on Github. Done.

## License

This project is licensed under the [Apache License, Version 2](http://www.apache.org/licenses/LICENSE-2.0.html).