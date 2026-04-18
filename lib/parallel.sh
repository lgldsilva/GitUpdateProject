#!/bin/bash

# Módulo de execução paralela.
# Dado um callback e um array de argumentos, roda até N workers simultâneos.
# Saída de cada worker é bufferizada em arquivo temporário e despejada em ordem
# ao final para manter o log coerente.

# Include guard
[[ -n "${_PARALLEL_SH_LOADED:-}" ]] && return 0
_PARALLEL_SH_LOADED=1

# shellcheck source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
# shellcheck source=lib/logger.sh
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# Callback usado internamente: recebe <git_dir> <logfile> <statusfile>
# e chama update_one_repo. O resultado é acumulado em PARALLEL_RESULTS.
_parallel_worker() {
    local git_dir="$1"
    local logfile="$2"
    local statusfile="$3"
    local callback="$4"

    # Redireciona stdout/stderr deste worker para o logfile
    {
        "$callback" "$git_dir"
        echo "$?" > "$statusfile"
    } >"$logfile" 2>&1
}

# run_parallel <callback> <git_dir_1> [<git_dir_2> ...]
# Consome FOUND_GIT_DIRS, popula PARALLEL_STATUSES (paralelo ao array de dirs).
run_parallel() {
    local callback="${1:?ERRO: callback não informado}"
    shift
    local -a dirs=("$@")

    local n=${#dirs[@]}
    [ "$n" -eq 0 ] && return 0

    local jobs="${PARALLEL_JOBS:-1}"
    [ "$jobs" -lt 1 ] && jobs=1
    [ "$jobs" -gt "$n" ] && jobs=$n

    local tmpdir
    tmpdir=$(mktemp -d -t gitupdate-parallel.XXXXXX)
    trap 'rm -rf "$tmpdir"' RETURN

    local -a logfiles=()
    local -a statusfiles=()
    local -a pids=()
    local active=0
    local i

    for ((i=0; i<n; i++)); do
        local logfile="$tmpdir/log-$i"
        local statusfile="$tmpdir/status-$i"
        logfiles[i]="$logfile"
        statusfiles[i]="$statusfile"

        while [ "$active" -ge "$jobs" ]; do
            # Esperar qualquer job terminar
            if wait -n 2>/dev/null; then
                :
            else
                # Shell sem `wait -n` — esperar o mais antigo
                wait "${pids[0]}" 2>/dev/null || true
                pids=("${pids[@]:1}")
            fi
            active=$((active - 1))
        done

        _parallel_worker "${dirs[i]}" "$logfile" "$statusfile" "$callback" &
        pids+=($!)
        active=$((active + 1))
    done

    wait

    # Consolidar saída em ordem original. PARALLEL_STATUSES é consumido pelo main.
    # Em modo JSON, o log dos workers vai para stderr (stdout é reservado para o JSON).
    # shellcheck disable=SC2034
    PARALLEL_STATUSES=()
    for ((i=0; i<n; i++)); do
        if [ -f "${logfiles[i]}" ]; then
            if [ "${JSON_OUTPUT:-false}" = true ]; then
                cat "${logfiles[i]}" >&2
            else
                cat "${logfiles[i]}"
            fi
        fi
        if [ -f "${statusfiles[i]}" ]; then
            # shellcheck disable=SC2034
            PARALLEL_STATUSES[i]=$(cat "${statusfiles[i]}")
        else
            # shellcheck disable=SC2034
            PARALLEL_STATUSES[i]=1
        fi
    done
}
