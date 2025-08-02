#!/bin/bash

# Módulo de configurações globais
# Este arquivo contém todas as variáveis de configuração do sistema

# Carregar cores
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Variáveis globais para a barra de progresso
export TOTAL_REPOS=0
export PROCESSED_REPOS=0
export PROGRESS_BAR_WIDTH=50

# Caracteres da barra de progresso - adaptar ao sistema
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows Git Bash - usar caracteres ASCII simples para compatibilidade
    export PROGRESS_BAR_CHAR="#"
    export EMPTY_BAR_CHAR="-"
else
    # Linux/macOS - usar caracteres Unicode para visual melhor
    export PROGRESS_BAR_CHAR="█"
    export EMPTY_BAR_CHAR="░"
fi

# Configurações de execução
export DEBUG_MODE=false
export FOLLOW_SYMLINKS=false
export SKIP_AUTH=true      # Por padrão, pular repositórios que requerem autenticação
export FORCE_PULL=false    # Por padrão, não forçar pull

# Configurações de log
export LOG_FILE="updateGit.log"

# Configurações Git
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS="/bin/echo"

# Função para configurar as variáveis baseado nos parâmetros
configure_settings() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -d|--debug)
                DEBUG_MODE=true
                shift
                ;;
            -L|--follow-symlinks)
                FOLLOW_SYMLINKS=true
                shift
                ;;
            -a|--allow-auth)
                SKIP_AUTH=false
                shift
                ;;
            -f|--force)
                FORCE_PULL=true
                shift
                ;;
            *)
                # Retornar argumentos não processados
                echo "$@"
                return 0
                ;;
        esac
    done
}
