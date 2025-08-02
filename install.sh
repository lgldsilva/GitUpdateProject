#!/bin/bash

# Script de instalação do GitUpdate System v2.0
# Este script configura o sistema e cria links simbólicos para fácil acesso

set -e

# Cores para output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# Função para logging
log() {
    echo -e "${GREEN}[INFO]${RESET} $1"
}

warn() {
    echo -e "${YELLOW}[AVISO]${RESET} $1"
}

error() {
    echo -e "${RED}[ERRO]${RESET} $1"
}

success() {
    echo -e "${GREEN}[SUCESSO]${RESET} $1"
}

# Mostrar cabeçalho
echo -e "${BLUE}========================================${RESET}"
echo -e "${BLUE} GitUpdate System v2.0 - Instalação${RESET}"
echo -e "${BLUE}========================================${RESET}"
echo ""

# Definir diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
LINK_NAME="git-update"

log "Diretório do sistema: $SCRIPT_DIR"
log "Diretório de instalação: $INSTALL_DIR"

# Verificar se o diretório de instalação existe
if [ ! -d "$INSTALL_DIR" ]; then
    log "Criando diretório $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
fi

# Verificar se o diretório está no PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    warn "O diretório $INSTALL_DIR não está no seu PATH"
    warn "Adicione a seguinte linha ao seu ~/.bashrc ou ~/.zshrc:"
    echo -e "${YELLOW}export PATH=\"\$PATH:$INSTALL_DIR\"${RESET}"
    echo ""
fi

# Verificar se já existe uma instalação
if [ -L "$INSTALL_DIR/$LINK_NAME" ]; then
    warn "Link simbólico já existe em $INSTALL_DIR/$LINK_NAME"
    read -p "Deseja sobrescrever? (s/N): " response
    if [[ ! "$response" =~ ^[Ss]$ ]]; then
        log "Instalação cancelada"
        exit 0
    fi
    rm "$INSTALL_DIR/$LINK_NAME"
fi

# Tornar o script principal executável
chmod +x "$SCRIPT_DIR/updateGit_v2.sh"
chmod +x "$SCRIPT_DIR/example_usage.sh"

# Criar link simbólico
log "Criando link simbólico: $INSTALL_DIR/$LINK_NAME -> $SCRIPT_DIR/updateGit_v2.sh"
ln -s "$SCRIPT_DIR/updateGit_v2.sh" "$INSTALL_DIR/$LINK_NAME"

# Verificar se a instalação foi bem-sucedida
if [ -L "$INSTALL_DIR/$LINK_NAME" ]; then
    success "Instalação concluída com sucesso!"
    echo ""
    log "Agora você pode usar o sistema com:"
    echo -e "${GREEN}  $LINK_NAME [diretório] [opções]${RESET}"
    echo ""
    log "Exemplos:"
    echo -e "${BLUE}  $LINK_NAME ~/Projetos -d${RESET}     # Debug mode"
    echo -e "${BLUE}  $LINK_NAME ~/Projetos -L${RESET}     # Seguir links simbólicos"
    echo -e "${BLUE}  $LINK_NAME ~/Projetos -a${RESET}     # Permitir autenticação"
    echo -e "${BLUE}  $LINK_NAME --help${RESET}            # Exibir ajuda"
    echo ""
    
    # Verificar se conseguimos executar
    if command -v "$LINK_NAME" >/dev/null 2>&1; then
        success "Comando '$LINK_NAME' está disponível no PATH"
    else
        warn "Comando '$LINK_NAME' não foi encontrado no PATH"
        warn "Você pode precisar recarregar seu shell ou adicionar $INSTALL_DIR ao PATH"
    fi
else
    error "Falha na criação do link simbólico"
    exit 1
fi

echo "
