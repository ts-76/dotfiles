#!/usr/bin/env bash
set -euo pipefail

tmp="/tmp/yazi-chosen-$$"

yazi --chooser-file="$tmp"

if [[ -s "$tmp" ]]; then
    paths=$(cat "$tmp")

    # search:// 形式の場合、実際のパスを抽出
    if [[ "$paths" == search://* ]]; then
        paths=$(echo "$paths" | sed 's|search://[^/]*/||')
    fi

    rm -f "$tmp"

    # Close the floating pane, then feed :open to Helix.
    zellij action toggle-floating-panes
    zellij action write 27
    zellij action write-chars ":open \"$paths\""
    zellij action write 13
else
    rm -f "$tmp"
    zellij action toggle-floating-panes
fi
