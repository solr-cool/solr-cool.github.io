#!/bin/bash
#
# This script will iterate the packages configured and gather
# recent versions and build the repo plugin descriptor.
set -e

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

# target definitions
source_package_dir=./_data/packages
target_details_dir=./_data/details
target_releases_dir=./_data/releases
target_dir=./target
target_test_dir=./target/package-tests

# clean build
rm -f repository.json
rm -rf ${target_dir}
rm -rf _site
rm -rf ${target_details_dir}/*.json
rm -rf ${target_releases_dir}/*.json
mkdir -p ${target_dir}
mkdir -p ${target_test_dir}
mkdir -p ${target_details_dir}
mkdir -p ${target_releases_dir}

# iterate package definitions
for plugin in ${source_package_dir}/*.yaml; do
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
  solr_package_descriptor_head=$(jq -n --arg name $name --arg description "$(yq read $plugin description)" '{"name":$name, "description": $description}')
  
  # read recent versions from Github
  gh_repo_name=${package_url#https://github.com/}
  gh_repo=$(curl -u ${GH_USER}:${GH_ACCESS_TOKEN} -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${gh_repo_name}")
  gh_repo_releases=$(curl -u ${GH_USER}:${GH_ACCESS_TOKEN} -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${gh_repo_name}/releases?per_page=10")
  gh_repo_status=$(curl -u ${GH_USER}:${GH_ACCESS_TOKEN} -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${gh_repo_name}/commits/master/status")

  # combine repo data
  gh_repo_details=$(echo ${gh_repo} | jq '{"name": .name, "full_name": .full_name, "description": .description, "updated_at": .updated_at, "stargazers_count": .stargazers_count, "watchers_count": .watchers_count, "license": .license}')
  gh_repo_details=$(echo ${gh_repo_details} | jq --argjson repo "${gh_repo}" '. += {"owner": { "login": $repo.owner.login, "type": $repo.owner.type, "avatar_url": $repo.owner.avatar_url, "html_url": $repo.owner.html_url }}')
  gh_repo_details=$(echo ${gh_repo_details} | jq --argjson status "${gh_repo_status}" '. += {"statuses": $status.statuses }')

  if [ ${#gh_repo_releases} -gt 8 ]; then
    gh_repo_details=$(echo ${gh_repo_details} | jq --argjson releases "${gh_repo_releases}" '. += {"total_download_count": $releases | map(.assets | map(.download_count) | add) | add}')
    gh_repo_details=$(echo ${gh_repo_details} | jq --argjson releases "${gh_repo_releases}" '. += {"latest_download_count": $releases[0].assets | map(.download_count) | add}')
  fi
  echo "${gh_repo_details}" > ${target_details_dir}/${name}.json

  # -------------------------------------------------------------------
  # (1b) Check Github releases
  # -------------------------------------------------------------------

  # condense gh releases
  gh_repo_releases_condensed=$(echo ${gh_repo_releases} | jq '[.[] | select(.prerelease == false) | {name: .name, body: .body, html_url: .html_url, created_at: .created_at, published_at: .published_at, assets: [.assets[] | select(.name | endswith("dependencies.jar")) | del(.uploader) ]}]')

  # compile solr package versions
  solr_package_versions=$(echo ${gh_repo_releases_condensed} | echo ${gh_repo_releases_condensed} | jq '[.[] | {version: .name , date: .published_at|fromdate|strftime("%Y-%m-%d"), artifacts: [.assets[]|{url: .browser_download_url}]}]')

  # add versions to solr package descriptor
  solr_package_descriptor=$(echo ${solr_package_descriptor_head} | jq --argjson versions "${solr_package_versions}" '. += {"versions": $versions}')

  # -------------------------------------------------------------------
  # (2) Compile package descriptor
  # -------------------------------------------------------------------
  #
  # check for a manifest section
  package_manifest=$(yq read $plugin package.manifest)
  if [ -z "$package_manifest" ]; then
    echo "No package manifest given."

    # write shortended release information for website
    echo ${gh_repo_releases_condensed} | jq '{releases: .}' > ${target_releases_dir}/${name}.json
    continue;
  fi

  # write full release information for website
  echo ${gh_repo_releases_condensed} | jq --argjson desc "${solr_package_descriptor}" '{releases: .,solr_package: $desc}' > ${target_releases_dir}/${name}.json

  # append manifest to each version
  solr_package_descriptor=$(echo ${solr_package_descriptor} | jq --argjson manifest "${package_manifest}" '.versions[] += {"manifest": $manifest}')

  # save descriptor
  echo ${solr_package_descriptor} > ${descriptor}

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
  cat << EOT > ./target/package-tests/${name}.bats
load '../../test/helper/bats-support/load'
load '../../test/helper/bats-assert/load'
load '../../test/helper/docker-support'

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
touch Gemfile.lock
mkdir -p _site
chmod a+w Gemfile.lock
chmod a+w _site
docker run --rm --volume="$PWD:/srv/jekyll" -it jekyll/builder:3.8 jekyll build

# -------------------------------------------------------------------
# (6) Execute bats tests
# -------------------------------------------------------------------
echo "Testing package manifest"
bats -o target --formatter junit test/setup
bats -o target --formatter junit target/package-tests
bats -o target --formatter junit test/teardown

# extract test results for jekyll
#xq -r '{"count": .testsuite."@tests", "failures": .testsuite."@failures", "errors": .testsuite."@errors"}' target/TestReport-thymeleaf.bats.xml > _data/tests/${name}.json

