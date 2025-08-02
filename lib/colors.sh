#!/bin/bash

# Módulo de cores e formatação de texto
# Este arquivo contém as definições de cores e tags coloridas

# Detectar suporte a cores
supports_colors() {
    # Windows Git Bash geralmente suporta cores
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        return 0
    fi
    
    # Verificar se o terminal suporta cores
    if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
        if command -v tput >/dev/null 2>&1; then
            if tput colors >/dev/null 2>&1 && [ "$(tput colors)" -ge 8 ]; then
                return 0
            fi
        fi
        # Fallback para terminais comuns que suportam cores
        case "${TERM:-}" in
            *color*|*256*|screen*|xterm*|rxvt*) return 0 ;;
        esac
    fi
    
    # Verificar variável de ambiente NO_COLOR
    [ -z "${NO_COLOR:-}" ]
}

# Definir cores com base no suporte
if supports_colors; then
    export RED='\033[31m'
    export YELLOW='\033[33m'
    export GREEN='\033[32m'
    export BLUE='\033[34m'
    export MAGENTA='\033[35m'
    export CYAN='\033[36m'
    export WHITE='\033[37m'
    export RESET='\033[0m'
else
    # Sem cores se não há suporte
    export RED=''
    export YELLOW=''
    export GREEN=''
    export BLUE=''
    export MAGENTA=''
    export CYAN=''
    export WHITE=''
    export RESET=''
fi

# Tags coloridas para uso em mensagens
export ERRO_TAG="${RED}[ERRO]${RESET}"
export AVISO_TAG="${YELLOW}[AVISO]${RESET}"
export SUCESSO_TAG="${GREEN}[SUCESSO]${RESET}"
export INFO_TAG="${BLUE}[INFO]${RESET}"
export DEBUG_TAG="${CYAN}[DEBUG]${RESET}"
