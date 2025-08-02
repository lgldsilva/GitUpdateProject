#!/bin/bash

# Módulo de descoberta de repositórios
# Este arquivo contém funções para encontrar repositórios Git

# Carregar dependências
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Função para encontrar repositórios Git
find_git_repositories() {
    local root_dir="$1"
    local git_dirs=()
    
    log "Procurando repositórios Git em: $root_dir"
    
    # Usar find para procurar diretórios .git em qualquer nível
    if [ "$FOLLOW_SYMLINKS" = true ]; then
        debug_log "Executando: find -L \"$root_dir\" -type d -name \".git\" (seguindo links simbólicos)"
        mapfile -t git_dirs < <(find -L "$root_dir" -type d -name ".git" 2>/dev/null)
    else
        debug_log "Executando: find \"$root_dir\" -type d -name \".git\" (sem seguir links simbólicos)"
        mapfile -t git_dirs < <(find "$root_dir" -type d -name ".git" 2>/dev/null)
    fi
    
    # Verificar se temos permissão para todos os diretórios
    if [ "$DEBUG_MODE" = true ] && [ ${#git_dirs[@]} -eq 0 ]; then
        debug_log "Nenhum diretório .git encontrado, verificando problemas de permissão..."
        local find_result
        if [ "$FOLLOW_SYMLINKS" = true ]; then
            find_result=$(find -L "$root_dir" -type d -name ".git" -o -type d -not -readable 2>&1)
        else
            find_result=$(find "$root_dir" -type d -name ".git" -o -type d -not -readable 2>&1)
        fi
        if [[ $find_result == *"Permission denied"* ]]; then
            debug_log "Problemas de permissão detectados: $find_result"
        fi
        debug_log "Listando diretórios no primeiro nível:"
        ls -la "$root_dir" | while read line; do
            debug_log "  $line"
        done
    fi
    
    # Se não encontrou nenhum repositório
    if [ ${#git_dirs[@]} -eq 0 ]; then
        log "Nenhum repositório Git encontrado em $root_dir"
        
        if [ "$DEBUG_MODE" = true ]; then
            debug_log "Tentando método alternativo com comando find..."
            debug_log "Procurando por diretórios .git com método alternativo:"
            local find_output
            if [ "$FOLLOW_SYMLINKS" = true ]; then
                find_output=$(find -L "$root_dir" -name ".git" -type d 2>&1)
            else
                find_output=$(find "$root_dir" -name ".git" -type d 2>&1)
            fi
            if [ -n "$find_output" ]; then
                echo "$find_output" | while read line; do
                    debug_log "  Encontrado: $line"
                done
            else
                debug_log "  Nenhum diretório .git encontrado com método alternativo"
            fi
        fi
        
        return 1
    else
        log "Encontrados ${#git_dirs[@]} repositórios Git"
        
        if [ "$DEBUG_MODE" = true ]; then
            debug_log "Lista de repositórios encontrados:"
            for git_dir in "${git_dirs[@]}"; do
                debug_log "  $git_dir"
            done
        fi
        
        # Export para uso global
        export FOUND_GIT_DIRS=("${git_dirs[@]}")
        export TOTAL_REPOS=${#git_dirs[@]}
        
        return 0
    fi
}
