#!/bin/bash

# Módulo de hooks pós-update por repositório.
# Executa .gitupdate-hook (se executável) no diretório do repo após pull bem-sucedido.

# Include guard
[[ -n "${_HOOKS_SH_LOADED:-}" ]] && return 0
_HOOKS_SH_LOADED=1

# shellcheck source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
# shellcheck source=lib/logger.sh
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# run_repo_hook <repo_dir>
# Procura .gitupdate-hook ou .gitupdate-hook.sh no repo_dir.
run_repo_hook() {
    [ "$RUN_HOOKS" = true ] || return 0

    local repo_dir="${1:?ERRO: repo_dir não informado}"
    local hook=""

    if [ -x "$repo_dir/.gitupdate-hook" ]; then
        hook="$repo_dir/.gitupdate-hook"
    elif [ -x "$repo_dir/.gitupdate-hook.sh" ]; then
        hook="$repo_dir/.gitupdate-hook.sh"
    fi

    [ -z "$hook" ] && return 0

    if [ "$DRY_RUN" = true ]; then
        info_log "  [dry-run] Executaria hook: $hook"
        return 0
    fi

    log "  Executando hook: $(basename "$hook")"
    if (cd "$repo_dir" && "$hook"); then
        sucesso_log "  Hook concluído"
        return 0
    else
        local status=$?
        aviso_log "  Hook falhou (status=$status)"
        return $status
    fi
}
