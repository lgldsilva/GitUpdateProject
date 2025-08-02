#!/bin/bash

# Módulo de barra de progresso
# Este arquivo contém as funções para exibir progresso das operações

# Carregar dependências
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Função para desenhar a barra de progresso
draw_progress_bar() {
    # Se não temos repositórios, não exibir a barra
    if [ "$TOTAL_REPOS" -eq 0 ]; then
        return
    fi
    
    # Calcular porcentagem
    local percent=$((100 * PROCESSED_REPOS / TOTAL_REPOS))
    
    # Calcular número de caracteres preenchidos na barra
    local filled=$((PROGRESS_BAR_WIDTH * PROCESSED_REPOS / TOTAL_REPOS))
    
    # Se temos pelo menos um repositório processado, garantir pelo menos um caractere
    if [ "$PROCESSED_REPOS" -gt 0 ] && [ $filled -eq 0 ]; then
        filled=1
    fi
    
    local empty=$((PROGRESS_BAR_WIDTH - filled))
    
    # Construir a barra de progresso
    local progress_bar=""
    for ((i=0; i<filled; i++)); do
        progress_bar="${progress_bar}${PROGRESS_BAR_CHAR}"
    done
    
    for ((i=0; i<empty; i++)); do
        progress_bar="${progress_bar}${EMPTY_BAR_CHAR}"
    done
    
    # Mover cursor para o início da linha e limpar (compatível com Windows)
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows Git Bash - usar método mais simples
        echo -ne "\r$(printf '%*s' 80 '')\r"
    else
        # Linux/macOS - usar escape ANSI
        echo -ne "\r\033[K"
    fi
    
    # Exibir barra de progresso com porcentagem
    echo -ne "Progresso: [${progress_bar}] ${percent}% (${PROCESSED_REPOS}/${TOTAL_REPOS})"
}

# Função para incrementar o progresso
increment_progress() {
    ((PROCESSED_REPOS++))
    draw_progress_bar
}

# Função para resetar o progresso
reset_progress() {
    PROCESSED_REPOS=0
    draw_progress_bar
}

# Função para finalizar a barra de progresso
finish_progress_bar() {
    if [ "$TOTAL_REPOS" -gt 0 ]; then
        echo  # Nova linha após a barra de progresso
    fi
}
