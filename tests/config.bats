#!/usr/bin/env bats

load helper

setup() {
    load_lib colors.sh
    load_lib config.sh
    # Reset explícito
    DRY_RUN=false
    PARALLEL_JOBS=1
    NETWORK_TIMEOUT=10
    MAX_RETRIES=1
    DO_SUBMODULES=false
    DO_LFS=false
    EXCLUDE_PATTERNS=()
    REMAINING_ARGS=()
}

@test "configure_settings: sem args mantém defaults" {
    configure_settings
    [ "$DRY_RUN" = false ]
    [ "$PARALLEL_JOBS" = 1 ]
}

@test "configure_settings: -n ativa dry-run" {
    configure_settings -n
    [ "$DRY_RUN" = true ]
}

@test "configure_settings: -j N define workers" {
    configure_settings -j 8
    [ "$PARALLEL_JOBS" = 8 ]
}

@test "configure_settings: --timeout aceita valor" {
    configure_settings --timeout 30
    [ "$NETWORK_TIMEOUT" = 30 ]
}

@test "configure_settings: --submodules + --lfs" {
    configure_settings --submodules --lfs
    [ "$DO_SUBMODULES" = true ]
    [ "$DO_LFS" = true ]
}

@test "configure_settings: -x acumula patterns" {
    configure_settings -x "a*" -x "b*"
    [ "${#EXCLUDE_PATTERNS[@]}" = 2 ]
    [ "${EXCLUDE_PATTERNS[0]}" = "a*" ]
    [ "${EXCLUDE_PATTERNS[1]}" = "b*" ]
}

@test "configure_settings: arg posicional vai para REMAINING_ARGS" {
    configure_settings -n /some/path
    [ "${#REMAINING_ARGS[@]}" = 1 ]
    [ "${REMAINING_ARGS[0]}" = "/some/path" ]
}

@test "load_config_file: lê KEY=VALUE" {
    local tmp
    tmp=$(mktemp -d)
    cat > "$tmp/config" <<EOF
# comentário
DRY_RUN=true
PARALLEL_JOBS=4
EXCLUDE_PATTERN=node_modules
EXCLUDE_PATTERN=*.tmp
EOF
    GITUPDATE_CONFIG="$tmp/config"
    EXCLUDE_PATTERNS=()
    DRY_RUN=false
    PARALLEL_JOBS=1
    load_config_file
    [ "$DRY_RUN" = true ]
    [ "$PARALLEL_JOBS" = 4 ]
    [ "${#EXCLUDE_PATTERNS[@]}" = 2 ]
    rm -rf "$tmp"
}
