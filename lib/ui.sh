#!/bin/bash

# Módulo de interface de usuário
# Este arquivo contém funções para interação com o usuário

# Carregar dependências
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Função para exibir ajuda
show_help() {
    echo -e "${GREEN}GitUpdate System - Sistema de Atualização de Repositórios Git${RESET}"
    echo ""
    echo -e "${YELLOW}Uso:${RESET} $0 [diretório_raiz] [opções]"
    echo ""
    echo -e "${YELLOW}Opções:${RESET}"
    echo -e "  ${CYAN}-d, --debug${RESET}              Ativa o modo de depuração"
    echo -e "  ${CYAN}-L, --follow-symlinks${RESET}    Segue links simbólicos ao procurar repositórios Git"
    echo -e "  ${CYAN}-a, --allow-auth${RESET}         Permite solicitação de credenciais para repositórios protegidos"
    echo -e "  ${CYAN}-f, --force${RESET}              Força o pull mesmo se houver divergências (git pull --force)"
    echo -e "  ${CYAN}-h, --help${RESET}               Exibe esta mensagem de ajuda"
    echo ""
    echo -e "${YELLOW}Exemplos:${RESET}"
    echo -e "  ${GREEN}$0 ~/Projetos -L -d${RESET}      Atualiza repositórios em ~/Projetos, seguindo links simbólicos e com depuração"
    echo -e "  ${GREEN}$0 ~/Projetos -a${RESET}         Atualiza repositórios em ~/Projetos, permitindo solicitação de senha"
    echo -e "  ${GREEN}$0 -f${RESET}                    Força atualização no diretório atual"
    echo ""
    echo -e "${YELLOW}Descrição:${RESET}"
    echo -e "  Este sistema modular atualiza automaticamente todos os repositórios Git encontrados"
    echo -e "  no diretório especificado. Por padrão, evita solicitações de senha e segue apenas"
    echo -e "  as branches principais (master, main, develop)."
    echo ""
    exit 0
}

# Função para mostrar o cabeçalho do sistema
show_header() {
    echo -e "${GREEN}========================================${RESET}"
    echo -e "${GREEN} GitUpdate System v2.0 - Modular${RESET}"
    echo -e "${GREEN}========================================${RESET}"
    echo ""
}

# Função para mostrar o resumo da execução
show_summary() {
    local total_repos="$1"
    local updated_repos="$2"
    local failed_repos="$3"
    
    echo ""
    echo -e "${GREEN}===== RESUMO DA EXECUÇÃO =====${RESET}"
    log "Total de repositórios encontrados: $total_repos"
    log "Repositórios atualizados com sucesso: $updated_repos"
    
    if [ $failed_repos -gt 0 ]; then
        aviso_log "Repositórios com problemas: $failed_repos"
    else
        sucesso_log "✓ Concluído com sucesso! Todos os repositórios foram atualizados."
    fi
}

# Função para aguardar entrada do usuário
wait_for_user() {
    echo ""
    read -p "Pressione [Enter] para continuar..."
}
