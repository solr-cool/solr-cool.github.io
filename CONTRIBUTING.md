# Contributing to solr.cool

We are looking forward to your contribution to solr.cool. We strive
to be a comprehensive directory of available Solr packages.

## Adding your component

> 💡 You are very welcome to add your Solr package to solr.cool. We
> are open to both FOSS and commercially licensed packages.

Follow these steps to add your package with ease.

#### 1. Fork this repository

Create a fork of the [solr-cool.github.io](https://github.com/solr-cool/solr-cool.github.io)
repository.

#### 2. Add package descriptor

Check out your fork of the repository. Add a new package descriptor file
of your Solr package into the `_data/packages` directory. Choose the
filename wisely at this will be _installation slug_ of you package.
The file name must end with `.yaml`. 

> A good starting point is either
the [thymeleaf](_data/packages/thymeleaf.ymal) or the 
[solritas-responsewriter](_data/packages/solritas-responsewriter.ymal)
package.

#### 3. Edit package descriptor

The following YAML keys are recognized when building the website.
All keys are mandatory except noted.

```yaml
name: Name of your component
description: A brief description of your component

# select one of _data/categories.yaml
category: responsewriters

# url pointing to the component, ideally a Github repository
# 
# If this points to a GitHub repository, we'll scrape license,
# releases and build status from the GitHub API
url: https://github.com/solr-cool/solr-thymeleaf

# Solr package distribution specific information
package:
  
  # (optional) If you already have a Solr package repo
  # set up, point to the repository descriptor. We'll
  # proxy all releases in your repository
  repo: https://raw.githubusercontent.com/erikhatcher/solritas/master/repo/repository.json

  # deploy "collection" oder "cluster" wide
  #
  # See: https://lucene.apache.org/solr/guide/8_6/package-manager.html#deploy-command
  install: collection

  # (optional) the install manifest as described in the
  # Solr docs
  manifest: |
    {
      "version-constraint": "6 - 9",
      "plugins": [
        {
          "name": "queryresponsewriter",
          "setup-command": {
            "path": "/api/collections/${collection}/config",
            "payload": {
              "add-queryresponsewriter": {
                "name": "${THYMELEAF_QRW_NAME}",
                "class": "thymeleaf:com.s24.search.solr.response.ThymeleafResponseWriter"
              }
            },
            "method": "POST"
          },
          "uninstall-command": {
            "path": "/api/collections/${collection}/config",
            "payload": {
              "delete-queryresponsewriter": "${THYMELEAF_QRW_NAME}"
            },
            "method": "POST"
          }
        }
      ],
      "parameter-defaults": {
        "THYMELEAF_QRW_NAME": "html"
      }
    }
```

#### 4. Build the site (optional)

Let the build script check your package descriptor. This will
verify the URLs. If you supplied a GitHub url, the build script
will check for releases, build status and license via the GitHub API.

Launch it locally using:

```bash
$ ./build.sh <your-package-slug> 
```

For the _thymeleaf_ package, this would be

```bash
$ ./build.sh thymeleaf
```

##### 4.1 Prerequisites

You need a couple if helper tools installed, to launch the build
script. If you're on a Mac, use [Homebrew](https://brew.sh)

```bash
$ brew install jq yq bats-core
```

#### 5. Create pull request

Create a pull request. Our Travis build server will check and build your
pull request automatically.

