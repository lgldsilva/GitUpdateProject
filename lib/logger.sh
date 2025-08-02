#!/bin/bash

# Módulo de logging
# Este arquivo contém todas as funções relacionadas ao sistema de logs

# Carregar dependências
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Função base para logging central
_log_base() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local tag="$1"
    local color="$2"
    local message="$3"
    local to_console="${4:-true}"
    local with_timestamp="${5:-true}"
    
    # Montar mensagem colorida para console
    local colored_message=""
    if [ "$with_timestamp" = true ]; then
        colored_message="[$timestamp] ${color}${tag}${RESET} ${message}"
    else
        colored_message="${color}${tag}${RESET} ${message}"
    fi
    
    # Montar mensagem sem cores para arquivo de log
    local plain_message=""
    if [ "$with_timestamp" = true ]; then
        plain_message="[$timestamp] ${tag} ${message}"
    else
        plain_message="${tag} ${message}"
    fi
    
    # Exibir no console se solicitado
    if [ "$to_console" = true ]; then
        echo -e "${colored_message}"
    fi
    
    # Sempre salvar no arquivo de log
    echo "${plain_message}" >> "$LOG_FILE"
}

# Função para exibir texto simples sem timestamp
print_text() {
    local message="$1"
    local color="${2:-}"
    
    _log_base "" "$color" "$message" true false
}

# Função para logging geral
log() {
    local message="$1"
    local to_console="${2:-true}"
    
    # Substituir [ERRO], [AVISO] e [SUCESSO] pelas versões coloridas
    if [[ "$message" == *"[ERRO]"* ]]; then
        message="${message/[ERRO]/$ERRO_TAG}"
    elif [[ "$message" == *"[AVISO]"* ]]; then
        message="${message/[AVISO]/$AVISO_TAG}"
    elif [[ "$message" == *"[SUCESSO]"* ]]; then
        message="${message/[SUCESSO]/$SUCESSO_TAG}"
    fi
    
    _log_base "" "" "$message" "$to_console"
}

# Função para logging de debug
debug_log() {
    local message="$1"
    local to_console="${2:-true}"
    
    if [ "$DEBUG_MODE" = true ]; then
        _log_base "[DEBUG]" "${CYAN}" "$message" "$to_console"
    fi
}

# Função para mostrar erros (sempre em vermelho)
erro_log() {
    local message="$1"
    local to_console="${2:-true}"
    
    _log_base "[ERRO]" "${RED}" "$message" "$to_console"
}

# Função para mostrar avisos (sempre em amarelo)
aviso_log() {
    local message="$1"
    local to_console="${2:-true}"
    
    _log_base "[AVISO]" "${YELLOW}" "$message" "$to_console"
}

# Função para mostrar sucessos (sempre em verde)
sucesso_log() {
    local message="$1"
    local to_console="${2:-true}"
    
    _log_base "[SUCESSO]" "${GREEN}" "$message" "$to_console"
}

# Função para mostrar informações (sempre em azul)
info_log() {
    local message="$1"
    local to_console="${2:-true}"
    
    _log_base "[INFO]" "${BLUE}" "$message" "$to_console"
}
