load '$BATS_TEST_DIRNAME/helper/bats-support/load'
load '$BATS_TEST_DIRNAME/helper/bats-assert/load'
load '$BATS_TEST_DIRNAME/helper/docker-support'

@test "solr package [thymeleaf] install" {
  run docker exec -it solr solr package install thymeleaf
  assert_success
  assert_output --partial 'thymeleaf installed'
}

@test "solr package [thymeleaf] deploy" {
  run docker exec -it solr solr package deploy thymeleaf -collections films -y
  assert_success
  assert_output --partial 'Deployment successful'
}
