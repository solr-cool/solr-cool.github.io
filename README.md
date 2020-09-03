This repo holds the content for the [http://solr.cool](http://solr.cool) website
and Solr Package repository.

## Building

The website is built using Jekyll.
Use the official Docker image to fire up a local Jekyll instance:

```
docker run --rm \
     --volume="$PWD:/srv/jekyll" \
     -p "4000:4000" \
     -it jekyll/jekyll:3.8 \
     jekyll serve --watch [--drafts]
```

and point your browser to `http://localhost:4000/`.

### Updating package releases

> ☝️ In the future (tm), the update process is triggered by Travis CI on a daily basis.

The website is built from the release and version information that
is checked into the repository. To update release information of the
listed packages, run the `build.sh` script.

For each package it will 

* collect release and repository information, 
* download and sign the JARs
* build a Solr package manager inventory file

## Adding content

1. _Add your package in a single file_ in the `_data/packages` directory.
   Fill in details and point to the repository used. To add the package
   to the package repository, add a `manifest` block with install commands. Use the `thymeleaf.json` as a starting point.
1. _Add a bats test_ in the `tests` directory. This will test your
   package Again, use the `thymeleaf.bats` as a starting point
1. Run the `build.sh


Preview your changes using the Docker command above.

## Deployment

Push to `master` on Github. Done.
