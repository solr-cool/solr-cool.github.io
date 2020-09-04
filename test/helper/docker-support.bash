# see: https://github.com/CachetHQ/Docker/blob/master/test/docker_helpers.bash
# 

# asserts logs from container $1 contains $2
function docker_assert_log {
	local -r container=$1
	shift
	run docker logs $container
	assert_output -p "$*"
}

# wait for a container to produce a given text in its log
# $1 container
# $2 timeout in second
# $* text to wait for
function docker_wait_for_log {
	local -r container=$1
	local -ir timeout_sec=$2
	shift 2
	retry $(( $timeout_sec * 2 )) .5s docker_assert_log $container "$*"
}

# Retry a command $1 times until it succeeds. Wait $2 seconds between retries.
function retry {
    local attempts=$1
    shift
    local delay=$1
    shift
    local i

    for ((i=0; i < attempts; i++)); do
        run "$@"
        if [ "$status" -eq 0 ]; then
            echo "$output"
            return 0
        fi
        sleep $delay
    done

    echo "Command \"$@\" failed $attempts times. Status: $status. Output: $output" >&2
    false
}