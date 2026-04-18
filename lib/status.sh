#!/bin/bash

# Módulo de detecção de status do repositório

# Include guard
[[ -n "${_STATUS_SH_LOADED:-}" ]] && return 0
_STATUS_SH_LOADED=1

# Retorna 0 se há alterações não commitadas (staged + unstaged + untracked).
is_dirty() {
    # -s = porcelain curto; qualquer saída indica alterações
    [ -n "$(git status --porcelain 2>/dev/null)" ]
}

# Conta commits LOCAIS ainda não enviados ao upstream (ahead).
# Ecoa número inteiro; 0 se não há upstream ou se está em sync.
count_ahead() {
    git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0
}

# Conta commits no upstream ainda não integrados localmente (behind).
count_behind() {
    git rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0
}

# Resumo curto (ex: "clean" / "dirty+2 ahead" / "dirty")
repo_status_summary() {
    local parts=()
    is_dirty && parts+=("dirty")
    local ahead behind
    ahead=$(count_ahead)
    behind=$(count_behind)
    [ "$ahead" -gt 0 ]  && parts+=("$ahead ahead")
    [ "$behind" -gt 0 ] && parts+=("$behind behind")

    if [ ${#parts[@]} -eq 0 ]; then
        echo "clean"
    else
        local IFS=','
        echo "${parts[*]}"
    fi
}
