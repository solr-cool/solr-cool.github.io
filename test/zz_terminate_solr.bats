load '$BATS_TEST_DIRNAME/helper/bats-support/load'
load '$BATS_TEST_DIRNAME/helper/bats-assert/load'
load '$BATS_TEST_DIRNAME/helper/docker-support'


@test "Tear Solr down" {
  docker-compose -f $BATS_TEST_DIRNAME/helper/docker-compose.yaml down
}