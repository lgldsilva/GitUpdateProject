#!/bin/bash

# GitUpdate System v2.0 - Sistema Modular de Atualização de Repositórios Git
# Script principal que orquestra todos os módulos do sistema

# Definir diretório base do sistema
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Carregar todos os módulos necessários
source "$LIB_DIR/colors.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/progress.sh"
source "$LIB_DIR/ui.sh"
source "$LIB_DIR/repo_finder.sh"
source "$LIB_DIR/repo_updater.sh"

# Função principal do sistema
main() {
    # Mostrar cabeçalho
    show_header
    
    # Processar parâmetros da linha de comando
    local root_dir=$PWD
    local remaining_args
    
    # Configurar settings baseado nos parâmetros
    remaining_args=$(configure_settings "$@")
    
    # Processar argumentos restantes
    if [ -n "$remaining_args" ]; then
        for arg in $remaining_args; do
            case "$arg" in
                -h|--help)
                    show_help
                    ;;
                *)
                    if [ -d "$arg" ]; then
                        root_dir="$arg"
                    else
                        erro_log "Erro: O diretório '$arg' não existe."
                        erro_log "Use $0 --help para mais informações."
                        exit 1
                    fi
                    ;;
            esac
        done
    fi
    
    # Log inicial
    log "Iniciando GitUpdate System v2.0"
    log "Data de execução: $(date)"
    log "Diretório de trabalho: $root_dir"
    
    # Informar sobre configurações ativas
    if [ "$DEBUG_MODE" = true ]; then
        log "Modo de depuração: ATIVADO"
    fi
    
    if [ "$FOLLOW_SYMLINKS" = true ]; then
        log "Seguir links simbólicos: ATIVADO"
    fi
    
    if [ "$FORCE_PULL" = true ]; then
        log "Pull forçado: ATIVADO (git pull --force)"
    fi
    
    # Informar sobre o modo de autenticação
    if [ "$SKIP_AUTH" = true ]; then
        log "Modo sem autenticação: repositórios que solicitam senha serão ignorados (use -a para permitir autenticação)"
    else
        log "Modo com autenticação: o Git pode solicitar credenciais para repositórios protegidos"
    fi
    
    # Verificar se o diretório raiz é um link simbólico
    if [ -L "$root_dir" ]; then
        local link_target
        link_target=$(readlink -f "$root_dir")
        log "Diretório raiz é um link simbólico apontando para: $link_target"
        
        if [ "$FOLLOW_SYMLINKS" = true ]; then
            log "Links simbólicos serão seguidos durante a busca por repositórios"
        else
            log "Links simbólicos NÃO serão seguidos (use -L para seguir links simbólicos)"
        fi
    fi
    
    # Salvar o diretório inicial
    local initial_dir=$PWD
    
    # Contadores
    local total_repos=0
    local updated_repos=0
    local failed_repos=0
    
    # Buscar repositórios Git
    if find_git_repositories "$root_dir"; then
        # Inicializar a barra de progresso
        draw_progress_bar
        
        # Processar cada repositório encontrado
        for git_dir in "${FOUND_GIT_DIRS[@]}"; do
            ((total_repos++))
            
            local repo_dir
            repo_dir="$(dirname "$git_dir")"
            local relative_path="${repo_dir#"$root_dir"/}"
            
            log "Encontrado repositório Git: $relative_path"
            
            # Entrar no diretório do repositório
            if cd "$repo_dir"; then
                # Atualizar o repositório
                if update_git_repo "$repo_dir"; then
                    ((updated_repos++))
                else
                    ((failed_repos++))
                fi
            else
                erro_log "Não foi possível acessar o diretório $repo_dir"
                ((failed_repos++))
            fi
            
            # Atualizar progresso
            increment_progress
        done
        
        # Finalizar barra de progresso
        finish_progress_bar
    else
        # Nenhum repositório encontrado
        total_repos=0
    fi
    
    # Voltar para o diretório inicial
    cd "$initial_dir" || exit
    
    # Mostrar resumo da execução
    show_summary "$total_repos" "$updated_repos" "$failed_repos"
    
    # Aguardar entrada do usuário
    wait_for_user
    
    # Código de saída baseado nos resultados
    if [ $failed_repos -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Executar função principal com todos os argumentos
main "$@"
