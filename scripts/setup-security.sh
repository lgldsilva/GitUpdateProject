#!/bin/bash

# Setup script for GitUpdate Project security
# This script installs and configures all security tools and hooks

set -e

# Carregar módulo de utilitários de segurança
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/security_utils.sh"

echo -e "${BLUE}🔧 GitUpdate Project - Setup de Segurança${RESET}"
echo "=============================================="

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Este não é um repositório Git. Execute: git init${RESET}"
    exit 1
fi

# 1. Install security tools
echo -e "\n${BLUE}1. 🛠️ Instalando ferramentas de segurança...${RESET}"
ensure_security_tools

# 2. Setup git hooks
echo -e "\n${BLUE}2. 🪝 Configurando Git hooks...${RESET}"

if [ -f "scripts/pre-commit-security.sh" ]; then
    # Create hooks directory if it doesn't exist
    mkdir -p .git/hooks
    
    # Create or update pre-commit hook
    if [ -f ".git/hooks/pre-commit" ]; then
        echo -e "${YELLOW}⚠️ Hook pre-commit já existe. Criando backup...${RESET}"
        cp .git/hooks/pre-commit .git/hooks/pre-commit.backup
    fi
    
    # Create new pre-commit hook
    ln -sf ../../scripts/pre-commit-security.sh .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    
    echo -e "${GREEN}✅ Hook pre-commit configurado${RESET}"
else
    echo -e "${RED}❌ Script pre-commit-security.sh não encontrado${RESET}"
    exit 1
fi

# 3. Verify configuration files
echo -e "\n${BLUE}3. 📋 Verificando arquivos de configuração...${RESET}"

MISSING_FILES=0

# Check .gitleaks.toml
if [ -f ".gitleaks.toml" ]; then
    echo -e "${GREEN}✅ .gitleaks.toml presente${RESET}"
else
    echo -e "${RED}❌ .gitleaks.toml ausente${RESET}"
    MISSING_FILES=$((MISSING_FILES + 1))
fi

# Check .gitignore
if [ -f ".gitignore" ]; then
    echo -e "${GREEN}✅ .gitignore presente${RESET}"
else
    echo -e "${RED}❌ .gitignore ausente${RESET}"
    MISSING_FILES=$((MISSING_FILES + 1))
fi

# Check security policy
if [ -f "SECURITY.md" ]; then
    echo -e "${GREEN}✅ SECURITY.md presente${RESET}"
else
    echo -e "${RED}❌ SECURITY.md ausente${RESET}"
    MISSING_FILES=$((MISSING_FILES + 1))
fi

# Check GitHub workflow
if [ -f ".github/workflows/security-scan.yml" ]; then
    echo -e "${GREEN}✅ Pipeline de segurança configurada${RESET}"
else
    echo -e "${RED}❌ Pipeline de segurança ausente${RESET}"
    MISSING_FILES=$((MISSING_FILES + 1))
fi

# 4. Test installation
echo -e "\n${BLUE}4. 🧪 Testando instalação...${RESET}"

echo -e "${YELLOW}Testando Gitleaks...${RESET}"
if command_exists gitleaks && gitleaks version >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Gitleaks funcionando${RESET}"
else
    echo -e "${RED}❌ Problema com Gitleaks${RESET}"
fi

echo -e "${YELLOW}Testando ShellCheck...${RESET}"
if command_exists shellcheck && shellcheck --version >/dev/null 2>&1; then
    echo -e "${GREEN}✅ ShellCheck funcionando${RESET}"
else
    echo -e "${RED}❌ Problema com ShellCheck${RESET}"
fi

echo -e "${YELLOW}Testando Semgrep...${RESET}"
if command_exists semgrep && semgrep --version >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Semgrep funcionando${RESET}"
else
    echo -e "${YELLOW}⚠️ Semgrep não disponível (opcional)${RESET}"
fi

# 5. Run initial security scan
echo -e "\n${BLUE}5. 🔍 Executando scan inicial de segurança...${RESET}"

if [ -f "scripts/security-audit.sh" ]; then
    echo -e "${YELLOW}Executando auditoria de segurança...${RESET}"
    ./scripts/security-audit.sh || true
else
    echo -e "${YELLOW}⚠️ Script de auditoria não encontrado${RESET}"
fi

# 6. Final summary
echo -e "\n${BLUE}📊 RESUMO DA INSTALAÇÃO${RESET}"
echo "=============================="

if [ $MISSING_FILES -eq 0 ]; then
    echo -e "${GREEN}✅ Todos os arquivos de configuração estão presentes${RESET}"
else
    echo -e "${RED}❌ $MISSING_FILES arquivos de configuração ausentes${RESET}"
fi

echo -e "\n${BLUE}🎯 PRÓXIMOS PASSOS:${RESET}"
echo "1. Revise e customize os arquivos de configuração conforme necessário"
echo "2. Execute './scripts/security-audit.sh' regularmente"
echo "3. O hook pre-commit irá executar automaticamente em cada commit"
echo "4. Configure as variáveis de ambiente no GitHub para a pipeline CI/CD"

# Instructions for GitHub setup
echo -e "\n${BLUE}🔧 CONFIGURAÇÃO DO GITHUB:${RESET}"
echo "1. Faça push dos arquivos para o GitHub"
echo "2. Vá em Settings > Security > Code security and analysis"
echo "3. Ative 'Dependency graph' e 'Dependabot alerts'"
echo "4. A pipeline de segurança executará automaticamente em push/PR"

if [ $MISSING_FILES -eq 0 ]; then
    echo -e "\n${GREEN}🎉 Setup de segurança concluído com sucesso!${RESET}"
    exit 0
else
    echo -e "\n${YELLOW}⚠️ Setup concluído com avisos. Verifique os arquivos ausentes.${RESET}"
    exit 1
fi
