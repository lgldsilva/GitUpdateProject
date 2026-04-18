#!/bin/bash

# Módulo de interface de usuário

# Include guard
[[ -n "${_UI_SH_LOADED:-}" ]] && return 0
_UI_SH_LOADED=1

# shellcheck source=lib/colors.sh
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Array paralelo (gerenciado pelo main) com registros de falha:
#   FAILED_REPORT_LINES[i] = "<path>\t<motivo>"
FAILED_REPORT_LINES=()

show_help() {
    cat <<EOF
${GREEN}GitUpdate System v2.1 - Atualização Recursiva de Repositórios Git${RESET}

${YELLOW}Uso:${RESET} git-update [diretório] [opções]

${YELLOW}Opções básicas:${RESET}
  ${CYAN}-d, --debug${RESET}              Ativa modo de depuração
  ${CYAN}-L, --follow-symlinks${RESET}    Segue links simbólicos na busca
  ${CYAN}-a, --allow-auth${RESET}         Permite solicitação de credenciais
  ${CYAN}-f, --force${RESET}              Pull forçado (git reset --hard)
  ${CYAN}-n, --dry-run${RESET}            Mostra ações sem executar
  ${CYAN}-h, --help${RESET}               Exibe esta ajuda

${YELLOW}Performance:${RESET}
  ${CYAN}-j, --jobs N${RESET}             Processa N repositórios em paralelo (default: 1)
  ${CYAN}--timeout SEC${RESET}            Timeout para ops de rede (default: 10)
  ${CYAN}--retries N${RESET}              Nº de tentativas em falhas de rede (default: 1)

${YELLOW}Operações extras:${RESET}
  ${CYAN}--submodules${RESET}             git submodule update --init --recursive
  ${CYAN}--lfs${RESET}                    git lfs pull (se repo usa LFS)
  ${CYAN}--push${RESET}                   git push após pull bem-sucedido
  ${CYAN}--gc${RESET}                     git gc --auto após atualização
  ${CYAN}--hooks${RESET}                  Executa .gitupdate-hook no repo (se presente)

${YELLOW}Exclusões:${RESET}
  ${CYAN}-x, --exclude PATTERN${RESET}    Exclui repos (glob; pode repetir)
                           Também lê .gitupdateignore no diretório raiz.

${YELLOW}Filtros de saída:${RESET}
  ${CYAN}--only-failed${RESET}            Mostra apenas repos que falharam
  ${CYAN}--only-dirty${RESET}             Mostra apenas repos com alterações locais

${YELLOW}Saída / notificações:${RESET}
  ${CYAN}--json${RESET}                   Saída final em JSON (maquinas/pipelines)
  ${CYAN}--notify${RESET}                 Envia notificação desktop ao fim
  ${CYAN}--webhook URL${RESET}            POST JSON ao fim para a URL

${YELLOW}Configuração persistente:${RESET}
  ~/.config/gitupdate/config    (KEY=VALUE por linha)

${YELLOW}Exemplos:${RESET}
  ${GREEN}git-update ~/Projetos${RESET}                      Atualiza tudo sequencialmente
  ${GREEN}git-update ~/Projetos -j 8 --submodules${RESET}    8 workers + submódulos
  ${GREEN}git-update ~/Projetos -n${RESET}                   Dry-run
  ${GREEN}git-update ~/Projetos --json > status.json${RESET} Saída estruturada

EOF
    return 0
}

show_header() {
    echo -e "${GREEN}========================================${RESET}"
    echo -e "${GREEN} GitUpdate System v2.1 - Modular${RESET}"
    echo -e "${GREEN}========================================${RESET}"
    echo ""
}

show_summary() {
    local total_repos="$1"
    local updated_repos="$2"
    local failed_repos="$3"

    # Se ONLY_FAILED, só mostra falhas (sem cabeçalho de total)
    if [ "${ONLY_FAILED:-false}" = true ]; then
        if [ "${#FAILED_REPORT_LINES[@]}" -eq 0 ]; then
            sucesso_log "Nenhuma falha 🎉"
            return 0
        fi
        echo ""
        echo -e "${RED}===== REPOSITÓRIOS COM FALHA =====${RESET}"
        local line
        for line in "${FAILED_REPORT_LINES[@]}"; do
            echo -e "  ${RED}✗${RESET} ${line//$'\t'/ — }"
        done
        return 0
    fi

    echo ""
    echo -e "${GREEN}===== RESUMO DA EXECUÇÃO =====${RESET}"
    log "Total de repositórios encontrados: $total_repos"
    log "Repositórios atualizados com sucesso: $updated_repos"

    if [ "$failed_repos" -gt 0 ]; then
        aviso_log "Repositórios com problemas: $failed_repos"
        if [ "${#FAILED_REPORT_LINES[@]}" -gt 0 ]; then
            echo ""
            echo -e "${YELLOW}Detalhes das falhas:${RESET}"
            local line
            for line in "${FAILED_REPORT_LINES[@]}"; do
                echo -e "  ${RED}✗${RESET} ${line//$'\t'/ — }"
            done
        fi
    else
        sucesso_log "✓ Concluído com sucesso! Todos os repositórios foram atualizados."
    fi

    if [ -n "${LOG_FILE:-}" ]; then
        echo ""
        echo -e "${CYAN}📝 Log detalhado salvo em: $LOG_FILE${RESET}"
    fi
}

record_failure() {
    local path="$1"
    local reason="$2"
    FAILED_REPORT_LINES+=("${path}"$'\t'"${reason}")
}

wait_for_user() {
    # Em modo JSON ou não-interativo, não pausar
    [ "${JSON_OUTPUT:-false}" = true ] && return 0
    [ -t 0 ] || return 0
    echo ""
    read -r -p "Pressione [Enter] para continuar..."
}
