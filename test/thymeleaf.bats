load 'helper/bats-support/load'
load 'helper/bats-assert/load'
load 'helper/docker-support'

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
