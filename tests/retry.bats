#!/usr/bin/env bats

load helper

setup() {
    load_lib colors.sh
    load_lib config.sh
    load_lib logger.sh
    load_lib retry.sh
    DEBUG_MODE=false
}

@test "retry_cmd: sucesso na primeira tentativa retorna 0" {
    run retry_cmd 3 true
    [ "$status" -eq 0 ]
}

@test "retry_cmd: falha persistente retorna último status" {
    run retry_cmd 2 false
    [ "$status" -eq 1 ]
}

@test "retry_cmd: sucesso após falha" {
    local counter_file
    counter_file=$(mktemp)
    echo 0 > "$counter_file"

    _flaky() {
        local n
        n=$(cat "$counter_file")
        n=$((n + 1))
        echo "$n" > "$counter_file"
        [ "$n" -ge 2 ]
    }
    export -f _flaky
    export counter_file

    run retry_cmd 3 bash -c '_flaky'
    [ "$status" -eq 0 ]
    rm -f "$counter_file"
}
