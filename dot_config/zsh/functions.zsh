# =============================================================================
# カスタム関数
# =============================================================================

# ディレクトリを作成して移動
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# fzfでディレクトリを選択して移動
fcd() {
    local dir
    dir=$(find ${1:-.} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzf +m) && cd "$dir"
}

# fzfでファイルを選択してエディタで開く
fe() {
    local file
    file=$(fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:60%) && ${EDITOR:-hx} "$file"
}

# fzfでgit branchを選択してcheckout
fco() {
    local branches branch
    branches=$(git branch -a) &&
    branch=$(echo "$branches" | fzf +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# 指定したポートを使用しているプロセスを表示
port() {
    if command -v lsof >/dev/null 2>&1; then
        lsof -i ":$1"
        return
    fi
    if command -v ss >/dev/null 2>&1; then
        ss -ltnp 2>/dev/null | command grep -E "[:.]$1\b" || true
        return
    fi
    echo "No supported tool found (need: lsof or ss)"
    return 1
}

# 指定したポートのプロセスをkill
killport() {
    if command -v lsof >/dev/null 2>&1; then
        local pids
        pids=$(lsof -ti ":$1" 2>/dev/null || true)
        if [ -z "$pids" ]; then
            echo "No process found on port $1"
            return 0
        fi
        echo "$pids" | xargs kill -9
        return
    fi
    if command -v fuser >/dev/null 2>&1; then
        fuser -k "$1/tcp"
        return
    fi
    echo "No supported tool found (need: lsof or fuser)"
    return 1
}

# tarを簡単に展開
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.tar.xz)    tar xJf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.zip)       unzip "$1"       ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# =============================================================================
# Git ユーザー切り替え
# =============================================================================
gsub() {
    git-account-switch sub --skip-gh
}

gmain() {
    git-account-switch main --skip-gh
}

gwho() {
    echo "Name:  $(git config user.name)"
    echo "Email: $(git config user.email)"
}

# =============================================================================
# SSH エージェント管理（必要時のみ手動実行）
# =============================================================================
ssh-start() {
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)"
        echo "SSH agent started"
    else
        echo "SSH agent already running (SSH_AUTH_SOCK=$SSH_AUTH_SOCK)"
    fi
}

ssh-add-key() {
    local key="${1:-$HOME/.ssh/id_ed25519}"
    if [ -f "$key" ]; then
        ssh-add "$key"
    else
        echo "Key not found: $key"
        return 1
    fi
}

# macOS専用: キーチェーンから鍵をロード
ssh-load-keychain() {
    if [[ "$(uname)" == "Darwin" ]]; then
        ssh-add --apple-load-keychain 2>/dev/null && echo "Loaded SSH keys from macOS keychain"
    else
        echo "This function is only available on macOS"
        return 1
    fi
}
