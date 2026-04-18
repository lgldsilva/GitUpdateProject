#!/bin/bash

# GitUpdate System v2.1 - Sistema Modular de Atualização de Repositórios Git
# Script principal que orquestra todos os módulos do sistema.

# Resolver diretório base seguindo symlinks (cross-platform)
_resolve_script_dir() {
    local src="${BASH_SOURCE[0]}"
    local i=0
    while [ -L "$src" ] && [ $i -lt 10 ]; do
        local target
        target="$(readlink "$src")"
        [[ "$target" != /* ]] && target="$(dirname "$src")/$target"
        src="$target"
        i=$((i + 1))
    done
    (cd "$(dirname "$src")" && pwd)
}

SCRIPT_DIR="$(_resolve_script_dir)"
LIB_DIR="$SCRIPT_DIR/lib"

# Fallback: buscar lib/ em locais comuns
if [ ! -d "$LIB_DIR" ]; then
    for possible_dir in \
        "/opt/GitUpdateProject" \
        "/usr/local/share/GitUpdateProject" \
        "/opt/homebrew/share/GitUpdateProject" \
        "$HOME/.local/share/GitUpdateProject" \
        "$(dirname "$0")" \
        "$(pwd)"; do
        if [ -d "$possible_dir/lib" ]; then
            SCRIPT_DIR="$possible_dir"
            LIB_DIR="$SCRIPT_DIR/lib"
            [[ "${DEBUG:-}" == "1" ]] && echo "🔄 Usando instalação em $SCRIPT_DIR"
            break
        fi
    done
fi

if [ ! -d "$LIB_DIR" ]; then
    echo "❌ ERRO: diretório lib/ não encontrado ($LIB_DIR)" >&2
    exit 1
fi

# Carregar módulos (ordem importa: dependências antes)
for lib_file in \
        colors.sh \
        config.sh \
        logger.sh \
        progress.sh \
        ui.sh \
        excludes.sh \
        retry.sh \
        status.sh \
        git_utils.sh \
        git_operations.sh \
        hooks.sh \
        parallel.sh \
        json_report.sh \
        notify.sh \
        repo_finder.sh \
        repo_updater.sh; do
    lib_path="$LIB_DIR/$lib_file"
    if [ -f "$lib_path" ]; then
        # shellcheck source=/dev/null
        source "$lib_path"
    else
        echo "❌ ERRO: Biblioteca não encontrada: $lib_path" >&2
        exit 1
    fi
done

main() {
    # Carregar config file antes do parse CLI (CLI sobrescreve)
    load_config_file

    # Processar flags
    configure_settings "$@"

    # Em modo JSON, desabilitar saída colorida/progresso e header
    local json_mode=false
    [ "${JSON_OUTPUT:-false}" = true ] && json_mode=true

    if [ "$json_mode" != true ]; then
        show_header
    fi

    cleanup_old_logs

    if [ "$json_mode" != true ]; then
        show_log_location
    fi

    # Processar argumentos posicionais
    local root_dir="$PWD"
    if [ ${#REMAINING_ARGS[@]} -gt 0 ]; then
        for arg in "${REMAINING_ARGS[@]}"; do
            case "$arg" in
                -h|--help)
                    show_help
                    exit 0
                    ;;
                *)
                    if [ -d "$arg" ]; then
                        root_dir="$(cd "$arg" && pwd)"
                    else
                        erro_log "Diretório '$arg' não existe."
                        exit 1
                    fi
                    ;;
            esac
        done
    fi

    log "Iniciando GitUpdate System v2.1"
    log "Diretório de trabalho: $root_dir"
    local start_ts
    start_ts=$(date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || date)

    # Resumo de flags ativas
    [ "$DEBUG_MODE" = true ]       && log "Modo debug: ATIVO"
    [ "$DRY_RUN" = true ]          && aviso_log "Modo DRY-RUN: nenhuma alteração será aplicada"
    [ "$FORCE_PULL" = true ]       && aviso_log "Modo FORCE: alterações locais serão descartadas"
    [ "$FOLLOW_SYMLINKS" = true ]  && log "Seguindo symlinks"
    [ "$PARALLEL_JOBS" -gt 1 ]     && log "Paralelismo: $PARALLEL_JOBS workers"
    [ "$DO_SUBMODULES" = true ]    && log "Submódulos: ATIVO"
    [ "$DO_LFS" = true ]           && log "LFS: ATIVO"
    [ "$DO_PUSH" = true ]          && log "Push: ATIVO"
    [ "$DO_GC" = true ]            && log "GC: ATIVO"
    [ "$RUN_HOOKS" = true ]        && log "Hooks: ATIVO"
    [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ] && log "Exclusões (${#EXCLUDE_PATTERNS[@]}): ${EXCLUDE_PATTERNS[*]}"

    # Resolver symlinks do root_dir se aplicável
    if [ -L "$root_dir" ]; then
        local link_target
        link_target=$(readlink -f "$root_dir" 2>/dev/null \
            || realpath "$root_dir" 2>/dev/null \
            || (cd "$root_dir" && pwd -P))
        log "Diretório raiz é symlink → $link_target"
    fi

    local initial_dir="$PWD"
    local total_repos=0
    local updated_repos=0
    local failed_repos=0

    if find_git_repositories "$root_dir"; then
        draw_progress_bar

        if [ "$PARALLEL_JOBS" -gt 1 ]; then
            # Modo paralelo: roda workers, coleta statuses, imprime logs na ordem
            run_parallel _run_one_repo "${FOUND_GIT_DIRS[@]}"
            local i
            for ((i=0; i<${#FOUND_GIT_DIRS[@]}; i++)); do
                ((total_repos++))
                local s="${PARALLEL_STATUSES[i]:-1}"
                if [ "$s" -eq 0 ]; then
                    ((updated_repos++))
                    report_repo "$(dirname "${FOUND_GIT_DIRS[i]}")" "ok" "" "" ""
                else
                    ((failed_repos++))
                    local path
                    path="$(dirname "${FOUND_GIT_DIRS[i]}")"
                    record_failure "$path" "status=$s"
                    report_repo "$path" "failed" "status=$s" "" ""
                fi
                increment_progress
            done
        else
            # Sequencial
            for git_dir in "${FOUND_GIT_DIRS[@]}"; do
                ((total_repos++))
                local repo_dir="${git_dir%/.git}"
                [ "$repo_dir" = "$git_dir" ] && repo_dir="$(dirname "$git_dir")"
                local rel="${repo_dir#"$root_dir"/}"
                log "Encontrado: $rel"

                if update_git_repo "$repo_dir"; then
                    ((updated_repos++))
                    report_repo "$repo_dir" "ok" "" "${LAST_PRE_STATUS:-}" "${LAST_POST_STATUS:-}"
                else
                    ((failed_repos++))
                    record_failure "$rel" "ver log"
                    report_repo "$repo_dir" "failed" "ver log" "${LAST_PRE_STATUS:-}" "${LAST_POST_STATUS:-}"
                fi
                increment_progress
            done
        fi

        finish_progress_bar
    fi

    cd "$initial_dir" || exit

    local end_ts
    end_ts=$(date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || date)

    if [ "$json_mode" = true ]; then
        emit_json_report "$total_repos" "$updated_repos" "$failed_repos" "$start_ts" "$end_ts"
    else
        show_summary "$total_repos" "$updated_repos" "$failed_repos"
    fi

    notify_completion "$total_repos" "$updated_repos" "$failed_repos"

    if [ "$json_mode" != true ]; then
        wait_for_user
    fi

    [ $failed_repos -gt 0 ] && exit 1
    exit 0
}

# Wrapper usado pelo runner paralelo (recebe path do .git, executa update).
_run_one_repo() {
    local git_dir="$1"
    local repo_dir
    if [ -d "$git_dir" ]; then
        repo_dir="$(dirname "$git_dir")"
    else
        repo_dir="$(dirname "$git_dir")"
    fi
    update_git_repo "$repo_dir"
}

main "$@"
