#!/bin/bash

# Módulo de retry com backoff exponencial

# Include guard
[[ -n "${_RETRY_SH_LOADED:-}" ]] && return 0
_RETRY_SH_LOADED=1

# shellcheck source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
# shellcheck source=lib/logger.sh
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# retry_cmd <max_tentativas> <comando...>
# Backoff: 1s, 2s, 4s, 8s... entre tentativas.
# Retorna o status da última tentativa.
retry_cmd() {
    local max="${1:?ERRO: max tentativas não informado}"
    shift
    [ $# -eq 0 ] && { erro_log "retry_cmd: comando vazio"; return 2; }

    local attempt=1
    local delay=1
    local status=0

    while [ $attempt -le "$max" ]; do
        "$@"
        status=$?
        if [ $status -eq 0 ]; then
            return 0
        fi

        if [ $attempt -lt "$max" ]; then
            debug_log "  Tentativa $attempt falhou (status=$status), aguardando ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))
        fi
        attempt=$((attempt + 1))
    done

    return $status
}
