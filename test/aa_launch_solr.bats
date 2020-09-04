load 'helper/bats-support/load'
load 'helper/bats-assert/load'
load 'helper/docker-support'

# Launch and prepare solr
@test "Launch Solr" {
  run docker-compose -f $BATS_TEST_DIRNAME/helper/docker-compose.yaml up -d
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
