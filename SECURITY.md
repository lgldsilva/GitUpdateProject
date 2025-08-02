# Security Policy

## Reportando Vulnerabilidades de Segurança

Se você descobrir uma vulnerabilidade de segurança neste projeto, por favor nos informe de forma responsável seguindo as diretrizes abaixo.

### 🔒 Como Reportar

1. **NÃO** crie uma issue pública no GitHub
2. Envie um email para: [luiz.guilherme.89@outlook.com]
3. Inclua o máximo de detalhes possível:
   - Descrição da vulnerabilidade
   - Passos para reproduzir
   - Impacto potencial
   - Versão afetada

### ⏱️ Tempo de Resposta

- **Confirmação inicial**: 48 horas
- **Avaliação completa**: 7 dias úteis
- **Correção**: Dependendo da severidade (1-30 dias)

### 🛡️ Processo de Correção

1. Validação da vulnerabilidade
2. Desenvolvimento da correção
3. Testes de segurança
4. Release da correção
5. Divulgação coordenada

## Versões Suportadas

| Versão | Suporte de Segurança |
| ------ | ------------------- |
| 2.0.x  | ✅ Suportada       |
| 1.x.x  | ❌ Não suportada   |

## Configurações de Segurança

### Scripts de Segurança Incluídos

- `scripts/pre-commit-security.sh`: Verificações antes do commit
- `scripts/security-audit.sh`: Auditoria completa de segurança
- `.github/workflows/security-scan.yml`: Pipeline CI/CD de segurança
- `.gitleaks.toml`: Configuração de detecção de secrets

### Execução dos Scripts

```bash
# Auditoria completa
./scripts/security-audit.sh

# Verificação pré-commit (configurar como hook)
./scripts/pre-commit-security.sh
```

## Melhores Práticas de Segurança

### Para Desenvolvedores

1. **Nunca** commite secrets, tokens ou credenciais
2. Use variáveis de ambiente para configurações sensíveis
3. Execute `./scripts/security-audit.sh` regularmente
4. Configure o hook de pré-commit
5. Mantenha dependências atualizadas

### Para Usuários

1. Revise o código antes de executar
2. Execute apenas de fontes confiáveis
3. Use permissões mínimas necessárias
4. Monitore logs por atividade suspeita

## Configuração do Git Hook

Para configurar a verificação automática de segurança:

```bash
# Configurar hook de pré-commit
ln -sf ../../scripts/pre-commit-security.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Pipeline de Segurança

Este projeto inclui uma pipeline automatizada de segurança que:

- ✅ Detecta secrets e credenciais (Gitleaks)
- ✅ Analisa vulnerabilidades de código (Semgrep)
- ✅ Verifica scripts shell (ShellCheck)
- ✅ Executa verificações personalizadas
- ✅ Gera relatórios detalhados

## Ferramentas de Segurança Utilizadas

| Ferramenta | Propósito | Status |
|-----------|-----------|---------|
| Gitleaks | Detecção de secrets | ✅ Configurado |
| Semgrep | Análise de código | ✅ Configurado |
| ShellCheck | Análise de shell scripts | ✅ Configurado |
| Custom Checks | Verificações específicas | ✅ Configurado |

## Exclusões e Falsos Positivos

Para configurar exclusões, edite:
- `.gitleaks.toml` - Para detecção de secrets
- `scripts/security-audit.sh` - Para verificações personalizadas

## Contato

Para questões relacionadas à segurança:
- Email: [luiz.guilherme.89@outlook.com]
- Security Advisory: [Link para GitHub Security Advisory]

---

**Última atualização**: 2 de agosto de 2025
