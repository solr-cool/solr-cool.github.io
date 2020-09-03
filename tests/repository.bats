load 'helper/bats-support/load'
load 'helper/bats-assert/load'
load 'helper/docker-support'

# Launch and prepare solr
@test "Launch Solr" {
  run docker-compose -f $BATS_TEST_DIRNAME/docker-compose.yaml up -d
  docker_wait_for_log solr 120 "o.e.j.s.Server Started"
}

@test "Solr up and running" {
  run curl -fs "http://localhost:8983/solr/"
  assert_success
}

@test "Create films test collection" {
  run docker exec -it solr solr create -c films
  assert_success
}

@test "Index films test data" {
  run docker exec -it solr post -c films example/films/films.json 
  assert_success
}

# Test repo connection
@test "solr package add-repo" {
  run docker exec -it solr solr package add-repo solr.cool http://repo:8080
  assert_success
  assert_output --partial 'Added repository: solr.cool'
}

@test "solr package list-available" {
  run docker exec -it solr solr package list-available
  assert_success
  assert_output --partial 'sematext-example'
  assert_output --partial 'Querqy'
}

# Install and verify plugins
@test "[thymeleaf] install" {
  run docker exec -it solr solr package install thymeleaf
  assert_success
  assert_output --partial 'thymeleaf installed'
}

#@test "[thymeleaf] deploy" {
#  run docker exec -it solr solr package deploy thymeleaf -collections films
#  assert_success
#  #assert_output --partial 'thymeleaf installed'
#}

@test "Tear Solr down" {
  docker-compose -f $BATS_TEST_DIRNAME/docker-compose.yaml down
}