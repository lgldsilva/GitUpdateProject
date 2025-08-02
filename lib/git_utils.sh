#!/bin/bash

# Módulo de utilitários Git
# Este arquivo contém funções auxiliares para operações Git

# Carregar dependências
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Função para verificar se um remote é válido
check_remote_valid() {
    local remote="$1"
    if git ls-remote --exit-code "$remote" &>/dev/null; then
        debug_log "  Remote '$remote' está acessível"
        return 0
    else
        aviso_log "  Remote '$remote' não está acessível"
        return 1
    fi
}

# Função para executar comando git com tratamento de erro
run_git_command() {
    local cmd="$1"
    local error_msg="$2"
    local debug_error="$3"
    local output_file="/tmp/git_command_output.$$"
    local status=0
    
    $cmd > "$output_file" 2>&1 || {
        status=$?
        aviso_log "$error_msg ($status)"
        if [ "$DEBUG_MODE" = true ] && [ "$debug_error" = true ]; then
            debug_log "  Detalhes do erro: $(head -5 "$output_file")"
        fi
        rm -f "$output_file"
        return $status
    }
    
    rm -f "$output_file"
    return 0
}

# Função para verificar se uma branch remota existe
check_branch_exists() {
    local remote="$1"
    local branch="$2"
    
    if git ls-remote --exit-code --heads "$remote" "$branch" &>/dev/null; then
        return 0  # Branch existe
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
        
        # Verificar quais remotes são acessíveis
        for remote in "${remotes[@]}"; do
            check_remote_valid "$remote"
        done
    fi
    
    # Retornar informações via variáveis globais
    export CURRENT_BRANCH="$current_branch"
    export REPO_REMOTES=("${remotes[@]}")
}

# Função para realizar operações git comuns
perform_git_operation() {
    local operation="$1"
    local command="$2"
    local error_type="$3"  # "erro" ou "aviso"
    local cmd_status=0
    
    log "  $operation"
    run_git_command "$command" "  $error_type ao $operation" true
    cmd_status=$?
    
    return $cmd_status
}
