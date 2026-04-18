# Testes

Testes automatizados com [bats-core](https://github.com/bats-core/bats-core).

## Instalar bats

```bash
# Arch Linux
sudo pacman -S bats

# Ubuntu/Debian
sudo apt install bats

# Fedora
sudo dnf install bats

# macOS
brew install bats-core

# npm (multiplataforma)
npm install -g bats
```

## Rodar

```bash
# Tudo
bats tests/

# Arquivo específico
bats tests/excludes.bats

# Verbose
bats --print-output-on-failure tests/
```

## Estrutura

- `helper.bash` — utilitários compartilhados (`load_lib`, `make_repo`).
- `excludes.bats` — padrões de exclusão e `.gitupdateignore`.
- `retry.bats` — retry com backoff.
- `status.bats` — detecção dirty/ahead/behind.
- `config.bats` — parser CLI e config file.

## Escrever novos testes

```bats
#!/usr/bin/env bats

load helper

setup() {
    load_lib colors.sh
    load_lib config.sh
    load_lib meu_modulo.sh
}

@test "descrição do caso" {
    run minha_funcao arg
    [ "$status" -eq 0 ]
    [ "$output" = "esperado" ]
}
```
