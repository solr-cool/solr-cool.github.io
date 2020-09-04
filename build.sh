#!/bin/bash
#
# This script will iterate the packages configured and gather
# recent versions and build the repo plugin descriptor.
set -ex

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v yq)" ]; then
  echo 'Error: yq is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v openssl)" ]; then
  echo 'Error: openssl is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v bats)" ]; then
  echo 'Error: bats is not installed.' >&2
  exit 1
fi

# clean build
rm -f repository.json
rm -rf target
rm -rf _site
rm -rf _data/versions/*.json
rm -rf _data/repos/*.json
rm -rf _data/tests/*.json
mkdir -p target
mkdir -p _data/versions
mkdir -p _data/repos
mkdir -p _data/tests

# iterate package definitions
for plugin in ./_data/packages/*.yaml; do
  echo "---"
  echo "Processing ${plugin}"
  file=$(basename $plugin)
  name=${file%.yaml}
  descriptor=target/${name}.json

  # -------------------------------------------------------------------
  # (1) Update package website description
  # -------------------------------------------------------------------
  # 
  package_url=$(yq read $plugin url)
  
  if [[ ! $package_url == *"https://github.com"* ]]; then
    echo "Not hosted on Github."
    continue;
  fi

  # prepare descriptor
  descriptor_head=$(jq -n --arg name $name --arg description "$(yq read $plugin description)" '{"name":$name, "description": $description}')
  
  # read recent versions from Github
  gh_repo_name=${package_url#https://github.com/}
  gh_repo_details=$(curl -u ${GH_USER}:${GH_ACCESS_TOKEN} -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${gh_repo_name}")
  gh_repo_releases=$(curl -u ${GH_USER}:${GH_ACCESS_TOKEN} -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${gh_repo_name}/releases?per_page=10")
  gh_repo_status=$(curl -u ${GH_USER}:${GH_ACCESS_TOKEN} -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${gh_repo_name}/commits/master/status")

  # combine repo data
  gh_repo_combined=$(echo ${gh_repo_details} | jq '{"name": .name, "full_name": .full_name, "description": .description, "updated_at": .updated_at, "stargazers_count": .stargazers_count, "watchers_count": .watchers_count, "license": .license}')
  gh_repo_combined=$(echo ${gh_repo_combined} | jq --argjson status "${gh_repo_status}" '. += {"statuses": $status.statuses }')

  if [ ${#gh_repo_releases} -gt 8 ]; then
    gh_repo_combined=$(echo ${gh_repo_combined} | jq --argjson releases "${gh_repo_releases}" '. += {"total_download_count": $releases | map(.assets | map(.download_count) | add) | add}')
    gh_repo_combined=$(echo ${gh_repo_combined} | jq --argjson releases "${gh_repo_releases}" '. += {"latest_download_count": $releases[0].assets | map(.download_count) | add}')
  fi
  echo ${gh_repo_combined} > _data/repos/${name}.json

  # compile versions
  versions=$(echo ${gh_repo_releases} | jq '[{"version": .[].name , "date": .[].published_at|fromdate|strftime("%Y-%m-%d"), "artifacts": [{ "url": .[].assets[0].browser_download_url }]}]')

  # add versions to plugin descriptor
  temp_descriptor=$(echo ${descriptor_head} | jq --argjson versions "${versions}" '. += {"versions": $versions}')
  echo ${temp_descriptor} > _data/versions/${name}.json

  # -------------------------------------------------------------------
  # (2) Compile package descriptor
  # -------------------------------------------------------------------
  #
  # check for a manifest section
  manifest=$(yq read $plugin manifest)
  if [ -z "$manifest" ]; then
    echo "No package manifest given."
    continue;
  fi

  # append manifest to each version
  versions_with_manifest=$(echo ${versions} | jq --argjson manifest "${manifest}" '.[] += {"manifest": $manifest}')

  # add versions to plugin descriptor
  full_descriptor=$(echo ${descriptor_head} | jq --argjson versions "${versions_with_manifest}" '. += {"versions": $versions}')

  # save descriptor part
  echo ${full_descriptor} > ${descriptor}

  # -------------------------------------------------------------------
  # (3) Download & sign JARs
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
  # (4) Generate bats test
  # -------------------------------------------------------------------
  cat << EOT > ./test/${name}.bats
load 'helper/bats-support/load'
load 'helper/bats-assert/load'
load 'helper/docker-support'

@test "solr package [${name}] install" {
  run docker exec -it solr solr package install ${name}
  assert_success
  assert_output --partial '${name} installed'
}

@test "solr package [${name}] deploy" {
  run docker exec -it solr solr package deploy ${name} -collections films -y
  assert_success
  assert_output --partial 'Deployment successful'
}
EOT
  
done
# -------------------------------------------------------------------
# (5) Assemble descriptor
# -------------------------------------------------------------------
jq -s '.' target/*.json > repository.json

echo "Building Jekyll site"
docker run --rm --volume="$PWD:/srv/jekyll" -it jekyll/builder:3.8 jekyll build

# -------------------------------------------------------------------
# (6) Execute bats tests
# -------------------------------------------------------------------
echo "Testing package manifest"
bats -o target --formatter junit test

# extract test results for jekyll
#xq -r '{"count": .testsuite."@tests", "failures": .testsuite."@failures", "errors": .testsuite."@errors"}' target/TestReport-thymeleaf.bats.xml > _data/tests/${name}.json

