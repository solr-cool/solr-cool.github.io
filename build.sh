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
target_details_dir=./packages
source_package_dir=./_data/packages
target_repo_details_dir=./_data/details
target_releases_dir=./_data/releases
target_dir=./target
target_test_dir=./target/package-tests
target_gh_api_dir=./target/gh-api-responses
target_package_descriptor_dir=./target/solr-package-descriptors

# clean build
rm -f repository.json
rm -rf ${target_dir}
rm -rf _site
rm -rf ${target_details_dir}/*.md
rm -rf ${target_repo_details_dir}/*.json
rm -rf ${target_releases_dir}/*.json
mkdir -p ${target_details_dir}
mkdir -p ${target_repo_details_dir}
mkdir -p ${target_releases_dir}
mkdir -p ${target_dir}
mkdir -p ${target_test_dir}
mkdir -p ${target_gh_api_dir}
mkdir -p ${target_package_descriptor_dir}

# -------------------------------------------------------------------
# Read repo details from GitHub API and write to temporary files
# -------------------------------------------------------------------
function fetchGithubDetails {
  local name=$1
  local package_url=$(getGithubRepoUrl $name)
  echo " Fetching GitHub repository & release information from ${package_url}"

  # read recent versions from Github
  local gh_repo_name=${package_url#https://github.com/}
  local gh_repo=$(curl -u ${GH_USER}:${GH_ACCESS_TOKEN} -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${gh_repo_name}")
  local gh_repo_releases=$(curl -u ${GH_USER}:${GH_ACCESS_TOKEN} -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${gh_repo_name}/releases?per_page=10")
  local gh_repo_status=$(curl -u ${GH_USER}:${GH_ACCESS_TOKEN} -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${gh_repo_name}/commits/master/status")

  echo "${gh_repo}" > ${target_gh_api_dir}/${name}_gh_repo.json
  echo "${gh_repo_releases}" > ${target_gh_api_dir}/${name}_gh_repo_releases.json
  echo "${gh_repo_status}" > ${target_gh_api_dir}/${name}_gh_repo_status.json
}

# -------------------------------------------------------------------
# Writes GitHub repo details to details
# -------------------------------------------------------------------
function writeGithubDetails2Data {
  local name=$1
  echo " Writing GitHub repo information into ${target_repo_details_dir}/${name}.json"

  # load temporary data
  local gh_repo=$(cat ${target_gh_api_dir}/${name}_gh_repo.json)
  local gh_repo_status=$(cat ${target_gh_api_dir}/${name}_gh_repo_status.json)
  local gh_repo_releases=$(cat ${target_gh_api_dir}/${name}_gh_repo_releases.json)

  # combine repo data
  local gh_repo_details=$(echo ${gh_repo} | jq '{"name": .name, "full_name": .full_name, "description": .description, "updated_at": .updated_at, "stargazers_count": .stargazers_count, "watchers_count": .watchers_count, "license": .license}')
  local gh_repo_details=$(echo ${gh_repo_details} | jq --argjson repo "${gh_repo}" '. += {"owner": { "login": $repo.owner.login, "type": $repo.owner.type, "avatar_url": $repo.owner.avatar_url, "html_url": $repo.owner.html_url }}')
  local gh_repo_details=$(echo ${gh_repo_details} | jq --argjson status "${gh_repo_status}" '. += {"statuses": $status.statuses }')

  if [ ${#gh_repo_releases} -gt 8 ]; then
    local gh_repo_details=$(echo ${gh_repo_details} | jq --argjson releases "${gh_repo_releases}" '. += {"total_download_count": $releases | map(.assets | map(.download_count) | add) | add}')
    local gh_repo_details=$(echo ${gh_repo_details} | jq --argjson releases "${gh_repo_releases}" '. += {"latest_download_count": $releases[0].assets | map(.download_count) | add}')
  fi
  echo "${gh_repo_details}" > ${target_repo_details_dir}/${name}.json
}

# check for tagged github releases
function hasGitHubReleasesAndAssets {
  local name=$1
  local gh_repo_releases=$(cat ${target_gh_api_dir}/${name}_gh_repo_releases.json)

  local gh_release_count=$(echo ${gh_repo_releases} | jq '. | length')
  local gh_asset_count=$(echo ${gh_repo_releases} | jq '.[].assets | length')

  if [[ $gh_release_count -gt 0 && ! -z $gh_asset_count ]]; then
    return 0
  else
    return 1
  fi

}

# -------------------------------------------------------------------
# Write Github release information
# -------------------------------------------------------------------
function writeGithubReleases {
  local name=$1
  echo " Writing GitHub release information into ${target_releases_dir}/${name}.json"

  # load temporary data
  local gh_repo_releases=$(cat ${target_gh_api_dir}/${name}_gh_repo_releases.json)

  # condense gh releases
  local gh_repo_releases_condensed=$(echo "${gh_repo_releases}" | tr '\r\n' ' ' | jq '[.[] | select(.prerelease == false) | {name: .name, body: .body, html_url: .html_url, created_at: .created_at, published_at: .published_at, assets: [.assets[] | del(.uploader) | select(.name|endswith(".jar")) | select(.name|contains("source")|not) | select(.name|contains("javadoc")|not) ]}]')

  # remove releases without (.jar) artifacts
  local gh_repo_releases_condensed=$(echo ${gh_repo_releases_condensed} | jq '[.[] | select(.assets | length > 0)]')

  # write release information
  echo ${gh_repo_releases_condensed} > ${target_releases_dir}/${name}.json
}

# -------------------------------------------------------------------
# take the Github release descriptor and compile a Solr package
# descriptor
# -------------------------------------------------------------------
function writeGithubReleasesToSolrPackageDescriptor {
  local name=$1
  echo " Transforming GitHub release information from ${target_releases_dir}/${name}.json to ${target_package_descriptor_dir}/${name}.json"

  # load temporary data
  local gh_repo_releases_condensed=$(cat ${target_releases_dir}/${name}.json)

  # prepare descriptor
  local solr_package_descriptor_head=$(jq -n --arg name $name --arg description "$(yq read ${source_package_dir}/${name}.yaml description)" '{"name":$name, "description": $description}')

  # compile solr package versions
  local solr_package_versions=$(echo ${gh_repo_releases_condensed} | jq '[.[] | {version: .name|gsub("[a-zA-Z_-]";"") , date: .published_at|fromdate|strftime("%Y-%m-%d"), artifacts: [.assets[]|{url: .browser_download_url}]}]')

  # add versions to solr package descriptor
  local solr_package_descriptor=$(echo ${solr_package_descriptor_head} | jq --argjson versions "${solr_package_versions}" '. += {"versions": $versions}')

  # check for a manifest section or install type
  local package_manifest=$(yq read ${source_package_dir}/${name}.yaml package.manifest)
  
  # write full release information for website
  echo ${gh_repo_releases_condensed} | jq --argjson desc "${solr_package_descriptor}" '{releases: .,solr_package: $desc}' > ${target_releases_dir}/${name}.json

  # append manifest to each version if given
  if [ -n "$package_manifest" ]; then
    echo " Appending install manifest"
    local solr_package_descriptor=$(echo ${solr_package_descriptor} | jq --argjson manifest "${package_manifest}" '.versions[] += {"manifest": $manifest}')
  fi

  # save descriptor
  echo ${solr_package_descriptor} > ${target_package_descriptor_dir}/${name}.json
}

function hasSolrPackageDescriptor {
  if [ -f ${target_package_descriptor_dir}/${1}.json ]; then
    return 0
  else
    return 1
  fi
}

function getPackageInstallMethod {
  echo "$(yq read ${source_package_dir}/${1}.yaml package.install)"
}

function hasPackageInstallMethod {
  if [ -z "$(yq read ${source_package_dir}/${1}.yaml package.install)" ]; then
    return 1
  else
    return 0
  fi
}

function hasPackageInstallManifest {
  if [ -z "$(yq read ${source_package_dir}/${1}.yaml package.manifest)" ]; then
    return 1
  else
    return 0
  fi
}

function hasPackageInstallVia {
  if [ -z "$(yq read ${source_package_dir}/${1}.yaml package.via)" ]; then
    return 1
  else
    return 0
  fi
}

# -------------------------------------------------------------------
# Write the markdown detail page
# -------------------------------------------------------------------
function writeMarkdownDetailPage {
  local name=$1
  echo " Writing Markdown detail page to ${target_details_dir}/${name}.md"

  # write details markdown
  cat << EOM > ${target_details_dir}/${name}.md
---
layout: package
package_name: ${name}
---
EOM
}

# -------------------------------------------------------------------
# Download & sign JARs
# -------------------------------------------------------------------
function downloadAndSignPackageArtifacts {
  local name=$1
  echo " Downloading and signing package artifacts in ${target_package_descriptor_dir}/${name}.json"

  # find jars to sign
  local jars=$(jq -r '.versions[].artifacts[].url' ${target_package_descriptor_dir}/${name}.json)

  # iterate jars
  for jar in ${jars}; do

    # download
    echo " Downloading ${jar}"
    curl -sfLo target/${name}.jar ${jar}

    # sign jars
    echo -n " Signing ... "
    local signature=$(openssl dgst -sha1 -sign solr.cool.pem target/${name}.jar | openssl enc -base64 | tr -d \\n)
    echo ${signature}

    # append signature in plugin descriptor
    jq "(.versions[].artifacts[]|select(.url==\"${jar}\")) += {sig: \"${signature}\"}" ${target_package_descriptor_dir}/${name}.json | sponge ${target_package_descriptor_dir}/${name}.json
  done
}

function assembleSolrPackageDescriptors {
  jq -s '.' ${target_package_descriptor_dir}/*.json > repository.json
}
  
# -------------------------------------------------------------------
# Generate bats test
# -------------------------------------------------------------------
function generateBatsTest {
  local name=$1
  echo "Generating BATS tests in /target/package-tests/${name}.bats"

  cat << EOT > ./target/package-tests/${name}.bats
load '../../test/helper/bats-support/load'
load '../../test/helper/bats-assert/load'
load '../../test/helper/docker-support'

@test "solr package [${name}] install" {
  run docker exec -it solr solr package install ${name}
  assert_success
  assert_output --partial '${name} installed'
}

EOT

  # collection installation
  if [ "$(getPackageInstallMethod $name)" = "collection" ]; then
    cat << EOT >> ./target/package-tests/${name}.bats
@test "solr package [${name}] deploy to collection" {
  run docker exec -it solr solr package deploy ${name} -collections films -y
  assert_success
  assert_output --partial 'Deployment successful'
}
EOT
  fi

  # cluster installation
  if [ "$(getPackageInstallMethod $name)" = "cluster" ]; then
    cat << EOT >> ./target/package-tests/${name}.bats
@test "solr package [${name}] deploy to cluster" {
  run docker exec -it solr solr package deploy ${name} -cluster -y
  assert_success
  assert_output --partial 'Deployment successful'
}
EOT
  fi
}

function buildJekyllSite {
  echo "Building Jekyll site"
  touch Gemfile.lock
  mkdir -p _site
  chmod a+w Gemfile.lock
  chmod a+w _site
  docker run --rm --volume="$PWD:/srv/jekyll" -it jekyll/builder:3.8 jekyll build
}

function runBatsIntegrationTests {
  echo "Testing package manifest"
  bats -o target --formatter junit test/setup
  bats -o target --formatter junit target/package-tests
  bats -o target --formatter junit test/teardown
}

function getGithubRepoUrl {
  echo $(yq read ${source_package_dir}/$1.yaml url);
}

function isHostedOnGitHub {
  if [[ ! $(getGithubRepoUrl $1) == *"https://github.com"* ]]; then
    return 1
  else
    return 0
  fi
}

# iterate package definitions
for plugin in ${source_package_dir}/*.yaml; do
  echo ""
  echo "---------------------------------------------------------------"
  echo " -> Building ${plugin}"
  echo "---------------------------------------------------------------"
  file=$(basename $plugin)
  name=${file%.yaml}

  if isHostedOnGitHub $name; then
    fetchGithubDetails $name
    writeGithubDetails2Data $name

    if hasGitHubReleasesAndAssets $name; then
      writeGithubReleases $name

      if hasPackageInstallMethod $name || hasPackageInstallManifest $name; then
        writeGithubReleasesToSolrPackageDescriptor $name
      fi
    fi
  else
    echo " Not hosted on Github."
  fi

  writeMarkdownDetailPage $name

  if hasSolrPackageDescriptor $name; then
    downloadAndSignPackageArtifacts $name
    generateBatsTest $name
  fi

done

echo "---------------------------------------------------------------"
echo " -> Assembling site & Solr package descriptor"
echo "---------------------------------------------------------------"

assembleSolrPackageDescriptors
buildJekyllSite
runBatsIntegrationTests

echo "---------------------------------------------------------------"
echo " Done."
echo "---------------------------------------------------------------"
