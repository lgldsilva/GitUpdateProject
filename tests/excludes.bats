#!/usr/bin/env bats

load helper

setup() {
    load_lib colors.sh
    load_lib config.sh
    load_lib logger.sh
    load_lib excludes.sh
    EXCLUDE_PATTERNS=()
}

@test "should_exclude_path: sem padrões não exclui nada" {
    run should_exclude_path "/foo/bar" "/foo"
    [ "$status" -eq 1 ]
}

@test "should_exclude_path: match por basename" {
    EXCLUDE_PATTERNS=("node_modules")
    run should_exclude_path "/foo/project/node_modules" "/foo"
    [ "$status" -eq 0 ]
}

@test "should_exclude_path: match por glob" {
    EXCLUDE_PATTERNS=("*.tmp")
    run should_exclude_path "/foo/xyz.tmp" "/foo"
    [ "$status" -eq 0 ]
}

@test "should_exclude_path: match por path relativo" {
    EXCLUDE_PATTERNS=("vendor/*")
    run should_exclude_path "/root/vendor/pkg" "/root"
    [ "$status" -eq 0 ]
}

@test "should_exclude_path: não match quando padrão não aplica" {
    EXCLUDE_PATTERNS=("node_modules")
    run should_exclude_path "/foo/src" "/foo"
    [ "$status" -eq 1 ]
}

@test "load_gitupdateignore: carrega padrões do arquivo" {
    local tmp
    tmp=$(mktemp -d)
    cat > "$tmp/.gitupdateignore" <<EOF
# comentário
node_modules
*.tmp

vendor/
EOF
    EXCLUDE_PATTERNS=()
    load_gitupdateignore "$tmp"
    [ "${#EXCLUDE_PATTERNS[@]}" -eq 3 ]
    [ "${EXCLUDE_PATTERNS[0]}" = "node_modules" ]
    rm -rf "$tmp"
}
