#!/bin/bash
# GitUpdateProject - Instalador Automático do GitHub
# Este script baixa e instala automaticamente a última release do GitUpdateProject

set -e

# Configurações
REPO_OWNER="lgldsilva"
REPO_NAME="GitUpdateProject"
GITHUB_REPO="$REPO_OWNER/$REPO_NAME"

# Detectar sistema operacional e definir diretórios apropriados
detect_os_and_set_dirs() {
    case "$(uname -s)" in
        Linux*)     
            OS="Linux"
            INSTALL_DIR="/opt/GitUpdateProject"
            BIN_DIR="/usr/local/bin"
            ;;
        Darwin*)    
            OS="Mac"
            # macOS pode usar Homebrew paths
            if [ -d "/opt/homebrew" ]; then
                # Apple Silicon Macs
                INSTALL_DIR="/opt/homebrew/share/GitUpdateProject"
                BIN_DIR="/opt/homebrew/bin"
            elif [ -d "/usr/local/Homebrew" ]; then
                # Intel Macs with Homebrew
                INSTALL_DIR="/usr/local/share/GitUpdateProject"
                BIN_DIR="/usr/local/bin"
            else
                # Fallback tradicional
                INSTALL_DIR="/opt/GitUpdateProject"
                BIN_DIR="/usr/local/bin"
            fi
            ;;
        CYGWIN*|MINGW*|MSYS*)
            OS="Windows"
            # No Git Bash/Windows, usar diretórios do usuário
            USER_HOME="$(cygpath -u "$USERPROFILE" 2>/dev/null || echo "$HOME")"
            INSTALL_DIR="$USER_HOME/.local/GitUpdateProject"
            BIN_DIR="$USER_HOME/.local/bin"
            # Criar diretório bin se não existir
            mkdir -p "$BIN_DIR"
            ;;
        *)          
            OS="Unknown"
            warn "Sistema operacional não reconhecido: $(uname -s)"
            warn "Assumindo comportamento similar ao Linux"
            # Tentar instalação no diretório do usuário como fallback mais seguro
            INSTALL_DIR="$HOME/.local/share/GitUpdateProject"
            BIN_DIR="$HOME/.local/bin"
            mkdir -p "$BIN_DIR"
            ;;
    esac
}

# Chamar detecção no início
detect_os_and_set_dirs
TEMP_DIR="/tmp/gitupdate-install-$$"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Funções de logging
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

info() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Função para verificar dependências
check_dependencies() {
    log "Verificando dependências..."
    
    local missing_deps=()
    local required_cmds=("curl")
    
    # Verificar curl (essencial)
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    # Verificar comando de extração baseado no OS
    local has_extract=false
    if command -v tar &> /dev/null; then
        has_extract=true
    fi
    
    if command -v unzip &> /dev/null; then
        has_extract=true
    fi
    
    if [[ "$OS" == "Windows" ]] && command -v powershell &> /dev/null; then
        has_extract=true
    fi
    
    if [ "$has_extract" = false ]; then
        missing_deps+=("tar ou unzip")
    fi
    
    # wget é útil mas não essencial (só no Linux/Mac)
    if [[ "$OS" != "Windows" ]] && ! command -v wget &> /dev/null; then
        warn "wget não encontrado (não crítico, mas recomendado)"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Dependências críticas não encontradas: ${missing_deps[*]}"
        case "$OS" in
            "Windows")
                log "No Windows/Git Bash:"
                log "  - Reinstale Git for Windows (inclui curl)"
                log "  - Instale 7-Zip ou WinRAR para extração"
                log "  - Ou use Windows Subsystem for Linux (WSL)"
                ;;
            "Mac")
                log "No macOS:"
                log "  - brew install curl (se não tiver)"
                log "  - Comandos tar/unzip já deveriam estar disponíveis"
                ;;
            *)
                log "Execute:"
                log "  - sudo apt-get install curl tar unzip (Ubuntu/Debian)"
                log "  - sudo yum install curl tar unzip (RHEL/CentOS)"
                log "  - sudo pacman -S curl tar unzip (Arch Linux)"
                ;;
        esac
        exit 1
    fi
    
    success "Todas as dependências críticas estão instaladas"
}

# Função para obter a última release
get_latest_release() {
    log "Buscando informações da última release..."
    
    local api_url="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
    
    if command -v curl &> /dev/null; then
        RELEASE_INFO=$(curl -s "$api_url")
    elif command -v wget &> /dev/null; then
        RELEASE_INFO=$(wget -qO- "$api_url")
    else
        error "Nem curl nem wget estão disponíveis"
        exit 1
    fi
    
    if [ -z "$RELEASE_INFO" ]; then
        error "Falha ao obter informações da release"
        exit 1
    fi
    
    # Extrair tag name (versão)
    VERSION=$(echo "$RELEASE_INFO" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
    
    if [ -z "$VERSION" ]; then
        error "Não foi possível determinar a versão da release"
        exit 1
    fi
    
    success "Última release encontrada: $VERSION"
}

# Função para escolher e baixar arquivo
download_release() {
    log "Determinando melhor formato de arquivo..."
    
    # Preferência: tar.gz > zip > tar.xz (zip é mais comum no Windows)
    local download_url=""
    local filename=""
    local extract_cmd=""
    
    # Tentar tar.gz primeiro (funciona bem no Git Bash)
    filename="$REPO_NAME-$VERSION.tar.gz"
    download_url="https://github.com/$GITHUB_REPO/releases/download/$VERSION/$filename"
    
    if command -v curl &> /dev/null; then
        if curl -s -I "$download_url" | grep -q "200 OK"; then
            extract_cmd="tar -xzf"
        else
            # Tentar zip (melhor para Windows)
            filename="$REPO_NAME-$VERSION.zip"
            download_url="https://github.com/$GITHUB_REPO/releases/download/$VERSION/$filename"
            if curl -s -I "$download_url" | grep -q "200 OK"; then
                if command -v unzip &> /dev/null; then
                    extract_cmd="unzip -q"
                elif [[ "$OS" == "Windows" ]]; then
                    # No Windows, pode usar PowerShell como fallback
                    extract_cmd="powershell_extract"
                else
                    extract_cmd="unzip -q"
                fi
            else
                # Fallback para tar.xz
                filename="$REPO_NAME-$VERSION.tar.xz"
                download_url="https://github.com/$GITHUB_REPO/releases/download/$VERSION/$filename"
                extract_cmd="tar -xJf"
            fi
        fi
    else
        # Se não temos curl, assumir que tar.gz existe
        extract_cmd="tar -xzf"
    fi
    
    log "Baixando: $filename"
    log "URL: $download_url"
    
    # Criar diretório temporário (usar Windows temp se no Windows)
    if [[ "$OS" == "Windows" ]]; then
        # Tentar várias opções para diretório temporário no Windows
        if [ -n "$TEMP" ]; then
            TEMP_DIR="$(cygpath -u "$TEMP" 2>/dev/null || echo "$TEMP")/gitupdate-install-$$"
        elif [ -n "$TMP" ]; then
            TEMP_DIR="$(cygpath -u "$TMP" 2>/dev/null || echo "$TMP")/gitupdate-install-$$"
        elif [ -n "$USERPROFILE" ]; then
            TEMP_DIR="$(cygpath -u "$USERPROFILE" 2>/dev/null || echo "$USERPROFILE")/tmp/gitupdate-install-$$"
        else
            TEMP_DIR="/tmp/gitupdate-install-$$"
        fi
    fi
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Baixar arquivo
    if command -v curl &> /dev/null; then
        if ! curl -L -o "$filename" "$download_url"; then
            error "Falha ao baixar o arquivo"
            cleanup_and_exit 1
        fi
    elif command -v wget &> /dev/null; then
        if ! wget -O "$filename" "$download_url"; then
            error "Falha ao baixar o arquivo"
            cleanup_and_exit 1
        fi
    fi
    
    success "Download concluído: $(stat -c%s "$filename" 2>/dev/null | numfmt --to=iec 2>/dev/null || wc -c < "$filename" | tr -d ' ')B"
    
    # Baixar e verificar checksums se disponível
    local checksum_url="https://github.com/$GITHUB_REPO/releases/download/$VERSION/checksums.sha256"
    if command -v curl &> /dev/null; then
        if curl -s -I "$checksum_url" | grep -q "200 OK"; then
            log "Baixando checksums para verificação..."
            curl -L -o checksums.sha256 "$checksum_url"
            
            # Verificar checksum com comando apropriado para cada OS
            local checksum_verified=false
            if command -v sha256sum &> /dev/null; then
                # Linux
                if sha256sum -c checksums.sha256 --ignore-missing 2>/dev/null; then
                    checksum_verified=true
                fi
            elif command -v shasum &> /dev/null; then
                # macOS
                if shasum -a 256 -c checksums.sha256 --ignore-missing 2>/dev/null; then
                    checksum_verified=true
                fi
            elif [[ "$OS" == "Windows" ]] && command -v powershell &> /dev/null; then
                # Windows PowerShell
                local expected_hash
                expected_hash=$(grep "$filename" checksums.sha256 2>/dev/null | cut -d' ' -f1)
                if [ -n "$expected_hash" ]; then
                    local actual_hash
                    actual_hash=$(powershell -command "(Get-FileHash '$filename' -Algorithm SHA256).Hash.ToLower()" 2>/dev/null)
                    if [ "$expected_hash" = "$actual_hash" ]; then
                        checksum_verified=true
                    fi
                fi
            fi
            
            if [ "$checksum_verified" = true ]; then
                success "Checksum verificado com sucesso"
            else
                warn "Checksum não verificado (comando não disponível ou falhou), mas continuando..."
            fi
        fi
    fi
    
    # Extrair arquivo
    log "Extraindo arquivo..."
    if [[ "$extract_cmd" == "powershell_extract" ]]; then
        # Usar PowerShell no Windows se unzip não estiver disponível
        local ps_result=false
        if command -v powershell &> /dev/null; then
            if powershell -command "try { Expand-Archive -Path '$filename' -DestinationPath '.' -Force; exit 0 } catch { exit 1 }" 2>/dev/null; then
                ps_result=true
            fi
        fi
        
        if [ "$ps_result" = false ]; then
            # Fallback: tentar PowerShell Core (pwsh) ou WSL
            if command -v pwsh &> /dev/null; then
                if pwsh -command "Expand-Archive -Path '$filename' -DestinationPath '.' -Force" 2>/dev/null; then
                    ps_result=true
                fi
            fi
        fi
        
        if [ "$ps_result" = false ]; then
            error "Falha ao extrair o arquivo com PowerShell. Instale 7-Zip ou WinRAR"
            error "Ou execute este script no Git Bash onde unzip deve estar disponível"
            cleanup_and_exit 1
        fi
    else
        if ! $extract_cmd "$filename"; then
            error "Falha ao extrair o arquivo"
            cleanup_and_exit 1
        fi
    fi
    
    success "Arquivo extraído com sucesso"
}

# Função para instalar
install_gitupdate() {
    log "Instalando GitUpdateProject..."
    
    # Determinar se precisa de sudo baseado no OS e diretório
    if [[ "$OS" == "Windows" ]]; then
        # No Windows/Git Bash, instalar no diretório do usuário (sem sudo)
        SUDO=""
        log "Instalação no diretório do usuário (Windows/Git Bash)"
    else
        # Linux/Mac: verificar se precisa de sudo
        if [[ $EUID -eq 0 ]]; then
            warn "Executando como root - instalação será system-wide"
            SUDO=""
        else
            # Verificar se precisamos de sudo baseado nos diretórios de destino
            if [[ "$INSTALL_DIR" == "/opt/"* ]] || [[ "$INSTALL_DIR" == "/usr/"* ]] || [[ "$BIN_DIR" == "/usr/"* ]] || [[ "$BIN_DIR" == "/opt/"* ]]; then
                log "Usando sudo para instalação system-wide"
                SUDO="sudo"
            else
                log "Instalação no diretório do usuário"
                SUDO=""
            fi
        fi
    fi
    
    # Remover instalação anterior se existir
    if [ -d "$INSTALL_DIR" ]; then
        warn "Removendo instalação anterior..."
        $SUDO rm -rf "$INSTALL_DIR"
    fi
    
    # Criar diretório de instalação
    log "Criando diretório de instalação: $INSTALL_DIR"
    $SUDO mkdir -p "$INSTALL_DIR"
    
    # Copiar arquivos
    log "Copiando arquivos..."
    
    # Verificar se os arquivos foram extraídos corretamente
    if [ ! -d "$REPO_NAME" ]; then
        # Tentar encontrar diretório extraído (pode ter nome diferente)
        local extracted_dir
        extracted_dir=$(find . -maxdepth 1 -type d -name "*$REPO_NAME*" | head -1)
        if [ -n "$extracted_dir" ] && [ -d "$extracted_dir" ]; then
            log "Diretório encontrado: $extracted_dir"
            $SUDO cp -r "$extracted_dir"/* "$INSTALL_DIR/"
        else
            # Fallback: copiar todos os arquivos da pasta atual
            log "Copiando arquivos diretamente do diretório atual..."
            $SUDO cp -r ./* "$INSTALL_DIR/" 2>/dev/null || {
                error "Não foi possível encontrar arquivos extraídos"
                error "Conteúdo do diretório:"
                ls -la
                cleanup_and_exit 1
            }
        fi
    else
        $SUDO cp -r "$REPO_NAME"/* "$INSTALL_DIR/"
    fi
    
    # Tornar scripts executáveis
    log "Configurando permissões..."
    $SUDO find "$INSTALL_DIR" -name "*.sh" -type f -exec chmod +x {} \;
    
    # Criar link simbólico ou script wrapper
    log "Criando comando no PATH..."
    
    if [[ "$OS" == "Windows" ]]; then
        # No Windows, criar um script .bat e .sh para compatibilidade
        local bat_file="$BIN_DIR/updateGit.bat"
        local sh_file="$BIN_DIR/updateGit"
        
        # Script .bat para Command Prompt
        cat > "$bat_file" << 'EOF'
@echo off
bash "%~dp0updateGit" %*
EOF
        
        # Script shell para Git Bash
        cat > "$sh_file" << EOF
#!/bin/bash
exec "$INSTALL_DIR/updateGit_v2.sh" "\$@"
EOF
        chmod +x "$sh_file"
        
        success "Scripts criados: $bat_file e $sh_file"
        
        # Verificar se BIN_DIR está no PATH
        if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
            warn "Diretório $BIN_DIR não está no PATH"
            warn "Adicione ao seu PATH ou execute diretamente:"
            warn "  $sh_file"
        fi
    else
        # Linux/Mac: criar link simbólico tradicional
        $SUDO mkdir -p "$BIN_DIR"
        $SUDO ln -sf "$INSTALL_DIR/updateGit_v2.sh" "$BIN_DIR/updateGit"
        
        # Verificar instalação
        if [ -x "$BIN_DIR/updateGit" ]; then
            success "Link simbólico criado: $BIN_DIR/updateGit"
        else
            error "Falha ao criar link simbólico"
            cleanup_and_exit 1
        fi
    fi
}

# Função para limpeza
cleanup_and_exit() {
    local exit_code=${1:-0}
    if [ -d "$TEMP_DIR" ]; then
        log "Limpando arquivos temporários..."
        rm -rf "$TEMP_DIR"
    fi
    exit "$exit_code"
}

# Função para mostrar informações finais
show_final_info() {
    echo ""
    echo -e "${BOLD}${GREEN}🎉 Instalação concluída com sucesso!${NC}"
    echo "=================================="
    echo ""
    echo -e "${YELLOW}📁 Instalado em:${NC} $INSTALL_DIR"
    echo -e "${YELLOW}�️  Sistema:${NC} $OS"
    
    if [[ "$OS" == "Windows" ]]; then
        echo -e "${YELLOW}�🔗 Comandos disponíveis:${NC}"
        echo "  updateGit (Git Bash)"
        echo "  updateGit.bat (Command Prompt)"
        echo ""
        echo -e "${BLUE}💡 Dica para Windows:${NC}"
        echo "  Adicione $BIN_DIR ao seu PATH para usar em qualquer local"
    else
        echo -e "${YELLOW}🔗 Comando disponível:${NC} updateGit"
    fi
    
    echo ""
    echo -e "${BLUE}📋 Como usar:${NC}"
    echo "  updateGit [diretório]     - Atualizar repositórios"
    echo "  updateGit --help          - Mostrar ajuda"
    echo ""
    echo -e "${BLUE}📚 Exemplos:${NC}"
    if [[ "$OS" == "Windows" ]]; then
        echo "  updateGit C:/Users/user/projetos  - Atualizar repos Windows"
        echo "  updateGit ~/projetos              - Atualizar repos (Git Bash)"
    else
        echo "  updateGit ~/projetos      - Atualizar todos os repos em ~/projetos"
    fi
    echo "  updateGit .               - Atualizar repos no diretório atual"
    echo ""
    echo -e "${GREEN}✨ Versão instalada: $VERSION${NC}"
    
    if [[ "$OS" == "Windows" ]]; then
        echo ""
        echo -e "${YELLOW}🪟 Específico para Windows:${NC}"
        echo "  - Use Git Bash para melhor compatibilidade"
        echo "  - Ou use updateGit.bat no Command Prompt"
        echo "  - Paths podem usar / ou \\ como separador"
    fi
    echo ""
}

# Função principal
main() {
    echo -e "${BOLD}${BLUE}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║         GitUpdateProject - Instalador Automático    ║"
    echo "║                                                      ║"
    echo "║  Este script baixa e instala automaticamente a      ║"
    echo "║  última versão do GitUpdateProject do GitHub        ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # Verificar se o usuário quer continuar
    read -p "Deseja continuar com a instalação? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Instalação cancelada pelo usuário"
        exit 0
    fi
    
    check_dependencies
    get_latest_release
    download_release
    install_gitupdate
    show_final_info
    
    cleanup_and_exit 0
}

# Capturar sinais para limpeza
trap 'cleanup_and_exit 1' INT TERM

# Executar função principal
main "$@"
