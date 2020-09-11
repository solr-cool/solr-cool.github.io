# Contributing guidelines for solr.cool


## Adding your component

> 💡 You are very welcome to add your Solr package to solr.cool. We
> are open to both FOSS and commercially licensed packages.

#### 1. package descriptor

```yaml
name: Name of your component
description: A brief description of your component

# select one of _data/categories.yaml
category: responsewriters

# url pointing to the component, ideally a Github repository
url: https://github.com/solr-cool/solr-thymeleaf

# Solr package distribution specific information
package:

  # install collection oder cluster wide
  install: collection

  # the install manifest
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

#### 2. Create pull request


#### 3. Travis CI builds the PR
