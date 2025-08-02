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

# Configurações de log centralizadas
# Criar diretório de logs se não existir
LOG_BASE_DIR="${HOME}/.local/share/GitUpdateProject/logs"
mkdir -p "$LOG_BASE_DIR" 2>/dev/null || {
    # Fallback para /tmp se não conseguir criar no home
    LOG_BASE_DIR="/tmp/GitUpdateProject-logs-$(id -u)"
    mkdir -p "$LOG_BASE_DIR" 2>/dev/null || LOG_BASE_DIR="/tmp"
}

# Nome do arquivo de log com timestamp para evitar conflitos
LOG_TIMESTAMP=$(date '+%Y%m%d_%H%M%S' 2>/dev/null || echo "$(date +%s)")
export LOG_FILE="$LOG_BASE_DIR/updateGit_${LOG_TIMESTAMP}.log"

# Função para limpar logs antigos (manter apenas os 10 mais recentes)
cleanup_old_logs() {
    if [ -d "$LOG_BASE_DIR" ] && [ "$(ls -1 "$LOG_BASE_DIR"/updateGit_*.log 2>/dev/null | wc -l)" -gt 10 ]; then
        # Listar arquivos de log ordenados por data de modificação (mais antigos primeiro)
        # e remover todos exceto os 10 mais recentes
        ls -1t "$LOG_BASE_DIR"/updateGit_*.log 2>/dev/null | tail -n +11 | while read -r old_log; do
            rm -f "$old_log" 2>/dev/null
        done
    fi
}

# Executar limpeza de logs antigos
cleanup_old_logs

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
