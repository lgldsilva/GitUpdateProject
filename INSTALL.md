# GitUpdateProject - Instalação Automática

Este script permite instalar automaticamente a última versão do GitUpdateProject diretamente do GitHub em **Linux**, **macOS** e **Windows** (Git Bash).

## 🚀 Instalação Rápida

### Linux/macOS (uma linha):
```bash
curl -fsSL https://raw.githubusercontent.com/lgldsilva/GitUpdateProject/master/install-from-github.sh | bash
```

### Windows (Git Bash):
```bash
curl -fsSL https://raw.githubusercontent.com/lgldsilva/GitUpdateProject/master/install-from-github.sh | bash
```

### Alternativa com wget:
```bash
wget -qO- https://raw.githubusercontent.com/lgldsilva/GitUpdateProject/master/install-from-github.sh | bash
```

### Instalação Manual:
```bash
# Baixar o script
curl -o install.sh https://raw.githubusercontent.com/lgldsilva/GitUpdateProject/master/install-from-github.sh

# Tornar executável
chmod +x install.sh

# Executar
./install.sh
```

## 🪟 Específico para Windows

### Pré-requisitos:
- **Git for Windows** instalado (inclui Git Bash)
- Execute sempre no **Git Bash** (não no Command Prompt ou PowerShell)

### Onde instala:
- **Linux/macOS**: `/opt/GitUpdateProject` (system-wide)
- **Windows**: `%USERPROFILE%\.local\GitUpdateProject` (usuário)

### Comandos disponíveis após instalação:
- **Git Bash**: `updateGit`
- **Command Prompt**: `updateGit.bat`

## 📦 O que o script faz:

1. **Detecta o sistema operacional** (Linux/macOS/Windows)
2. **Verifica dependências** apropriadas para cada OS
3. **Busca a última release** no GitHub
4. **Baixa automaticamente** o formato mais adequado
5. **Verifica checksums** se disponível
6. **Instala no local correto** para cada sistema
7. **Cria comandos** apropriados no PATH

## 🔧 Após a instalação:

### Linux/macOS:
```bash
updateGit ~/projetos
updateGit --help
```

### Windows (Git Bash):
```bash
updateGit ~/projetos
updateGit C:/Users/user/projetos
updateGit --help
```

### Windows (Command Prompt):
```cmd
updateGit.bat C:\Users\user\projetos
updateGit.bat --help
```

## �️ Requisitos

### Linux/macOS:
- **SO**: Linux, macOS
- **Dependências**: curl ou wget, tar, unzip
- **Permissões**: sudo para instalação system-wide

### Windows:
- **SO**: Windows 10/11
- **Software**: Git for Windows (com Git Bash)
- **Dependências**: curl (incluído no Git), tar (incluído no Git)
- **Permissões**: Não requer administrador (instala no usuário)

## 🔐 Segurança

- O script verifica checksums SHA256 quando disponíveis
- Usa HTTPS para todas as conexões
- Não requer privilégios root no Windows
- Código fonte completamente aberto e auditável

## 📋 Personalização

Para instalar em local customizado, edite as variáveis no script antes de executar.

## 🔄 Atualizações

Execute o mesmo comando para atualizar para a versão mais recente:

```bash
curl -fsSL https://raw.githubusercontent.com/lgldsilva/GitUpdateProject/master/install-from-github.sh | bash
```

## 🐛 Solução de Problemas

### Windows - Git Bash não encontrado:
```bash
# Instalar Git for Windows:
# https://git-scm.com/download/win
```

### Windows - Erro de PATH:
```bash
# Adicionar ao PATH no Git Bash:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Windows - PowerShell como alternativa:
Se o unzip não estiver disponível, o script usa PowerShell automaticamente.

### Linux - Erro de permissões:
```bash
sudo curl -fsSL https://raw.githubusercontent.com/lgldsilva/GitUpdateProject/master/install-from-github.sh | bash
```

### macOS - Dependências não encontradas:
```bash
# Instalar Homebrew primeiro:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install curl wget
```

### Verificar instalação:
```bash
# Linux/macOS
which updateGit
updateGit --version

# Windows (Git Bash)
which updateGit
updateGit --version

# Windows (Command Prompt)
where updateGit.bat
updateGit.bat --version
```
