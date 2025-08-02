#!/bin/bash

# Módulo principal de atualização de repositórios
# Este arquivo contém a lógica principal para atualizar um repositório Git

# Carregar dependências
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/git_utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/git_operations.sh"

# Função principal para atualizar um repositório Git
update_git_repo() {
    local repo_path=$1
    local repo_name
    repo_name=$(basename "$repo_path")
    local status=0
    local return_status=0
    local branch_found=false
    
    # Configuração para evitar solicitações de senha
    export GIT_TERMINAL_PROMPT=0
    export GIT_ASKPASS=/bin/echo
    
    log "Atualizando repositório: $repo_name"
    
    # Obter informações do repositório
    get_repo_info
    
    # Realizar operações git comuns
    perform_git_operation "Salvando alterações locais (stash)" "git stash save" "Possível problema"
    local stash_status=$?
    [ $stash_status -ne 0 ] && status=$stash_status
    
    perform_git_operation "Resetando para o estado do repositório remoto" "git reset --hard" "Falha"
    local reset_status=$?
    [ $reset_status -ne 0 ] && status=$reset_status
    
    perform_git_operation "Buscando alterações de todos os remotes" "git fetch --all --prune" "Falha"
    local fetch_status=$?
    [ $fetch_status -ne 0 ] && status=$fetch_status
    
    # Para cada remote, verificar as branches padrão
    for remote in "${REPO_REMOTES[@]}"; do
        debug_log "  Verificando branches disponíveis no remote '$remote' para $repo_name"
        
        # Verificar e atualizar branches padrão
        if check_standard_branches "$remote"; then
            branch_found=true
        fi
        
        # Verificar se a branch atual existe no remote (apenas se não for uma das branches padrão)
        if [ -n "$CURRENT_BRANCH" ] && [ "$CURRENT_BRANCH" != "master" ] && [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "develop" ]; then
            if update_branch "$remote" "$CURRENT_BRANCH"; then
                branch_found=true
                local update_status=$?
                [ $update_status -ne 0 ] && status=1
            fi
        fi
    done
    
    # Se nenhuma branch específica foi encontrada ou atualizada, tente um pull genérico
    if [ "$branch_found" = false ]; then
        try_generic_pull
        status=$?
    fi
    
    # Resumo do resultado da atualização
    if [ $status -eq 0 ]; then
        log "  Repositório $repo_name atualizado com sucesso"
        return_status=0
    else
        aviso_log "  Repositório $repo_name atualizado com avisos ou erros"
        return_status=1
    fi
    echo "-----------------------------------------"
    
    return $return_status
}
