#!/usr/bin/env bats

load helper

setup() {
    load_lib status.sh
    REPO=$(make_repo)
    cd "$REPO"
}

teardown() {
    rm -rf "$REPO"
}

@test "is_dirty: repo limpo retorna 1" {
    run is_dirty
    [ "$status" -eq 1 ]
}

@test "is_dirty: repo com arquivo untracked retorna 0" {
    touch new-file.txt
    run is_dirty
    [ "$status" -eq 0 ]
}

@test "is_dirty: repo com arquivo modificado retorna 0" {
    echo "data" > tracked.txt
    git add tracked.txt
    git -c user.email=t@t -c user.name=t commit -q -m "add"
    echo "modified" > tracked.txt
    run is_dirty
    [ "$status" -eq 0 ]
}

@test "repo_status_summary: clean" {
    run repo_status_summary
    [ "$status" -eq 0 ]
    [ "$output" = "clean" ]
}

@test "repo_status_summary: dirty quando tem arquivo untracked" {
    touch foo.txt
    run repo_status_summary
    [ "$output" = "dirty" ]
}
