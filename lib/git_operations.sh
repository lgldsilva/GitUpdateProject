#!/bin/bash

# Módulo de operações de pull/atualização
# Este arquivo contém as funções principais para atualizar repositórios Git

# Carregar dependências
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/git_utils.sh"

# Função para executar pull e verificar alterações
execute_pull() {
    local cmd="$1"         # Comando completo de pull
    local use_timeout="$2" # true ou false
    local item_name="$3"   # Nome do item (ex: "Branch master", "Pull genérico")
    local output_file="/tmp/git_pull_output.$$"
    local status=0
    
    # Verificar o hash antes do pull
    local before_hash
    before_hash=$(git rev-parse HEAD 2>/dev/null)
    
    # Executar o comando (com ou sem timeout)
    if [ "$use_timeout" = true ]; then
        # Capturar saída de erro também para debug
        timeout 10 "$cmd" > "$output_file" 2>&1 || {
            status=$?
            if [ $status -eq 124 ]; then
                aviso_log "  Timeout ao atualizar $item_name (possível solicitação de credenciais)"
            else
                aviso_log "  Falha ao atualizar $item_name ($status)"
                if [ "$DEBUG_MODE" = true ]; then
                    debug_log "  Detalhes do erro: $(head -5 "$output_file")"
                fi
            fi
            rm -f "$output_file"
            return $status
        }
    else
        # Capturar saída de erro também para debug
        $cmd > "$output_file" 2>&1 || {
            status=$?
            aviso_log "  Falha ao atualizar $item_name ($status)"
            if [ "$DEBUG_MODE" = true ]; then
                debug_log "  Detalhes do erro: $(head -5 "$output_file")"
            fi
            rm -f "$output_file"
            return $status
        }
    fi
    
    # Se chegamos aqui, o comando foi bem sucedido
    # Verificar mudanças
    local after_hash
    after_hash=$(git rev-parse HEAD 2>/dev/null)
    if [ "$before_hash" != "$after_hash" ]; then
        # Verificar quantos commits foram trazidos
        local num_commits
        num_commits=$(git log --pretty=oneline "${before_hash}".."${after_hash}" 2>/dev/null | wc -l)
        sucesso_log "  $item_name: Baixados $num_commits novos commits"
        # Mostrar informações sobre os commits
        git log --pretty=format:"    %h - %s (%an, %ar)" -n 3 "${before_hash}".."${after_hash}" 2>/dev/null
        echo ""
    else
        sucesso_log "  $item_name: Já está atualizado"
    fi
    
    rm -f "$output_file"
    return ${status:-0}
}

# Função para atualizar uma branch específica de um remote
update_branch() {
    local remote="$1"
    local branch="$2"
    local local_status=0
    
    # Verificar se o remote é válido
    if ! check_remote_valid "$remote"; then
        return 1
    fi
    
    # Verificar se a branch remota existe
    if check_branch_exists "$remote" "$branch"; then
        log "  Atualizando branch $branch do remote $remote"
        
        # Montar o comando de pull
        local pull_cmd=""
        local item_name="Branch $branch"
        
        # Se a opção de força estiver ativada
        if [ "$FORCE_PULL" = true ]; then
            pull_cmd="git pull --force $remote $branch:$branch"
            item_name="Branch $branch (forçado)"
        else
            pull_cmd="git pull $remote $branch:$branch"
        fi
        
        # Executar o pull com ou sem timeout, dependendo da configuração
        execute_pull "$pull_cmd" "$SKIP_AUTH" "$item_name"
        local_status=$?
        
        return $local_status
    fi
    return 1  # Branch não encontrada
}

# Função para verificar e atualizar uma lista de branches padrão
check_standard_branches() {
    local remote="$1"
    local default_branches=("master" "main" "develop")
    local local_branch_found=false
    local update_status=0
    
    for branch in "${default_branches[@]}"; do
        if update_branch "$remote" "$branch"; then
            local_branch_found=true
            update_status=$?
            [ $update_status -ne 0 ] && return 1
        fi
    done
    
    if [ "$local_branch_found" = true ]; then
        return 0  # Sucesso (pelo menos uma branch padrão foi encontrada)
    else
        return 1  # Falha (nenhuma branch padrão foi encontrada)
    fi
}

# Função para realizar o pull genérico
do_pull() {
    local remote="$1"
    local use_timeout="$2"
    
    # Verificar se o remote é válido
    if ! check_remote_valid "$remote"; then
        erro_log "  Pull genérico falhou: remote inválido"
        return 1
    fi
    
    log "  Tentando pull genérico do remote $remote"
    
    # Montar o comando de pull
    local pull_cmd=""
    local item_name="Pull genérico"
    local pull_status=0
    
    # Se a opção de força estiver ativada
    if [ "$FORCE_PULL" = true ]; then
        pull_cmd="git pull --force $remote"
        item_name="Pull genérico (forçado)"
    else
        pull_cmd="git pull $remote"
    fi
    
    # Executar o pull com timeout ou não
    execute_pull "$pull_cmd" "$use_timeout" "$item_name"
    pull_status=$?
    
    if [ $pull_status -ne 0 ]; then
        erro_log "  Pull genérico falhou com status $pull_status"
    fi
    
    return $pull_status
}

# Função para tentar pull genérico quando nenhuma branch específica foi encontrada
try_generic_pull() {
    if [ ${#REPO_REMOTES[@]} -gt 0 ]; then
        log "  Nenhuma branch padrão ou atual encontrada, tentando pull genérico do remote ${REPO_REMOTES[0]}"
        
        local use_timeout=$SKIP_AUTH
        # Usar timeout para evitar ficar preso em solicitação de senha
        do_pull "${REPO_REMOTES[0]}" "$use_timeout"
        return $?
    else
        erro_log "  Não foi possível atualizar o repositório: nenhum remote definido"
        return 1
    fi
}
