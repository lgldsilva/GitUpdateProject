#!/bin/bash

# Módulo de exclusões
# Suporte a --exclude PATTERN (CLI/config) e arquivo .gitupdateignore no root_dir.

# Include guard
[[ -n "${_EXCLUDES_SH_LOADED:-}" ]] && return 0
_EXCLUDES_SH_LOADED=1

# shellcheck source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Carrega padrões de .gitupdateignore no root_dir (se existir). Anexa a EXCLUDE_PATTERNS.
load_gitupdateignore() {
    local root_dir="${1:?ERRO: root_dir não informado}"
    local ignore_file="$root_dir/.gitupdateignore"
    [ -f "$ignore_file" ] || return 0

    local line
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [ -z "$line" ] && continue
        EXCLUDE_PATTERNS+=("$line")
    done < "$ignore_file"
}

# Retorna 0 se o path deve ser excluído conforme qualquer padrão configurado.
# Padrões são testados contra:
#   - path absoluto
#   - path relativo ao root_dir
#   - basename
# Suporta glob shell (ex: "*.tmp", "vendor/*", "node_modules").
should_exclude_path() {
    local path="${1:?ERRO: path não informado}"
    local root_dir="${2:-}"

    [ ${#EXCLUDE_PATTERNS[@]} -eq 0 ] && return 1

    local rel="$path"
    if [ -n "$root_dir" ] && [[ "$path" == "$root_dir"/* ]]; then
        rel="${path#"$root_dir"/}"
    fi
    local base
    base="$(basename "$path")"

    local pattern
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        # shellcheck disable=SC2254
        case "$path" in $pattern) return 0 ;; esac
        # shellcheck disable=SC2254
        case "$rel"  in $pattern) return 0 ;; esac
        # shellcheck disable=SC2254
        case "$base" in $pattern) return 0 ;; esac
    done
    return 1
}
