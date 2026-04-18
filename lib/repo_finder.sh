#!/bin/bash

# Módulo de descoberta de repositórios
# Encontra .git (tanto dirs quanto arquivos — worktrees/submódulos).

# Include guard
[[ -n "${_REPO_FINDER_SH_LOADED:-}" ]] && return 0
_REPO_FINDER_SH_LOADED=1

# shellcheck source=lib/logger.sh
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
# shellcheck source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
# shellcheck source=lib/excludes.sh
source "$(dirname "${BASH_SOURCE[0]}")/excludes.sh"

# Dado um .git (dir ou arquivo), retorna o diretório do repo pai.
_repo_parent_of_gitpath() {
    local gitpath="$1"
    dirname "$gitpath"
}

# Detecta se um .git path pertence a um submódulo (arquivo .git com "gitdir:" apontando
# para .git/modules/... do repo pai). Retorna 0 se for submódulo.
_is_submodule_gitfile() {
    local gitfile="$1"
    [ -f "$gitfile" ] || return 1
    grep -qE '^gitdir:.*/\.git/modules/' "$gitfile" 2>/dev/null
}

# Filtra repos aninhados dentro de outro repo já encontrado.
# (Um clone dentro de outro clone normalmente é acidente — atualizar ambos pode
# gerar confusão. Mantemos apenas o mais externo.)
_filter_nested_repos() {
    local -a input=("$@")
    local -a output=()
    local i j parent_i parent_j is_nested

    # Ordenar por profundidade crescente (menos "/" primeiro) para manter externos
    # shellcheck disable=SC2207
    IFS=$'\n' input=($(printf '%s\n' "${input[@]}" | awk '{print gsub(/\//,"&"), $0}' | sort -n | cut -d' ' -f2-))
    unset IFS

    for ((i=0; i<${#input[@]}; i++)); do
        parent_i="$(_repo_parent_of_gitpath "${input[i]}")"
        is_nested=false
        for ((j=0; j<${#output[@]}; j++)); do
            parent_j="$(_repo_parent_of_gitpath "${output[j]}")"
            if [[ "$parent_i" == "$parent_j"/* ]]; then
                is_nested=true
                debug_log "  Ignorando repo aninhado: $parent_i (dentro de $parent_j)"
                break
            fi
        done
        [ "$is_nested" = false ] && output+=("${input[i]}")
    done

    FOUND_GIT_DIRS=("${output[@]}")
}

find_git_repositories() {
    local root_dir="${1:?ERRO: diretório raiz não especificado}"
    local -a candidates=()

    log "Procurando repositórios Git em: $root_dir"
    load_gitupdateignore "$root_dir"

    local -a find_args=()
    [ "$FOLLOW_SYMLINKS" = true ] && find_args+=("-L")

    # Buscar tanto dirs quanto arquivos chamados ".git"
    # (worktrees criam arquivo .git; submódulos também — filtraremos submódulos abaixo)
    while IFS= read -r -d '' entry; do
        candidates+=("$entry")
    done < <(find "${find_args[@]}" "$root_dir" \
                \( -type d -o -type f \) -name ".git" -print0 2>/dev/null)

    if [ ${#candidates[@]} -eq 0 ]; then
        log "Nenhum repositório Git encontrado em $root_dir"
        FOUND_GIT_DIRS=()
        TOTAL_REPOS=0
        return 1
    fi

    # Filtrar: (a) submódulos (serão atualizados via --submodules), (b) excluídos
    local -a kept=()
    local gitpath parent
    for gitpath in "${candidates[@]}"; do
        if _is_submodule_gitfile "$gitpath"; then
            debug_log "  Pulando submódulo: $gitpath"
            continue
        fi
        parent="$(_repo_parent_of_gitpath "$gitpath")"
        if should_exclude_path "$parent" "$root_dir"; then
            debug_log "  Excluído por padrão: $parent"
            continue
        fi
        kept+=("$gitpath")
    done

    if [ ${#kept[@]} -eq 0 ]; then
        log "Nenhum repositório Git restou após filtros"
        # shellcheck disable=SC2034
        FOUND_GIT_DIRS=()
        # shellcheck disable=SC2034
        TOTAL_REPOS=0
        return 1
    fi

    # Remover aninhados (clone dentro de clone)
    _filter_nested_repos "${kept[@]}"

    # shellcheck disable=SC2034
    TOTAL_REPOS=${#FOUND_GIT_DIRS[@]}
    log "Encontrados $TOTAL_REPOS repositório(s) Git (após filtros)"

    if [ "$DEBUG_MODE" = true ]; then
        for git_dir in "${FOUND_GIT_DIRS[@]}"; do
            debug_log "  $git_dir"
        done
    fi

    return 0
}
