load '../helper/bats-support/load'
load '../helper/bats-assert/load'
load '../helper/docker-support'

# Test repo connection
@test "solr package add-repo" {
  run docker exec -it solr solr package add-repo solr.cool http://repo:8080
  assert_success
  assert_output --partial 'Added repository: solr.cool'
}

@test "solr package list-available" {
  run docker exec -it solr solr package list-available
  assert_success
  assert_output --partial 'thymeleaf'
}
