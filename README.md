# GitUpdateProject 🔧

<p align="center">
  <img src="https://img.shields.io/badge/security-A%2B-brightgreen" alt="Security Score">
  <img src="https://img.shields.io/badge/platform-Linux%20|%20macOS-blue" alt="Platform Support">
  <img src="https://img.shields.io/badge/shell-bash-green" alt="Shell">
  <img src="https://img.shields.io/github/actions/workflow/status/lgldsilva/GitUpdateProject/security-scan.yml?branch=master" alt="CI/CD Status">
</p>

**Automated Git repository update system with comprehensive security pipeline**

GitUpdateProject é uma solução completa para automação de atualizações de repositórios Git com pipeline de segurança integrado. O sistema oferece detecção automática de repositórios, atualizações seguras e verificações de segurança em tempo real.

## ✨ Características Principais

- 🚀 **Detecção recursiva**: encontra todos os repositórios Git (inclusive worktrees) em um diretório
- ⚡ **Execução paralela**: até N workers simultâneos (`--jobs N`)
- 🔀 **Suporte a submódulos, LFS, push e gc**: operações opcionais via flags
- 🎯 **Preserva trabalho local**: stash automático antes do pull, pop ao final (ou `--force` para descartar)
- 🧪 **Dry-run**: `--dry-run` mostra o que seria feito sem executar
- 📁 **Exclusões**: `--exclude PATTERN` ou arquivo `.gitupdateignore`
- 🪝 **Hooks por repo**: `.gitupdate-hook` executado após update bem-sucedido
- 📊 **Saída JSON**: `--json` para integração com pipelines
- 🔔 **Notificações**: desktop (`--notify`) e webhook (`--webhook URL`)
- 🌐 **Cross-platform**: Linux, macOS (com/sem coreutils) e Windows (Git Bash)
- 🔒 **Pipeline de segurança**: Gitleaks, Semgrep e ShellCheck integrados
- 🏗️ **Arquitetura modular**: 14 módulos shell reutilizáveis
- 🧪 **Suite de testes `bats`** para regressões

## 📦 Instalação Rápida

```bash
# Clone o repositório
git clone https://github.com/lgldsilva/GitUpdateProject.git
cd GitUpdateProject

# Configure o pipeline de segurança (execução única)
./scripts/setup-security.sh

# Execute o sistema de atualização
./updateGit_v2.sh /caminho/para/seus/repositorios
```

## 🛠️ Configuração do Pipeline de Segurança

O sistema inclui um pipeline de segurança completo que é configurado automaticamente:

### Ferramentas de Segurança Incluídas

- **Gitleaks v8.18.0**: Detecção de secrets e credenciais
- **Semgrep**: Análise estática de código para vulnerabilidades  
- **ShellCheck**: Validação de scripts shell

### Instalação Automática por Plataforma

```bash
# Arch Linux
sudo pacman -S shellcheck
sudo pacman -S python-pipx && pipx install semgrep

# Ubuntu/Debian  
sudo apt install shellcheck python3-pipx
pipx install semgrep

# Fedora
sudo dnf install ShellCheck pipx
pipx install semgrep

# macOS
brew install shellcheck gitleaks
pipx install semgrep
```

## 🚀 Uso

### Uso Básico

```bash
# Atualizar todos os repositórios em um diretório
./updateGit_v2.sh ~/Projetos

# Modo debug
./updateGit_v2.sh -d ~/Projetos

# Dry-run (ver o que seria feito)
./updateGit_v2.sh --dry-run ~/Projetos

# Paralelismo: 8 workers + submódulos + LFS
./updateGit_v2.sh -j 8 --submodules --lfs ~/Projetos

# Push de commits locais não enviados após o pull
./updateGit_v2.sh --push ~/Projetos

# Forçar pull descartando alterações locais
./updateGit_v2.sh -f ~/Projetos

# Saída JSON para pipelines
./updateGit_v2.sh --json ~/Projetos > status.json
```

### Opções Completas

| Flag | Descrição |
|------|-----------|
| `-d, --debug` | Modo de depuração |
| `-L, --follow-symlinks` | Segue symlinks na busca |
| `-a, --allow-auth` | Permite prompt de credenciais |
| `-f, --force` | Pull forçado (reset --hard) |
| `-n, --dry-run` | Mostra ações sem executar |
| `-j, --jobs N` | N workers paralelos |
| `--timeout SEC` | Timeout de ops de rede (default 10s) |
| `--retries N` | Retentativas em falhas de rede |
| `--submodules` | `git submodule update --init --recursive` |
| `--lfs` | `git lfs pull` (se repo usa LFS) |
| `--push` | Push após pull bem-sucedido |
| `--gc` | `git gc --auto` ao final |
| `--hooks` | Executa `.gitupdate-hook` no repo (se presente) |
| `-x, --exclude PAT` | Exclui repos (glob; repetível) |
| `--only-failed` | Exibe só os que falharam |
| `--only-dirty` | Processa só repos com alterações locais |
| `--json` | Saída final em JSON |
| `--notify` | Notificação desktop ao fim |
| `--webhook URL` | POST JSON ao fim |

### Config File

Defaults persistentes em `~/.config/gitupdate/config`:

```ini
# Comentários começam com #
DRY_RUN=false
PARALLEL_JOBS=4
NETWORK_TIMEOUT=15
MAX_RETRIES=3
DO_SUBMODULES=true

# Exclusões (pode repetir)
EXCLUDE_PATTERN=node_modules
EXCLUDE_PATTERN=vendor/*
EXCLUDE_PATTERN=*.bak
```

### `.gitupdateignore`

Arquivo no diretório raiz com padrões (formato glob, um por linha):

```
node_modules
archive/*
*-backup
```

### Hooks por Repositório

Se um repo tiver `.gitupdate-hook` (ou `.gitupdate-hook.sh`) executável e você rodar com `--hooks`, o script é executado após o pull bem-sucedido:

```bash
#!/bin/bash
# Exemplo: .gitupdate-hook em projeto Node.js
npm install --silent
```

### Auditoria de Segurança

```bash
# Executar scan completo de segurança
./scripts/security-audit.sh

# Verificar apenas secrets
gitleaks detect --source .

# Análise de vulnerabilidades no código
semgrep --config=auto .
```

### Demo Interativa

```bash
# Executar demonstração das funcionalidades
./demo.sh
```

## 📊 Sistema de Pontuação de Segurança

O projeto inclui um sistema de pontuação que avalia:

- 🔴 **Issues Críticas**: Secrets expostos, vulnerabilidades de alta severidade
- 🟠 **Issues Altas**: Problemas de configuração, falhas de validação
- 🟡 **Issues Médias**: Melhorias de código, warnings importantes  
- 🔵 **Issues Baixas**: TODOs, sugestões de otimização

**Score Atual do Projeto: A+** ⭐

## 🏗️ Arquitetura

### Estrutura Modular

```
GitUpdateProject/
├── lib/                          # Módulos centralizados
│   ├── colors.sh                 # Cores e formatação
│   ├── config.sh                 # Config global + parser CLI + config file
│   ├── excludes.sh               # Padrões de exclusão + .gitupdateignore
│   ├── git_operations.sh         # Pull/fetch/merge/submodule/LFS/push/gc
│   ├── git_utils.sh              # Utilitários Git
│   ├── hooks.sh                  # Hooks pós-update por repo
│   ├── json_report.sh            # Saída JSON estruturada
│   ├── logger.sh                 # Sistema de logging
│   ├── notify.sh                 # Notificações (desktop + webhook)
│   ├── parallel.sh               # Runner paralelo (--jobs N)
│   ├── progress.sh               # Barra de progresso
│   ├── repo_finder.sh            # Detecção de repos (dirs + worktrees)
│   ├── repo_updater.sh           # Lógica de atualização de 1 repo
│   ├── retry.sh                  # Retry com backoff exponencial
│   ├── security_utils.sh         # Utilitários de segurança
│   ├── status.sh                 # Detecção de dirty/ahead/behind
│   └── ui.sh                     # Interface e help
├── scripts/                      # Scripts de automação
│   ├── cleanup-scattered-logs.sh # Limpeza de logs antigos
│   ├── pre-commit-security.sh    # Hook pre-commit
│   ├── security-audit.sh         # Auditoria completa
│   └── setup-security.sh         # Configuração inicial
├── tests/                        # Suite bats
│   ├── config.bats
│   ├── excludes.bats
│   ├── helper.bash
│   ├── retry.bats
│   └── status.bats
├── .github/workflows/            # CI/CD Pipeline
│   ├── build-release.yml
│   └── security-scan.yml
└── security-reports/             # Relatórios gerados (gitignored)
```

### Funcionalidades dos Módulos

- **git_operations.sh**: Pull, fetch, merge com detecção de conflitos
- **repo_finder.sh**: Busca recursiva e detecção inteligente de repos
- **security_utils.sh**: Centralização de 10+ funções de segurança
- **progress.sh**: Barras de progresso animadas com estatísticas

## 🔒 Recursos de Segurança

### Pre-commit Hooks

Validação automática antes de cada commit:
- ✅ Detecção de secrets com Gitleaks
- ✅ Análise de scripts shell com ShellCheck
- ✅ Verificações personalizadas de segurança

### Pipeline CI/CD

GitHub Actions automatizado que executa:
- 🔍 Scan de secrets em todo o código
- 🛡️ Análise de vulnerabilidades com Semgrep
- 📝 Validação de qualidade de código
- 📊 Geração de relatórios de segurança

### Configuração Personalizada

```toml
# .gitleaks.toml - Configuração de detecção de secrets
[extend]
useDefault = true

[[rules]]
id = "custom-rule"
description = "Regra personalizada"
regex = '''sua-regex-aqui'''
```

## 📈 Relatórios e Monitoramento

### Relatórios Automáticos

```bash
# Localização dos relatórios
security-reports/
├── gitleaks-report.json     # Detecção de secrets
├── semgrep-report.json      # Vulnerabilidades
├── shellcheck-report.txt    # Qualidade shell
└── security-summary.md      # Resumo executivo
```

### Métricas de Qualidade

- **Cobertura de Segurança**: 100% dos arquivos analisados
- **Tempo de Scan**: < 30 segundos para projetos médios
- **Falsos Positivos**: < 5% com configuração otimizada
- **Compatibilidade**: 6+ distribuições Linux + macOS

## 🤝 Contribuição

### Como Contribuir

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

### Padrões de Código

- ✅ Scripts devem passar no ShellCheck
- ✅ Seguir convenções de nomenclatura do projeto
- ✅ Incluir testes para novas funcionalidades
- ✅ Documentar funções públicas

## 📝 Changelog

### v2.1.0 (Atual)
- ➕ Execução paralela (`--jobs N`)
- ➕ Dry-run (`--dry-run`)
- ➕ Submódulos, LFS, push, gc (flags opcionais)
- ➕ Retry com backoff exponencial e timeout configurável
- ➕ Exclusões via `--exclude` e `.gitupdateignore`
- ➕ Config file em `~/.config/gitupdate/config`
- ➕ Hooks pós-update (`.gitupdate-hook`)
- ➕ Saída JSON (`--json`)
- ➕ Notificações (desktop + webhook)
- ➕ Detecção de worktrees e filtragem de repos aninhados
- ➕ Detecção de estado dirty/ahead/behind
- ➕ Suite de testes `bats`
- 🔧 Refatoração: comandos como arrays (sem `bash -c`), traps para tempfiles
- 🔧 Correção crítica: `stash + pop` agora preservam alterações locais

### v2.0.0
- ➕ Pipeline de segurança completo (Gitleaks, Semgrep, ShellCheck)
- ➕ Suporte multi-plataforma (Linux, macOS, Windows Git Bash)
- ➕ Módulo de utilitários de segurança centralizado
- 🔧 Refatoração modular

### v1.0.0
- ➕ Sistema básico de atualização Git
- ➕ Interface de linha de comando
- ➕ Logging básico

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🏆 Reconhecimentos

- **Gitleaks**: Por fornecer excelente ferramenta de detecção de secrets
- **Semgrep**: Pela análise estática de código de alta qualidade
- **ShellCheck**: Pelo linting superior de scripts shell
- **Comunidade Open Source**: Pelo suporte e contribuições

## 📞 Suporte

- 🐛 **Issues**: [GitHub Issues](https://github.com/lgldsilva/GitUpdateProject/issues)
- 📧 **Email**: Disponível no perfil GitHub
- 📚 **Documentação**: Consulte `README.md`, `INSTALL.md` e a ajuda do script (`./updateGit_v2.sh --help`)

---

<p align="center">
  <b>⭐ Se este projeto foi útil, considere dar uma estrela no GitHub! ⭐</b>
</p>

<p align="center">
  Feito com ❤️ por <a href="https://github.com/lgldsilva">lgldsilva</a>
</p>
