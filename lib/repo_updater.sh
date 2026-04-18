#!/bin/bash

# Módulo principal de atualização de um repositório Git.

# Include guard
[[ -n "${_REPO_UPDATER_SH_LOADED:-}" ]] && return 0
_REPO_UPDATER_SH_LOADED=1

# shellcheck source=lib/logger.sh
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
# shellcheck source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
# shellcheck source=lib/git_utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/git_utils.sh"
# shellcheck source=lib/git_operations.sh
source "$(dirname "${BASH_SOURCE[0]}")/git_operations.sh"
# shellcheck source=lib/status.sh
source "$(dirname "${BASH_SOURCE[0]}")/status.sh"
# shellcheck source=lib/hooks.sh
source "$(dirname "${BASH_SOURCE[0]}")/hooks.sh"

# update_git_repo <repo_path>
# Aceita tanto o path do diretório do repo quanto o path do .git (dir ou file).
update_git_repo() {
    local arg="${1:?ERRO: caminho do repositório não especificado}"
    local repo_path="$arg"

    # Se veio com .git, sobe um nível
    if [[ "$(basename "$repo_path")" == ".git" ]]; then
        repo_path="$(dirname "$repo_path")"
    fi

    local repo_name
    repo_name=$(basename "$repo_path")
    local status=0
    local branch_found=false

    export GIT_TERMINAL_PROMPT=0
    export GIT_ASKPASS=/bin/echo

    # Entrar no diretório (compatibilidade com caminho do paralelizador)
    if ! cd "$repo_path" 2>/dev/null; then
        erro_log "  Não foi possível acessar $repo_path"
        return 1
    fi

    log "Atualizando repositório: $repo_name"

    # Coletar status inicial
    local pre_status
    pre_status=$(repo_status_summary)
    debug_log "  Status inicial: $pre_status"

    # Obter info do repo
    get_repo_info

    # Se --only-dirty e repo não está dirty, pular
    if [ "$ONLY_DIRTY" = true ]; then
        if ! is_dirty; then
            log "  [only-dirty] Pulando repo limpo: $repo_name"
            [ "${JSON_OUTPUT:-false}" != true ] && echo "-----------------------------------------"
            return 0
        fi
    fi

    # Lidar com alterações locais
    local did_stash=false
    if [ "$FORCE_PULL" = true ]; then
        aviso_log "  Modo --force ativo: descartando alterações locais (git reset --hard)"
        if [ "$DRY_RUN" != true ]; then
            perform_git_operation "Resetando para HEAD (modo forçado)" "Falha" git reset --hard
            [ $? -ne 0 ] && status=1
        else
            info_log "  [dry-run] Resetaria HEAD"
        fi
    elif is_dirty; then
        if [ "$DRY_RUN" != true ]; then
            if perform_git_operation "Salvando alterações locais (stash)" "Aviso" \
                    git stash push -u -m "GitUpdate autosave"; then
                did_stash=true
            else
                aviso_log "  Falha ao fazer stash — update pode ser bloqueado"
            fi
        else
            info_log "  [dry-run] Faria stash de alterações locais"
        fi
    fi

    # Fetch: falha parcial (um remote inacessível) não deve falhar o repo — os
    # updates individuais de branch vão determinar o sucesso real. Só logamos.
    if [ "$DRY_RUN" != true ]; then
        perform_git_operation "Buscando alterações de todos os remotes" "Aviso" git fetch --all --prune || \
            aviso_log "  Fetch retornou não-zero (possivelmente um remote offline); prosseguindo"
    else
        info_log "  [dry-run] Faria git fetch --all --prune"
    fi

    # Atualizar branches
    for remote in "${REPO_REMOTES[@]}"; do
        debug_log "  Verificando branches no remote '$remote' para $repo_name"
        if check_standard_branches "$remote"; then
            branch_found=true
        fi
        if [ -n "$CURRENT_BRANCH" ] \
                && [ "$CURRENT_BRANCH" != "master" ] \
                && [ "$CURRENT_BRANCH" != "main" ] \
                && [ "$CURRENT_BRANCH" != "develop" ]; then
            if update_branch "$remote" "$CURRENT_BRANCH"; then
                branch_found=true
            fi
        fi
    done

    if [ "$branch_found" = false ]; then
        try_generic_pull
        status=$?
    fi

    # Restaurar stash se aplicou
    if [ "$did_stash" = true ] && [ "$DRY_RUN" != true ]; then
        if ! perform_git_operation "Restaurando alterações locais (stash pop)" "Aviso" git stash pop; then
            aviso_log "  Conflito ao restaurar stash — ver 'git stash list'"
        fi
    fi

    # Operações extras
    update_submodules || status=1
    pull_lfs || :
    push_repo || :
    run_gc || :

    # Hooks
    if [ $status -eq 0 ]; then
        run_repo_hook "$repo_path" || :
    fi

    # Status final
    local post_status
    post_status=$(repo_status_summary)
    debug_log "  Status final: $post_status"

    # Exportar para o chamador via variáveis (cada chamada sobrescreve)
    # shellcheck disable=SC2034
    LAST_PRE_STATUS="$pre_status"
    # shellcheck disable=SC2034
    LAST_POST_STATUS="$post_status"

    if [ $status -eq 0 ]; then
        log "  Repositório $repo_name atualizado com sucesso"
    else
        aviso_log "  Repositório $repo_name atualizado com avisos ou erros"
    fi
    if [ "${JSON_OUTPUT:-false}" != true ]; then
        echo "-----------------------------------------"
    fi

    return $status
}
