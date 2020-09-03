#!/bin/bash
#
# This script will iterate the packages configured and gather
# recent versions and build the repo plugin descriptor.
set -e

# clean build
rm -rf target
rm -rf _data/versions/*.json
rm -rf _data/repos/*.json
mkdir -p target
mkdir -p _data/versions
mkdir -p _data/repos

# iterate package definitions
for plugin in ./_data/packages/*.yaml; do
  echo "---"
  echo "Processing ${plugin}"
  file=$(basename $plugin)
  name=${file%.yaml}
  descriptor=target/${name}.json

  # check for a manifest section
  manifest=$(yq read $plugin manifest)
  if [ -z "$manifest" ]; then
    echo "No package manifest given."
    continue;
  fi

  # -------------------------------------------------------------------
  # (1) Compile package descriptor
  # -------------------------------------------------------------------
  # 
  # prepare descriptor
  jq -n \
    --arg name $name \
    --arg description "$(yq read $plugin description)" \
    '{"name":$name, "description": $description}' > ${descriptor}
  
  # read recent versions from Github
  gh_repo_url=$(yq read $plugin url)
  gh_repo_name=${gh_repo_url#https://github.com/}
  gh_repo_details=$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${gh_repo_name}")
  gh_repo_releases=$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${gh_repo_name}/releases?per_page=10")

  # compile versions
  versions=$(echo ${gh_repo_releases} | jq '[{"version": .[].name , "date": .[].published_at|fromdate|strftime("%Y-%m-%d"), "artifacts": [{ "url": .[].assets[0].browser_download_url }]}]')

  # append manifest to each version
  versions_with_manifest=$(echo ${versions} | jq --argjson manifest "${manifest}" '.[] += {"manifest": $manifest}')

  # add versions to plugin descriptor
  full_descriptor=$(cat ${descriptor} | jq --argjson versions "${versions_with_manifest}" '. += {"versions": $versions}')
  echo ${full_descriptor} > ${descriptor}

  # -------------------------------------------------------------------
  # (2) Download & sign JARs
  # -------------------------------------------------------------------
  # find jars to sign
  jars=$(jq -r '.versions[].artifacts[].url' ${descriptor})

  # iterate jars
  for jar in ${jars}; do

    # download
    echo "Downloading ${jar}"
    curl -sfLo target/${name}.jar ${jar}

    # sign jars
    echo -n "Signing ... "
    signature=$(openssl dgst -sha1 -sign solr.cool.pem target/${name}.jar | openssl enc -base64 | tr -d \\n)
    echo ${signature}

    # append signature in plugin descriptor
    jq "(.versions[].artifacts[]|select(.url==\"${jar}\")) += {sig: \"${signature}\"}" ${descriptor} | sponge ${descriptor}
  done
  
  # -------------------------------------------------------------------
  # (3) Update package website description
  # -------------------------------------------------------------------
  cp ${descriptor} _data/versions/${name}.json
  
  echo ${gh_repo_details} | jq '{"name": .name, "full_name": .full_name, "description": .description, "updated_at": .updated_at, "stargazers_count": .stargazers_count, "watchers_count": .watchers_count, "license": .license}' > _data/repos/${name}.json

done

# update repository definition
jq -s '.' target/*.json > repository.json