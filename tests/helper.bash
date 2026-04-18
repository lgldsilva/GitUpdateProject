#!/usr/bin/env bash

# Common test setup helpers for bats.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_DIR="$PROJECT_ROOT/lib"
export PROJECT_ROOT LIB_DIR

# Carrega um módulo da lib dentro do teste.
load_lib() {
    local lib="$1"
    # shellcheck source=/dev/null
    source "$LIB_DIR/$lib"
}

# Cria um repo git temporário. Ecoa o path.
make_repo() {
    local dir
    dir=$(mktemp -d -t gitupdate-test.XXXXXX)
    (
        cd "$dir" || exit 1
        git init -q
        git -c user.email=t@t -c user.name=t commit -q --allow-empty -m "initial"
    )
    echo "$dir"
}
