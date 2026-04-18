#!/bin/bash

# Módulo de configurações globais
# Este arquivo contém todas as variáveis de configuração do sistema

# Include guard
[[ -n "${_CONFIG_SH_LOADED:-}" ]] && return 0
_CONFIG_SH_LOADED=1

# shellcheck source=lib/colors.sh
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Progresso
export TOTAL_REPOS=0
export PROCESSED_REPOS=0
export PROGRESS_BAR_WIDTH=50

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    export PROGRESS_BAR_CHAR="#"
    export EMPTY_BAR_CHAR="-"
else
    export PROGRESS_BAR_CHAR="█"
    export EMPTY_BAR_CHAR="░"
fi

# Comportamento básico
export DEBUG_MODE=false
export FOLLOW_SYMLINKS=false
export SKIP_AUTH=true
export FORCE_PULL=false

# Novas flags
export DRY_RUN=false
export PARALLEL_JOBS=1
export NETWORK_TIMEOUT=10
export MAX_RETRIES=1          # 1 = sem retry, 2+ = retry com backoff
export DO_SUBMODULES=false
export DO_LFS=false
export DO_PUSH=false
export DO_GC=false
export RUN_HOOKS=false
export JSON_OUTPUT=false
export NOTIFY=false
export WEBHOOK_URL=""
export ONLY_FAILED=false
export ONLY_DIRTY=false

# Arrays globais preenchidos por CLI/config (não exportáveis)
EXCLUDE_PATTERNS=()
REMAINING_ARGS=()

# Logs centralizados
LOG_BASE_DIR="${HOME}/.local/share/GitUpdateProject/logs"
mkdir -p "$LOG_BASE_DIR" 2>/dev/null || {
    LOG_BASE_DIR="/tmp/GitUpdateProject-logs-$(id -u)"
    mkdir -p "$LOG_BASE_DIR" 2>/dev/null || LOG_BASE_DIR="/tmp"
}

LOG_TIMESTAMP=$(date '+%Y%m%d_%H%M%S' 2>/dev/null || date +%s)
export LOG_FILE="$LOG_BASE_DIR/updateGit_${LOG_TIMESTAMP}.log"

cleanup_old_logs() {
    [ -d "$LOG_BASE_DIR" ] || return 0
    # Cross-platform: nomes contêm timestamp YYYYMMDD_HHMMSS, então sort lexical
    # por basename já equivale a sort por data (descendente = -r).
    local -a logs=()
    while IFS= read -r f; do
        [ -n "$f" ] && logs+=("$f")
    done < <(
        # Usar globbing + sort lexical reverso (portátil, sem -printf)
        # shellcheck disable=SC2012
        ls -1 "$LOG_BASE_DIR"/updateGit_*.log 2>/dev/null | sort -r
    )
    if [ ${#logs[@]} -gt 10 ]; then
        for old in "${logs[@]:10}"; do
            rm -f "$old" 2>/dev/null
        done
    fi
}

# Git seguro por padrão (sem prompt de credenciais)
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS="/bin/echo"

# Carregar config file (~/.config/gitupdate/config) se existir.
# Formato: KEY=VALUE por linha, # para comentários.
# Arrays são expressos como PATTERN em EXCLUDE_PATTERN (uma por linha, pode repetir).
load_config_file() {
    local cfg="${GITUPDATE_CONFIG:-$HOME/.config/gitupdate/config}"
    [ -f "$cfg" ] || return 0

    local line key value
    while IFS= read -r line || [ -n "$line" ]; do
        # Ignorar comentários e linhas vazias
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [ -z "$line" ] && continue

        key="${line%%=*}"
        value="${line#*=}"
        # Stripping de aspas opcionais
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"

        case "$key" in
            DEBUG_MODE|FOLLOW_SYMLINKS|SKIP_AUTH|FORCE_PULL|DRY_RUN|\
            DO_SUBMODULES|DO_LFS|DO_PUSH|DO_GC|RUN_HOOKS|JSON_OUTPUT|\
            NOTIFY|ONLY_FAILED|ONLY_DIRTY)
                export "$key=$value"
                ;;
            PARALLEL_JOBS|NETWORK_TIMEOUT|MAX_RETRIES)
                export "$key=$value"
                ;;
            WEBHOOK_URL)
                export WEBHOOK_URL="$value"
                ;;
            EXCLUDE_PATTERN)
                EXCLUDE_PATTERNS+=("$value")
                ;;
            *)
                echo "⚠️  Config file: chave desconhecida '$key' (ignorando)" >&2
                ;;
        esac
    done < "$cfg"
}

# Parser CLI. Argumentos posicionais vão para REMAINING_ARGS.
configure_settings() {
    REMAINING_ARGS=()
    while [ $# -gt 0 ]; do
        case "$1" in
            -d|--debug)            DEBUG_MODE=true; shift ;;
            -L|--follow-symlinks)  FOLLOW_SYMLINKS=true; shift ;;
            -a|--allow-auth)       SKIP_AUTH=false; shift ;;
            -f|--force)            FORCE_PULL=true; shift ;;
            -n|--dry-run)          DRY_RUN=true; shift ;;
            -j|--jobs)             PARALLEL_JOBS="${2:-1}"; shift 2 ;;
            --timeout)             NETWORK_TIMEOUT="${2:-10}"; shift 2 ;;
            --retries)             MAX_RETRIES="${2:-1}"; shift 2 ;;
            --submodules)          DO_SUBMODULES=true; shift ;;
            --lfs)                 DO_LFS=true; shift ;;
            --push)                DO_PUSH=true; shift ;;
            --gc)                  DO_GC=true; shift ;;
            --hooks)               RUN_HOOKS=true; shift ;;
            --json)                JSON_OUTPUT=true; shift ;;
            --notify)              NOTIFY=true; shift ;;
            --webhook)             WEBHOOK_URL="${2:-}"; shift 2 ;;
            --only-failed)         ONLY_FAILED=true; shift ;;
            --only-dirty)          ONLY_DIRTY=true; shift ;;
            -x|--exclude)          EXCLUDE_PATTERNS+=("${2:-}"); shift 2 ;;
            *)
                REMAINING_ARGS+=("$1")
                shift
                ;;
        esac
    done
}
