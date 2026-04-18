#!/bin/bash

# Módulo de notificações (desktop + webhook).
# Cross-platform: notify-send (Linux), osascript (macOS), PowerShell (Windows/Git Bash).

# Include guard
[[ -n "${_NOTIFY_SH_LOADED:-}" ]] && return 0
_NOTIFY_SH_LOADED=1

# shellcheck source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Notificação desktop best-effort. Silencioso se backend indisponível.
_desktop_notify() {
    local title="$1"
    local body="$2"

    case "$OSTYPE" in
        darwin*)
            if command -v osascript >/dev/null 2>&1; then
                osascript -e "display notification \"${body//\"/\\\"}\" with title \"${title//\"/\\\"}\"" >/dev/null 2>&1
            fi
            ;;
        msys*|cygwin*)
            if command -v powershell.exe >/dev/null 2>&1; then
                powershell.exe -NoProfile -Command \
                    "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; \
                     \$n = New-Object System.Windows.Forms.NotifyIcon; \
                     \$n.Icon = [System.Drawing.SystemIcons]::Information; \
                     \$n.Visible = \$true; \
                     \$n.ShowBalloonTip(5000, '$title', '$body', 'Info')" \
                    >/dev/null 2>&1 || true
            fi
            ;;
        linux*|*)
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "$title" "$body" 2>/dev/null || true
            fi
            ;;
    esac
}

_webhook_notify() {
    local url="$1"
    local payload="$2"
    [ -z "$url" ] && return 0

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -X POST -H "Content-Type: application/json" -d "$payload" "$url" >/dev/null 2>&1 || true
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- --header="Content-Type: application/json" --post-data="$payload" "$url" >/dev/null 2>&1 || true
    fi
}

# notify_completion <total> <ok> <failed>
notify_completion() {
    local total="$1"
    local ok="$2"
    local failed="$3"

    local title="GitUpdate concluído"
    local body="$ok/$total atualizados, $failed com erro"

    if [ "$NOTIFY" = true ]; then
        _desktop_notify "$title" "$body"
    fi

    if [ -n "$WEBHOOK_URL" ]; then
        local payload
        printf -v payload '{"total":%d,"ok":%d,"failed":%d,"title":"%s","body":"%s"}' \
            "$total" "$ok" "$failed" "$title" "$body"
        _webhook_notify "$WEBHOOK_URL" "$payload"
    fi
}
