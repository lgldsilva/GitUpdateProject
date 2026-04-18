#!/bin/bash

# Módulo de operações git (pull/fetch/submodule/LFS/push/gc)

# Include guard
[[ -n "${_GIT_OPERATIONS_SH_LOADED:-}" ]] && return 0
_GIT_OPERATIONS_SH_LOADED=1

# shellcheck source=lib/logger.sh
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
# shellcheck source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
# shellcheck source=lib/git_utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/git_utils.sh"
# shellcheck source=lib/retry.sh
source "$(dirname "${BASH_SOURCE[0]}")/retry.sh"

# Detecta comando de timeout cross-platform.
# Linux: 'timeout'. macOS (via coreutils): 'gtimeout'. Windows Git Bash: sem timeout.
# Retorna 0 se disponível, ecoando o nome; 1 se não disponível.
_find_timeout_cmd() {
    if command -v timeout >/dev/null 2>&1; then
        echo "timeout"; return 0
    elif command -v gtimeout >/dev/null 2>&1; then
        echo "gtimeout"; return 0
    fi
    return 1
}

# Executa comando git e verifica alterações por hash de ref.
# Uso: execute_pull <use_timeout:bool> <item_name> <check_ref> <cmd...>
execute_pull() {
    local use_timeout="$1"
    local item_name="$2"
    local check_ref="$3"
    shift 3
    local cmd=("$@")

    local output_file
    output_file=$(mktemp -t gitupdate.XXXXXX)
    trap 'rm -f "$output_file"' RETURN

    local status=0
    local before_hash
    before_hash=$(git rev-parse "$check_ref" 2>/dev/null)

    if [ "$DRY_RUN" = true ]; then
        info_log "  [dry-run] $item_name: executaria ${cmd[*]}"
        return 0
    fi

    # Wrapper para a execução (com ou sem timeout)
    local timeout_cmd=""
    if [ "$use_timeout" = true ]; then
        timeout_cmd="$(_find_timeout_cmd || true)"
    fi

    local _attempt_cmd=()
    if [ -n "$timeout_cmd" ]; then
        _attempt_cmd=("$timeout_cmd" "$NETWORK_TIMEOUT" "${cmd[@]}")
    else
        _attempt_cmd=("${cmd[@]}")
    fi

    # Retry apenas para comandos de rede (use_timeout=true). Operações locais não.
    local retries=1
    [ "$use_timeout" = true ] && retries="$MAX_RETRIES"

    retry_cmd "$retries" "${_attempt_cmd[@]}" > "$output_file" 2>&1 || {
        status=$?
        if [ "$status" -eq 124 ]; then
            aviso_log "  Timeout ao atualizar $item_name (possível solicitação de credenciais)"
        else
            aviso_log "  Falha ao atualizar $item_name ($status)"
            [ "$DEBUG_MODE" = true ] && debug_log "  Detalhes: $(head -5 "$output_file")"
        fi
        return "$status"
    }

    local after_hash
    after_hash=$(git rev-parse "$check_ref" 2>/dev/null)
    if [ "$before_hash" != "$after_hash" ]; then
        local num_commits
        num_commits=$(git log --pretty=oneline "${before_hash}".."${after_hash}" 2>/dev/null | wc -l | tr -d ' ')
        sucesso_log "  $item_name: Baixados $num_commits novos commits"
        if [ "${JSON_OUTPUT:-false}" != true ]; then
            git log --pretty=format:"    %h - %s (%an, %ar)" -n 3 "${before_hash}".."${after_hash}" 2>/dev/null
            echo ""
        fi
    else
        sucesso_log "  $item_name: Já está atualizado"
    fi

    return 0
}

update_branch() {
    local remote="${1:?ERRO: remote não especificado}"
    local branch="${2:?ERRO: branch não especificada}"
    local local_status=0

    check_remote_valid "$remote" || return 1

    if check_branch_exists "$remote" "$branch"; then
        log "  Atualizando branch $branch do remote $remote"

        local -a pull_cmd=()
        local item_name="Branch $branch"
        local check_ref="HEAD"

        if [ "$CURRENT_BRANCH" = "$branch" ]; then
            if [ "$FORCE_PULL" = true ]; then
                pull_cmd=(git reset --hard "$remote/$branch")
                item_name="Branch $branch (forçado)"
            else
                pull_cmd=(git merge --ff-only "$remote/$branch")
            fi
            check_ref="HEAD"
        else
            if [ "$FORCE_PULL" = true ]; then
                pull_cmd=(git branch -f "$branch" "$remote/$branch")
                item_name="Branch $branch (forçado)"
            else
                pull_cmd=(git fetch . "refs/remotes/$remote/$branch:refs/heads/$branch")
            fi
            check_ref="refs/heads/$branch"
        fi

        execute_pull false "$item_name" "$check_ref" "${pull_cmd[@]}"
        local_status=$?
        return $local_status
    fi
    return 1
}

check_standard_branches() {
    local remote="${1:?ERRO: remote não especificado}"
    local default_branches=("master" "main" "develop")
    local local_branch_found=false

    for branch in "${default_branches[@]}"; do
        if update_branch "$remote" "$branch"; then
            local_branch_found=true
        fi
    done

    [ "$local_branch_found" = true ]
}

do_pull() {
    local remote="${1:?ERRO: remote não especificado}"
    local use_timeout="${2:-true}"

    check_remote_valid "$remote" || {
        erro_log "  Pull genérico falhou: remote inválido"
        return 1
    }

    log "  Tentando pull genérico do remote $remote"

    local -a pull_cmd=()
    local item_name="Pull genérico"
    local pull_status=0

    if [ "$FORCE_PULL" = true ]; then
        pull_cmd=(git pull --force "$remote")
        item_name="Pull genérico (forçado)"
    else
        pull_cmd=(git pull "$remote")
    fi

    execute_pull "$use_timeout" "$item_name" "HEAD" "${pull_cmd[@]}"
    pull_status=$?

    [ $pull_status -ne 0 ] && erro_log "  Pull genérico falhou com status $pull_status"
    return $pull_status
}

try_generic_pull() {
    if [ ${#REPO_REMOTES[@]} -gt 0 ]; then
        log "  Nenhuma branch padrão ou atual encontrada, tentando pull genérico do remote ${REPO_REMOTES[0]}"
        local use_timeout=$SKIP_AUTH
        do_pull "${REPO_REMOTES[0]}" "$use_timeout"
        return $?
    else
        erro_log "  Não foi possível atualizar o repositório: nenhum remote definido"
        return 1
    fi
}

# =============================================================================
# Novas operações: submodule / LFS / push / gc
# =============================================================================

# Atualiza submódulos recursivamente se o repo os tiver.
update_submodules() {
    [ "$DO_SUBMODULES" = true ] || return 0
    [ -f ".gitmodules" ] || return 0

    if [ "$DRY_RUN" = true ]; then
        info_log "  [dry-run] Atualizaria submódulos"
        return 0
    fi

    log "  Atualizando submódulos (recursive)"
    local timeout_cmd
    timeout_cmd="$(_find_timeout_cmd || true)"
    local -a cmd=(git submodule update --init --recursive)
    if [ -n "$timeout_cmd" ] && [ "$SKIP_AUTH" = true ]; then
        cmd=("$timeout_cmd" "$NETWORK_TIMEOUT" "${cmd[@]}")
    fi

    if retry_cmd "$MAX_RETRIES" "${cmd[@]}" >/dev/null 2>&1; then
        sucesso_log "  Submódulos: atualizados"
        return 0
    else
        aviso_log "  Falha ao atualizar submódulos"
        return 1
    fi
}

# Executa git-lfs pull se o repo usa LFS.
pull_lfs() {
    [ "$DO_LFS" = true ] || return 0
    command -v git-lfs >/dev/null 2>&1 || {
        aviso_log "  git-lfs não instalado, pulando --lfs"
        return 0
    }
    [ -f ".gitattributes" ] && grep -q "filter=lfs" .gitattributes 2>/dev/null || return 0

    if [ "$DRY_RUN" = true ]; then
        info_log "  [dry-run] Rodaria git lfs pull"
        return 0
    fi

    log "  Sincronizando arquivos LFS"
    if git lfs pull >/dev/null 2>&1; then
        sucesso_log "  LFS: sincronizado"
    else
        aviso_log "  Falha ao rodar git lfs pull"
        return 1
    fi
}

# Push dos commits locais não enviados. Usa --push flag.
push_repo() {
    [ "$DO_PUSH" = true ] || return 0

    # Só pusha se há upstream configurado
    local upstream
    upstream=$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null) || return 0

    local ahead
    ahead=$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
    [ "$ahead" -eq 0 ] && return 0

    if [ "$DRY_RUN" = true ]; then
        info_log "  [dry-run] Faria push de $ahead commit(s) para $upstream"
        return 0
    fi

    log "  Push de $ahead commit(s) para $upstream"
    local timeout_cmd
    timeout_cmd="$(_find_timeout_cmd || true)"
    local -a cmd=(git push)
    [ -n "$timeout_cmd" ] && cmd=("$timeout_cmd" "$NETWORK_TIMEOUT" "${cmd[@]}")

    if retry_cmd "$MAX_RETRIES" "${cmd[@]}" >/dev/null 2>&1; then
        sucesso_log "  Push: $ahead commit(s) enviados"
    else
        aviso_log "  Falha no push"
        return 1
    fi
}

# Garbage collection auto.
run_gc() {
    [ "$DO_GC" = true ] || return 0
    if [ "$DRY_RUN" = true ]; then
        info_log "  [dry-run] Rodaria git gc --auto"
        return 0
    fi
    log "  git gc --auto"
    git gc --auto >/dev/null 2>&1 || aviso_log "  gc retornou não-zero"
}
