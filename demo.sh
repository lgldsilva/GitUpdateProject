#!/bin/bash

# Demonstração completa do GitUpdate Project com Pipeline de Segurança
# Este script mostra todas as funcionalidades implementadas

set -e

# Carregar cores do sistema
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/colors.sh"

echo -e "${BLUE}🚀 GitUpdate Project - Demonstração Completa${RESET}"
echo "=================================================="

# Função para pausar e aguardar confirmação
wait_for_user() {
    echo ""
    read -p "Pressione [Enter] para continuar..."
    echo ""
}

# 1. Mostrar estrutura do projeto
echo -e "${BLUE}1. 📁 Estrutura do Projeto${RESET}"
echo "Mostrando a estrutura modular com sistema de segurança:"
tree -I '.git|security-reports' . || find . -type f -name "*.sh" -o -name "*.md" -o -name "*.yml" -o -name "*.toml" | head -20
wait_for_user

# 2. Demonstrar funcionalidade original
echo -e "${BLUE}2. 🔄 Funcionalidade Original (Atualização Git)${RESET}"
echo "O sistema mantém toda funcionalidade original para atualizar repositórios Git:"
echo ""
echo -e "${GREEN}Comandos disponíveis:${RESET}"
echo "  ./updateGit_v2.sh --help                    # Ver ajuda"
echo "  ./updateGit_v2.sh ~/Projetos -d -L          # Atualizar com debug e symlinks"
echo "  ./updateGit_v2.sh ~/Projetos -a             # Permitir autenticação"
echo "  ./updateGit_v2.sh ~/Projetos -f             # Forçar pull"
echo ""
echo "Executando ajuda:"
./updateGit_v2.sh --help
wait_for_user

# 3. Demonstrar sistema de segurança
echo -e "${BLUE}3. 🔒 Sistema de Segurança${RESET}"
echo "Executando auditoria completa de segurança..."
./scripts/security-audit.sh
wait_for_user

# 4. Mostrar relatórios gerados
echo -e "${BLUE}4. 📊 Relatórios de Segurança${RESET}"
echo "Relatórios gerados na pasta security-reports/:"
ls -la security-reports/
echo ""
echo "Conteúdo do resumo de segurança:"
cat security-reports/security-summary.md
wait_for_user

# 5. Demonstrar configurações de segurança
echo -e "${BLUE}5. ⚙️ Configurações de Segurança${RESET}"
echo ""
echo -e "${GREEN}Arquivo .gitleaks.toml (detecção de secrets):${RESET}"
head -15 .gitleaks.toml
echo "..."
echo ""
echo -e "${GREEN}Arquivo .gitignore (proteção automática):${RESET}"
head -10 .gitignore
echo "..."
wait_for_user

# 6. Demonstrar pipeline GitHub Actions
echo -e "${BLUE}6. 🚀 Pipeline GitHub Actions${RESET}"
echo ""
echo -e "${GREEN}Pipeline de segurança configurada em:${RESET}"
echo ".github/workflows/security-scan.yml"
echo ""
echo "Esta pipeline executa automaticamente:"
echo "  ✅ Gitleaks - Detecção de secrets"
echo "  ✅ Semgrep - Análise de vulnerabilidades"
echo "  ✅ ShellCheck - Análise de scripts shell"
echo "  ✅ Verificações customizadas"
echo "  ✅ Geração de relatórios"
wait_for_user

# 7. Demonstrar modularidade
echo -e "${BLUE}7. 🧩 Sistema Modular${RESET}"
echo ""
echo -e "${GREEN}Módulos disponíveis na pasta lib/:${RESET}"
ls -la lib/
echo ""
echo "Cada módulo tem uma responsabilidade específica:"
echo "  🎨 colors.sh - Cores e formatação"
echo "  ⚙️ config.sh - Configurações globais"
echo "  📝 logger.sh - Sistema de logging"
echo "  📊 progress.sh - Barra de progresso"
echo "  🖥️ ui.sh - Interface do usuário"
echo "  🔧 git_utils.sh - Utilitários Git"
echo "  🔄 git_operations.sh - Operações Git"
echo "  🏗️ repo_updater.sh - Atualizador principal"
echo "  🔍 repo_finder.sh - Descoberta de repositórios"
wait_for_user

# 8. Demonstrar scripts de segurança
echo -e "${BLUE}8. 🛡️ Scripts de Segurança${RESET}"
echo ""
echo -e "${GREEN}Scripts disponíveis na pasta scripts/:${RESET}"
ls -la scripts/
echo ""
echo "Funcionalidades dos scripts:"
echo "  🔧 setup-security.sh - Setup automático completo"
echo "  🔍 security-audit.sh - Auditoria completa de segurança"
echo "  🚫 pre-commit-security.sh - Hook pré-commit (bloqueia commits inseguros)"
wait_for_user

# 9. Demonstrar exemplo de uso dos módulos
echo -e "${BLUE}9. 📚 Exemplo de Reutilização de Módulos${RESET}"
echo ""
echo "Executando example_usage.sh para mostrar reutilização:"
./example_usage.sh
wait_for_user

# 10. Demonstrar instalação
echo -e "${BLUE}10. 📦 Sistema de Instalação${RESET}"
echo ""
echo -e "${GREEN}Para instalação global do sistema:${RESET}"
echo "  ./install.sh"
echo ""
echo "Após instalação, o comando 'git-update' fica disponível globalmente:"
echo "  git-update ~/Projetos -d -L"
echo "  git-update --help"
wait_for_user

# 11. Resumo das vantagens
echo -e "${BLUE}11. 🎯 Resumo das Vantagens${RESET}"
echo ""
echo -e "${GREEN}✅ Funcionalidade Original Mantida:${RESET}"
echo "  - Atualização automática de repositórios Git"
echo "  - Suporte a múltiplas branches (master, main, develop)"
echo "  - Barra de progresso e logging detalhado"
echo "  - Configurações flexíveis via parâmetros"
echo ""
echo -e "${GREEN}🔒 Sistema de Segurança Adicionado:${RESET}"
echo "  - Detecção automática de secrets e tokens"
echo "  - Pipeline CI/CD com múltiplas ferramentas"
echo "  - Hook pré-commit impede commits inseguros"
echo "  - Auditoria completa com score de segurança"
echo "  - Relatórios detalhados e processo auditável"
echo ""
echo -e "${GREEN}🏗️ Arquitetura Modular:${RESET}"
echo "  - Código organizado e reutilizável"
echo "  - Fácil manutenção e extensão"
echo "  - Testes isolados por módulo"
echo "  - Documentação completa"
echo ""
echo -e "${GREEN}🚀 Pronto para Produção:${RESET}"
echo "  - Setup automatizado one-click"
echo "  - Processo profissional e confiável" 
echo "  - Conformidade com melhores práticas"
echo "  - Proteção contra vazamentos de dados"
wait_for_user

# 12. Próximos passos
echo -e "${BLUE}12. 🎯 Próximos Passos Recomendados${RESET}"
echo ""
echo -e "${YELLOW}Para usar este sistema:${RESET}"
echo ""
echo "1. 🔧 Setup inicial:"
echo "   ./scripts/setup-security.sh"
echo ""
echo "2. 🧪 Teste o sistema:"
echo "   ./scripts/security-audit.sh"
echo "   ./updateGit_v2.sh --help"
echo ""
echo "3. 📦 Instale globalmente (opcional):"
echo "   ./install.sh"
echo ""
echo "4. 🚀 Configure no GitHub:"
echo "   - Faça push dos arquivos"
echo "   - A pipeline de segurança executará automaticamente"
echo "   - Ative Dependabot em Settings > Security"
echo ""
echo "5. 📝 Customize conforme necessário:"
echo "   - Edite .gitleaks.toml para regras específicas"
echo "   - Ajuste .gitignore para seu projeto"
echo "   - Modifique scripts/security-audit.sh para verificações customizadas"

echo ""
echo -e "${GREEN}🎉 Demonstração concluída!${RESET}"
echo -e "${GREEN}Seu GitUpdate Project agora possui um sistema completo de segurança! 🔒${RESET}"
