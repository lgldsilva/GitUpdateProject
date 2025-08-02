# Correção: Log Centralizado

## Problema Identificado

Os arquivos `updateGit.log` estavam sendo criados no diretório atual onde o script era executado, causando:
- **Poluição dos repositórios**: Cada repositório ficava com um arquivo de log
- **Espalhamento desnecessário**: Logs eram criados em diversos locais
- **Dificuldade de rastreamento**: Logs espalhados eram difíceis de encontrar e gerenciar

## Solução Implementada

### 1. **Log Centralizado com Timestamp**
- **Local**: `~/.local/share/GitUpdateProject/logs/`
- **Formato**: `updateGit_YYYYMMDD_HHMMSS.log`
- **Fallback**: Se não conseguir criar no home, usa `/tmp/GitUpdateProject-logs-$(id -u)/`

### 2. **Limpeza Automática**
- Mantém apenas os **10 logs mais recentes**
- Limpeza automática executada a cada execução
- Evita acúmulo excessivo de arquivos de log

### 3. **Informações ao Usuário**
- Mostra a localização do log no início da execução
- Exibe no resumo final onde o log foi salvo
- Fornece comando para visualizar o log: `cat "caminho/do/log"`

### 4. **Script de Limpeza**
- **Arquivo**: `scripts/cleanup-scattered-logs.sh`
- **Função**: Remove logs antigos espalhados pelos repositórios
- **Modo dry-run**: Permite visualizar o que seria removido antes de executar

## Arquivos Modificados

### `lib/config.sh`
```bash
# Antes
export LOG_FILE="updateGit.log"

# Depois
LOG_BASE_DIR="${HOME}/.local/share/GitUpdateProject/logs"
LOG_TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
export LOG_FILE="$LOG_BASE_DIR/updateGit_${LOG_TIMESTAMP}.log"
```

### `lib/logger.sh`
- Adicionada função `show_log_location()` para informar onde o log será salvo

### `lib/ui.sh`
- Modificada função `show_summary()` para mostrar localização do log no final

### `updateGit_v2.sh`
- Adicionada chamada para `show_log_location()` após o cabeçalho

## Como Usar

### 1. **Execução Normal**
```bash
./updateGit_v2.sh ~/Projetos
```
- Agora mostra onde o log será salvo
- Log centralizado em `~/.local/share/GitUpdateProject/logs/`

### 2. **Limpar Logs Antigos Espalhados**
```bash
# Ver o que seria removido (dry-run)
./scripts/cleanup-scattered-logs.sh ~/Projetos --dry-run

# Remover logs espalhados
./scripts/cleanup-scattered-logs.sh ~/Projetos
```

### 3. **Visualizar Logs**
```bash
# Ver o log mais recente
ls -la ~/.local/share/GitUpdateProject/logs/

# Ver conteúdo do log
cat ~/.local/share/GitUpdateProject/logs/updateGit_20250802_143022.log
```

## Benefícios

✅ **Não polui mais os repositórios** - Logs ficam centralizados  
✅ **Timestamps únicos** - Evita conflitos entre execuções simultâneas  
✅ **Limpeza automática** - Mantém apenas logs recentes  
✅ **Melhor rastreabilidade** - Usuário sabe exatamente onde encontrar os logs  
✅ **Fácil manutenção** - Script de limpeza para remover logs antigos espalhados  
✅ **Compatibilidade** - Funciona em qualquer sistema com fallback para /tmp  

## Migração

Para usuários que já tinham logs espalhados:

1. **Execute o script de limpeza**:
   ```bash
   ./scripts/cleanup-scattered-logs.sh ~/seus-projetos
   ```

2. **Verifique o resultado**:
   - Logs antigos serão removidos dos repositórios
   - Novos logs serão criados centralizadamente

3. **Localização dos novos logs**:
   - `~/.local/share/GitUpdateProject/logs/updateGit_TIMESTAMP.log`
