#!/bin/bash

# Módulo de relatório JSON.
# Acumula entradas por repositório e emite JSON estruturado ao final se --json.

# Include guard
[[ -n "${_JSON_REPORT_SH_LOADED:-}" ]] && return 0
_JSON_REPORT_SH_LOADED=1

# Array paralelo: cada entrada é uma linha JSON pronta
REPO_REPORTS=()

_json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

# report_repo <path> <status:ok|failed|skipped> <reason> <pre_status> <post_status>
report_repo() {
    local path="$1"
    local status="$2"
    local reason="${3:-}"
    local pre="${4:-}"
    local post="${5:-}"

    local entry
    printf -v entry '{"path":"%s","status":"%s","reason":"%s","pre":"%s","post":"%s"}' \
        "$(_json_escape "$path")" \
        "$(_json_escape "$status")" \
        "$(_json_escape "$reason")" \
        "$(_json_escape "$pre")" \
        "$(_json_escape "$post")"
    REPO_REPORTS+=("$entry")
}

# emit_json_report <total> <ok> <failed> [start_ts] [end_ts]
emit_json_report() {
    local total="${1:-0}"
    local ok="${2:-0}"
    local failed="${3:-0}"
    local start_ts="${4:-}"
    local end_ts="${5:-}"

    local n=${#REPO_REPORTS[@]}
    local i joined=""
    for ((i=0; i<n; i++)); do
        if [ $i -eq 0 ]; then
            joined="${REPO_REPORTS[i]}"
        else
            joined+=",${REPO_REPORTS[i]}"
        fi
    done

    printf '{"total":%d,"ok":%d,"failed":%d,"start":"%s","end":"%s","repos":[%s]}\n' \
        "$total" "$ok" "$failed" \
        "$(_json_escape "$start_ts")" \
        "$(_json_escape "$end_ts")" \
        "$joined"
}
