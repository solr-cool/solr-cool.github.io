load 'helper/bats-support/load'
load 'helper/bats-assert/load'
load 'helper/docker-support'

# Build jekyll site from downloaded meta data
@test "Build site" {
  run  docker run --rm --volume="$PWD:/srv/jekyll" -it jekyll/builder:3.8 jekyll build
}
