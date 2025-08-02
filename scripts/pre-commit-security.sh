#!/bin/bash

# Pre-commit security check script
# This script runs security checks before each commit to prevent accidental exposure of secrets

set -e

# Carregar módulo de utilitários de segurança
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/security_utils.sh"

echo -e "${BLUE}🔒 Executando verificações de segurança pré-commit...${RESET}"

# Check if gitleaks is installed, install if needed
if ! command_exists gitleaks; then
    echo -e "${YELLOW}⚠️ Gitleaks não encontrado. Instalando...${RESET}"
    if ! install_gitleaks; then
        echo -e "${RED}❌ Falha na instalação do Gitleaks${RESET}"
        exit 1
    fi
fi

# Run gitleaks on staged files
echo -e "${BLUE}🔍 Verificando secrets nos arquivos staged...${RESET}"
if ! gitleaks protect --staged --verbose; then
    echo -e "${RED}❌ COMMIT BLOQUEADO: Secrets ou credenciais detectadas!${RESET}"
    echo -e "${YELLOW}📋 Ações recomendadas:${RESET}"
    echo -e "  1. Remova as informações sensíveis dos arquivos"
    echo -e "  2. Use variáveis de ambiente para configurações sensíveis"
    echo -e "  3. Adicione arquivos de configuração ao .gitignore"
    echo -e "  4. Para falsos positivos, atualize .gitleaks.toml"
    exit 1
fi

# Check shell scripts with shellcheck (if available)
if command_exists shellcheck; then
    echo -e "${BLUE}🔍 Verificando scripts shell...${RESET}"
    
    # Find staged shell scripts
    SHELL_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(sh|bash)$' || true)
    
    if [ -n "$SHELL_FILES" ]; then
        echo "Arquivos shell encontrados: $SHELL_FILES"
        
        # Run shellcheck on each file
        SHELLCHECK_ISSUES=0
        for file in $SHELL_FILES; do
            if ! shellcheck "$file"; then
                SHELLCHECK_ISSUES=$((SHELLCHECK_ISSUES + 1))
            fi
        done
        
        if [ $SHELLCHECK_ISSUES -gt 0 ]; then
            echo -e "${YELLOW}⚠️ Issues encontradas no ShellCheck. Revise os scripts antes do commit.${RESET}"
            # Note: We don't exit here as shellcheck issues are warnings, not blockers
        fi
    fi
fi

# Custom security checks
echo -e "${BLUE}🔍 Executando verificações personalizadas...${RESET}"

# Check for suspicious patterns in staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -n "$STAGED_FILES" ]; then
    # Check for hardcoded IPs (excluding common safe ones)
    if echo "$STAGED_FILES" | xargs grep -l -E '\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b' 2>/dev/null | grep -v "127.0.0.1\|0.0.0.0\|localhost"; then
        echo -e "${YELLOW}⚠️ Endereços IP encontrados nos arquivos. Verifique se não são sensíveis.${RESET}"
    fi
    
    # Check for potential database connections
    if echo "$STAGED_FILES" | xargs grep -l -i -E "(mongodb|mysql|postgres|redis)://[^'\"\s]+" 2>/dev/null; then
        echo -e "${YELLOW}⚠️ Strings de conexão de banco encontradas. Verifique se são seguras.${RESET}"
    fi
    
    # Check for TODO/FIXME with security implications
    if echo "$STAGED_FILES" | xargs grep -l -i -E "TODO.*\b(password|token|secret|key|auth|credential)\b" 2>/dev/null; then
        echo -e "${YELLOW}⚠️ TODOs relacionados a segurança encontrados. Considere resolver antes do commit.${RESET}"
    fi
fi

echo -e "${GREEN}✅ Verificações de segurança concluídas com sucesso!${RESET}"
echo -e "${GREEN}🚀 Commit permitido.${RESET}"

exit 0
