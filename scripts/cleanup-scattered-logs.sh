#!/bin/bash

# Script para limpar arquivos updateGit.log espalhados pelos repositórios
# Este script encontra e remove arquivos de log antigos que foram criados antes da correção

# Remover set -e para melhor tratamento de erros
# set -e

# Carregar cores
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh" 2>/dev/null || {
    # Fallback se não conseguir carregar as cores
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    RESET='\033[0m'
}

echo -e "${BLUE}🧹 GitUpdate - Limpeza de Logs Espalhados${RESET}"
echo "============================================="
echo ""

# Função de logging
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

# Verificar se foi fornecido um diretório
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Uso:${RESET} $0 <diretório_raiz> [--dry-run]"
    echo ""
    echo -e "${YELLOW}Parâmetros:${RESET}"
    echo "  diretório_raiz   Diretório onde procurar por logs espalhados"
    echo "  --dry-run        Apenas mostrar o que seria removido, sem remover"
    echo ""
    echo -e "${YELLOW}Exemplo:${RESET}"
    echo "  $0 ~/Projetos           # Limpar logs em ~/Projetos"
    echo "  $0 ~/Projetos --dry-run # Apenas mostrar o que seria removido"
    exit 1
fi

ROOT_DIR="$1"
DRY_RUN=false

# Verificar parâmetro --dry-run
if [ "$2" = "--dry-run" ]; then
    DRY_RUN=true
    warn "Modo DRY-RUN ativado - nenhum arquivo será removido"
fi

# Verificar se o diretório existe
if [ ! -d "$ROOT_DIR" ]; then
    error "Diretório não encontrado: $ROOT_DIR"
    exit 1
fi

log "Procurando arquivos updateGit.log em: $ROOT_DIR"
echo ""

# Contador de arquivos encontrados
found_count=0
removed_count=0

# Procurar arquivos updateGit.log (excludindo o diretório de logs centralizados)
# Usar array para armazenar os resultados e evitar problemas com process substitution
mapfile -t log_files < <(find "$ROOT_DIR" -name "updateGit.log" -type f 2>/dev/null)

for log_file in "${log_files[@]}"; do
    # Pular se for o arquivo de log centralizado
    if [[ "$log_file" == *"/.local/share/GitUpdateProject/logs/"* ]]; then
        continue
    fi
    
    ((found_count++))
    
    # Mostrar informações do arquivo - simplificar para evitar travamento
    file_size="$(ls -lh "$log_file" 2>/dev/null | awk '{print $5}' || echo "?")"
    file_date="$(ls -l "$log_file" 2>/dev/null | awk '{print $6" "$7" "$8}' || echo "desconhecida")"
    
    echo -e "${CYAN}Encontrado:${RESET} $log_file"
    echo -e "  Tamanho: $file_size | Data: $file_date"
    
    if [ "$DRY_RUN" = false ]; then
        if rm -f "$log_file" 2>/dev/null; then
            echo -e "  ${GREEN}✓ Removido${RESET}"
            ((removed_count++))
        else
            echo -e "  ${RED}✗ Erro ao remover${RESET}"
        fi
    else
        echo -e "  ${YELLOW}[DRY-RUN] Seria removido${RESET}"
    fi
    echo ""
done

# Também procurar por padrões updateGit_*.log (caso existam)
mapfile -t timestamped_log_files < <(find "$ROOT_DIR" -name "updateGit_*.log" -type f 2>/dev/null)

for log_file in "${timestamped_log_files[@]}"; do
    # Pular se for o arquivo de log centralizado
    if [[ "$log_file" == *"/.local/share/GitUpdateProject/logs/"* ]]; then
        continue
    fi
    
    ((found_count++))
    
    # Mostrar informações do arquivo - simplificar para evitar travamento
    file_size="$(ls -lh "$log_file" 2>/dev/null | awk '{print $5}' || echo "?")"
    file_date="$(ls -l "$log_file" 2>/dev/null | awk '{print $6" "$7" "$8}' || echo "desconhecida")"
    
    echo -e "${CYAN}Encontrado:${RESET} $log_file"
    echo -e "  Tamanho: $file_size | Data: $file_date"
    
    if [ "$DRY_RUN" = false ]; then
        if rm -f "$log_file" 2>/dev/null; then
            echo -e "  ${GREEN}✓ Removido${RESET}"
            ((removed_count++))
        else
            echo -e "  ${RED}✗ Erro ao remover${RESET}"
        fi
    else
        echo -e "  ${YELLOW}[DRY-RUN] Seria removido${RESET}"
    fi
    echo ""
done

# Resumo
echo -e "${GREEN}===== RESUMO =====${RESET}"

if [ $found_count -eq 0 ]; then
    success "Nenhum arquivo de log espalhado encontrado! 🎉"
else
    log "Arquivos de log encontrados: $found_count"
    
    if [ "$DRY_RUN" = false ]; then
        if [ $removed_count -eq $found_count ]; then
            success "Todos os $removed_count arquivos foram removidos com sucesso! 🎉"
        else
            warn "Removidos: $removed_count de $found_count arquivos"
            warn "Alguns arquivos podem não ter sido removidos devido a permissões"
        fi
    else
        warn "Modo DRY-RUN: $found_count arquivos seriam removidos"
        echo ""
        echo -e "${YELLOW}Para remover os arquivos, execute:${RESET}"
        echo "  $0 $ROOT_DIR"
    fi
fi

echo ""
log "A partir de agora, os logs serão salvos centralizadamente em:"
log "  ~/.local/share/GitUpdateProject/logs/"
echo ""
