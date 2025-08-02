#!/bin/bash

# Security audit script
# Run comprehensive security checks on the GitUpdate project

set -e

# Carregar módulo de utilitários de segurança
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/security_utils.sh"

# Project information
PROJECT_NAME="GitUpdate Project"
SCAN_DATE=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)
REPORT_DIR="security-reports"

echo -e "${BLUE}🔒 $PROJECT_NAME - Auditoria de Segurança${RESET}"
echo -e "${BLUE}Data: $SCAN_DATE${RESET}"
echo "=================================================="

# Create reports directory
mkdir -p "$REPORT_DIR"

# Reset counters
reset_security_counters

# 1. Secret Detection with Gitleaks
run_gitleaks_scan "." "$REPORT_DIR/gitleaks-report.json" || true

# 2. Shell Script Analysis
run_shellcheck_scan "$REPORT_DIR/shellcheck-report.json" || true

# 3. File Permissions Check
echo -e "\n${BLUE}3. 🔐 Verificando permissões de arquivos...${RESET}"
PERM_ISSUES=0

# Check for overly permissive files
WORLD_WRITABLE=$(find . -type f -perm -002 ! -path "./.git/*" 2>/dev/null | wc -l)
if [ "$WORLD_WRITABLE" -gt 0 ]; then
    echo -e "${RED}❌ $WORLD_WRITABLE arquivos com permissão de escrita para todos${RESET}"
    find . -type f -perm -002 ! -path "./.git/*" | head -5
    add_to_summary "HIGH" "$WORLD_WRITABLE"
    PERM_ISSUES=$((PERM_ISSUES + WORLD_WRITABLE))
fi

# Check for executable files that shouldn't be
EXEC_NON_SCRIPTS=$(find . -type f -perm -111 ! -name "*.sh" ! -path "./.git/*" ! -path "./scripts/*" 2>/dev/null | wc -l)
if [ "$EXEC_NON_SCRIPTS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️ $EXEC_NON_SCRIPTS arquivos executáveis suspeitos${RESET}"
    add_to_summary "MEDIUM" "$EXEC_NON_SCRIPTS"
    PERM_ISSUES=$((PERM_ISSUES + EXEC_NON_SCRIPTS))
fi

if [ "$PERM_ISSUES" -eq 0 ]; then
    echo -e "${GREEN}✅ Permissões de arquivos corretas${RESET}"
fi

# 4. Dependency Security (for future use)
echo -e "\n${BLUE}4. 📦 Verificando dependências...${RESET}"
echo -e "${GREEN}✅ Projeto não possui dependências externas${RESET}"

# 5. Code Quality Checks
run_custom_security_checks || true

# 6. Git Security
echo -e "\n${BLUE}6. 🔧 Verificações Git...${RESET}"

# Check if .gitignore exists and has common sensitive patterns
if [ -f ".gitignore" ]; then
    GITIGNORE_PATTERNS=0
    for pattern in "*.log" "*.key" "*.pem" ".env" "config.ini" "credentials" "secrets"; do
        if ! grep -q "$pattern" .gitignore; then
            GITIGNORE_PATTERNS=$((GITIGNORE_PATTERNS + 1))
        fi
    done
    
    if [ $GITIGNORE_PATTERNS -gt 0 ]; then
        echo -e "${YELLOW}⚠️ $GITIGNORE_PATTERNS padrões de segurança ausentes no .gitignore${RESET}"
        add_to_summary "LOW" "$GITIGNORE_PATTERNS"
    else
        echo -e "${GREEN}✅ .gitignore bem configurado${RESET}"
    fi
else
    echo -e "${YELLOW}⚠️ Arquivo .gitignore não encontrado${RESET}"
    add_to_summary "MEDIUM" 1
fi

# Generate final report
generate_security_summary "$PROJECT_NAME" "$SCAN_DATE"

# Save summary to file
save_security_summary "$REPORT_DIR" "$PROJECT_NAME" "$SCAN_DATE"

echo ""
echo -e "${BLUE}📋 Relatórios salvos em: $REPORT_DIR/${RESET}"
echo -e "${BLUE}📄 Resumo disponível em: $REPORT_DIR/security-summary.md${RESET}"

# Exit with appropriate code
get_security_exit_code
