load 'helper/bats-support/load'
load 'helper/bats-assert/load'
load 'helper/docker-support'


@test "Tear Solr down" {
  docker-compose -f $BATS_TEST_DIRNAME/helper/docker-compose.yaml down
}