#!/bin/bash

# Módulo de utilitários de segurança
# Centraliza funções compartilhadas pelos scripts de auditoria, pre-commit e setup.

# Include guard
[[ -n "${_SECURITY_UTILS_SH_LOADED:-}" ]] && return 0
_SECURITY_UTILS_SH_LOADED=1

# shellcheck source=lib/colors.sh
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Contadores globais de severidade
export SEC_CRITICAL=0
export SEC_HIGH=0
export SEC_MEDIUM=0
export SEC_LOW=0

reset_security_counters() {
    SEC_CRITICAL=0
    SEC_HIGH=0
    SEC_MEDIUM=0
    SEC_LOW=0
}

add_to_summary() {
    local severity="${1:?ERRO: severidade não informada}"
    local count="${2:-1}"
    case "$severity" in
        CRITICAL) SEC_CRITICAL=$((SEC_CRITICAL + count)) ;;
        HIGH)     SEC_HIGH=$((SEC_HIGH + count)) ;;
        MEDIUM)   SEC_MEDIUM=$((SEC_MEDIUM + count)) ;;
        LOW)      SEC_LOW=$((SEC_LOW + count)) ;;
        *)
            echo -e "${YELLOW}⚠️  Severidade desconhecida: $severity${RESET}" >&2
            return 1
            ;;
    esac
}

command_exists() {
    command -v "${1:?ERRO: comando não informado}" >/dev/null 2>&1
}

# Instala gitleaks usando o gerenciador de pacotes disponível.
install_gitleaks() {
    if command_exists gitleaks; then
        return 0
    fi

    echo -e "${BLUE}📦 Instalando gitleaks...${RESET}"

    if command_exists brew; then
        brew install gitleaks && return 0
    fi
    if command_exists pacman; then
        sudo pacman -S --noconfirm gitleaks && return 0
    fi
    if command_exists apt-get; then
        # Gitleaks não está nos repositórios padrão — fallback para download direto
        :
    fi
    if command_exists dnf; then
        sudo dnf install -y gitleaks && return 0
    fi

    # Fallback: download direto da release oficial
    local version="8.18.0"
    local os arch tmp
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64) arch="x64" ;;
        aarch64|arm64) arch="arm64" ;;
    esac

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' RETURN

    local url="https://github.com/gitleaks/gitleaks/releases/download/v${version}/gitleaks_${version}_${os}_${arch}.tar.gz"
    if command_exists curl; then
        curl -fsSL "$url" -o "$tmp/gitleaks.tgz" || return 1
    elif command_exists wget; then
        wget -qO "$tmp/gitleaks.tgz" "$url" || return 1
    else
        echo -e "${RED}❌ curl ou wget necessários para baixar gitleaks${RESET}" >&2
        return 1
    fi

    tar -xzf "$tmp/gitleaks.tgz" -C "$tmp" gitleaks || return 1
    local dest="/usr/local/bin"
    [[ -w "$dest" ]] || dest="$HOME/.local/bin"
    mkdir -p "$dest"
    install -m 0755 "$tmp/gitleaks" "$dest/gitleaks"
    command_exists gitleaks
}

# Garante presença das ferramentas mínimas (gitleaks, shellcheck). Semgrep é opcional.
ensure_security_tools() {
    local missing=0

    if ! command_exists gitleaks; then
        echo -e "${YELLOW}⚠️  gitleaks ausente${RESET}"
        install_gitleaks || missing=1
    fi

    if ! command_exists shellcheck; then
        echo -e "${YELLOW}⚠️  shellcheck ausente — instale via gerenciador de pacotes${RESET}"
        missing=1
    fi

    if ! command_exists semgrep; then
        echo -e "${YELLOW}ℹ️  semgrep ausente (opcional): pipx install semgrep${RESET}"
    fi

    return "$missing"
}

run_gitleaks_scan() {
    local source_dir="${1:-.}"
    local report_path="${2:-gitleaks-report.json}"

    echo -e "\n${BLUE}1. 🔍 Detectando secrets com gitleaks...${RESET}"
    if ! command_exists gitleaks; then
        echo -e "${YELLOW}⚠️  gitleaks não instalado, pulando${RESET}"
        add_to_summary "MEDIUM" 1
        return 1
    fi

    # Gitleaks retorna 1 quando encontra leaks, 0 quando limpo, >1 em erro real
    local status=0
    gitleaks detect \
        --source "$source_dir" \
        --report-format json \
        --report-path "$report_path" \
        --no-banner 2>/dev/null || status=$?

    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}✅ Nenhum secret detectado${RESET}"
    elif [[ $status -eq 1 ]]; then
        local leaks=0
        if command_exists jq && [[ -f "$report_path" ]]; then
            leaks=$(jq 'length' "$report_path" 2>/dev/null || echo 0)
        fi
        echo -e "${RED}❌ $leaks secret(s) detectado(s)${RESET}"
        add_to_summary "CRITICAL" "$leaks"
        return 1
    else
        echo -e "${RED}❌ Erro na execução do gitleaks (status=$status)${RESET}"
        add_to_summary "HIGH" 1
        return 1
    fi
}

run_shellcheck_scan() {
    local report_path="${1:-shellcheck-report.json}"

    echo -e "\n${BLUE}2. 🐚 Analisando scripts shell com shellcheck...${RESET}"
    if ! command_exists shellcheck; then
        echo -e "${YELLOW}⚠️  shellcheck não instalado, pulando${RESET}"
        add_to_summary "LOW" 1
        return 1
    fi

    # Coletar scripts shell, excluindo .git
    mapfile -t shell_files < <(find . -type f -name "*.sh" ! -path "./.git/*" 2>/dev/null)
    if [[ ${#shell_files[@]} -eq 0 ]]; then
        echo -e "${GREEN}✅ Nenhum script shell encontrado${RESET}"
        : > "$report_path"
        return 0
    fi

    local status=0
    shellcheck --format=json "${shell_files[@]}" > "$report_path" 2>/dev/null || status=$?

    local issues=0
    if command_exists jq && [[ -s "$report_path" ]]; then
        issues=$(jq 'length' "$report_path" 2>/dev/null || echo 0)
    fi

    if [[ $issues -eq 0 ]]; then
        echo -e "${GREEN}✅ Nenhum issue de shellcheck${RESET}"
    else
        echo -e "${YELLOW}⚠️  $issues issue(s) encontrado(s) pelo shellcheck${RESET}"
        add_to_summary "LOW" "$issues"
    fi
    return "$status"
}

run_custom_security_checks() {
    echo -e "\n${BLUE}5. 🧪 Executando verificações customizadas...${RESET}"
    local found=0

    # rm -rf /, sudo rm, chmod 777
    if grep -r -n -E "(rm[[:space:]]+-rf[[:space:]]+/|sudo[[:space:]]+rm|chmod[[:space:]]+777)" \
            --include="*.sh" --exclude-dir=.git --exclude-dir=security-reports . 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Comandos potencialmente perigosos encontrados${RESET}"
        add_to_summary "MEDIUM" 1
        found=1
    fi

    # TODOs com palavras sensíveis
    if grep -r -n -i -E "TODO.*\b(password|token|secret|key|auth|credential)\b" \
            --exclude-dir=.git --exclude-dir=security-reports . 2>/dev/null; then
        echo -e "${YELLOW}⚠️  TODOs com termos sensíveis encontrados${RESET}"
        add_to_summary "LOW" 1
        found=1
    fi

    [[ $found -eq 0 ]] && echo -e "${GREEN}✅ Nenhum padrão suspeito encontrado${RESET}"
    return 0
}

_render_security_summary() {
    local project="$1"
    local scan_date="$2"
    cat <<EOF
# Resumo de Segurança — $project

**Data:** $scan_date

| Severidade | Quantidade |
|------------|------------|
| 🔴 Crítica | $SEC_CRITICAL |
| 🟠 Alta    | $SEC_HIGH |
| 🟡 Média   | $SEC_MEDIUM |
| 🔵 Baixa   | $SEC_LOW |

EOF
}

generate_security_summary() {
    local project="${1:-GitUpdate Project}"
    local scan_date="${2:-$(date '+%Y-%m-%d %H:%M:%S')}"

    echo ""
    echo -e "${BLUE}📊 RESUMO DE SEGURANÇA${RESET}"
    echo "=================================="
    echo -e "Projeto: ${GREEN}$project${RESET}"
    echo -e "Data:    ${GREEN}$scan_date${RESET}"
    echo ""
    echo -e "  🔴 Críticas: ${RED}$SEC_CRITICAL${RESET}"
    echo -e "  🟠 Altas:    ${RED}$SEC_HIGH${RESET}"
    echo -e "  🟡 Médias:   ${YELLOW}$SEC_MEDIUM${RESET}"
    echo -e "  🔵 Baixas:   ${CYAN}$SEC_LOW${RESET}"
    echo ""
}

save_security_summary() {
    local report_dir="${1:?ERRO: diretório de relatório não informado}"
    local project="${2:-GitUpdate Project}"
    local scan_date="${3:-$(date '+%Y-%m-%d %H:%M:%S')}"

    mkdir -p "$report_dir"
    _render_security_summary "$project" "$scan_date" > "$report_dir/security-summary.md"
}

get_security_exit_code() {
    if [[ $SEC_CRITICAL -gt 0 ]]; then
        return 2
    elif [[ $SEC_HIGH -gt 0 ]]; then
        return 1
    fi
    return 0
}
