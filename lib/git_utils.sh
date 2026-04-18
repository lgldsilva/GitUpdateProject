#!/bin/bash

# Módulo de utilitários Git
# Este arquivo contém funções auxiliares para operações Git

# Include guard
[[ -n "${_GIT_UTILS_SH_LOADED:-}" ]] && return 0
_GIT_UTILS_SH_LOADED=1

# Carregar dependências
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Função para verificar se um remote é válido (verificação local, sem rede)
check_remote_valid() {
    local remote="${1:?ERRO: remote não especificado}"
    if git remote get-url "$remote" &>/dev/null; then
        debug_log "  Remote '$remote' está configurado"
        return 0
    else
        aviso_log "  Remote '$remote' não está configurado"
        return 1
    fi
}

# Função para executar comando git com tratamento de erro.
# Uso: run_git_command "<error_msg>" <debug_bool> -- <cmd...>
run_git_command() {
    local error_msg="$1"
    local debug_error="$2"
    shift 2
    # Aceitar um separador opcional "--" antes do comando
    [ "${1:-}" = "--" ] && shift

    local output_file
    output_file=$(mktemp -t git_command_output.XXXXXX)
    trap 'rm -f "$output_file"' RETURN
    local status=0

    "$@" > "$output_file" 2>&1 || {
        status=$?
        aviso_log "$error_msg ($status)"
        if [ "$DEBUG_MODE" = true ] && [ "$debug_error" = true ]; then
            debug_log "  Detalhes do erro: $(head -5 "$output_file")"
        fi
        return $status
    }

    return 0
}

# Função para verificar se uma branch remota existe (usa refs locais após fetch)
check_branch_exists() {
    local remote="${1:?ERRO: remote não especificado}"
    local branch="${2:?ERRO: branch não especificada}"
    
    if git show-ref --verify --quiet "refs/remotes/$remote/$branch" 2>/dev/null; then
        return 0  # Branch existe localmente (após fetch)
    fi
    return 1  # Branch não existe
}

# Função para obter informações do repositório atual
get_repo_info() {
    local current_branch=""
    local remotes=()
    
    # Obter a branch atual
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$current_branch" ] && [ "$current_branch" != "HEAD" ]; then
        debug_log "  Branch atual: $current_branch"
    else
        debug_log "  Não foi possível determinar a branch atual (possivelmente em 'detached HEAD')"
        current_branch=""
    fi
    
    # Obter lista de todos os remotes
    mapfile -t remotes < <(git remote 2>/dev/null)
    if [ ${#remotes[@]} -eq 0 ]; then
        aviso_log "  Nenhum remote encontrado"
    else
        debug_log "  Remotes encontrados: ${remotes[*]}"
    fi
    
    # Retornar informações via variáveis globais consumidas por outros módulos
    # shellcheck disable=SC2034
    CURRENT_BRANCH="$current_branch"
    # shellcheck disable=SC2034
    REPO_REMOTES=("${remotes[@]}")
}

# Função para realizar operações git comuns.
# Uso: perform_git_operation "<operação>" "<tipo_erro>" <cmd...>
perform_git_operation() {
    local operation="$1"
    local error_type="$2"  # "Erro", "Aviso", "Falha", etc.
    shift 2
    local cmd_status=0

    log "  $operation"
    run_git_command "  $error_type ao $operation" true -- "$@"
    cmd_status=$?

    return $cmd_status
}
