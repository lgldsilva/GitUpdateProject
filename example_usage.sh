#!/bin/bash

# Exemplo de uso dos módulos independentemente
# Este script demonstra como usar os módulos do GitUpdate System em outros projetos

# Definir diretório da biblioteca
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

# Exemplo 1: Usando apenas o sistema de logging
echo "=== Exemplo 1: Sistema de Logging ==="
source "$LIB_DIR/colors.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/logger.sh"

log "Esta é uma mensagem de log normal"
debug_log "Esta é uma mensagem de debug (só aparece em modo debug)"
erro_log "Esta é uma mensagem de erro"
aviso_log "Esta é uma mensagem de aviso"
sucesso_log "Esta é uma mensagem de sucesso"
info_log "Esta é uma mensagem informativa"

echo ""

# Exemplo 2: Usando barra de progresso
echo "=== Exemplo 2: Barra de Progresso ==="
source "$LIB_DIR/progress.sh"

TOTAL_REPOS=10
PROCESSED_REPOS=0

echo "Simulando processamento de 10 itens:"
for i in $(seq 1 10); do
    increment_progress
    sleep 0.5
done
finish_progress_bar

echo ""

# Exemplo 3: Usando utilitários Git (se estivermos em um repositório Git)
echo "=== Exemplo 3: Utilitários Git ==="
source "$LIB_DIR/git_utils.sh"

if git rev-parse --git-dir > /dev/null 2>&1; then
    log "Detectado repositório Git, obtendo informações..."
    get_repo_info
    
    if [ -n "$CURRENT_BRANCH" ]; then
        info_log "Branch atual: $CURRENT_BRANCH"
    fi
    
    if [ ${#REPO_REMOTES[@]} -gt 0 ]; then
        info_log "Remotes encontrados: ${REPO_REMOTES[*]}"
    fi
else
    aviso_log "Não estamos em um repositório Git"
fi

echo ""

# Exemplo 4: Interface de usuário
echo "=== Exemplo 4: Interface de Usuário ==="
source "$LIB_DIR/ui.sh"

show_header
show_summary 5 4 1

echo ""
echo "Este exemplo demonstra como os módulos podem ser reutilizados!"
