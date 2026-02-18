# =============================================================================
# エイリアス設定
# =============================================================================

# リスト表示 (eza がある場合は使用)
if command -v eza > /dev/null 2>&1; then
    alias ls="eza --icons --git"
    alias ll="eza -la --icons --git"
    alias lt="eza -T --icons --level=2"
    alias tree="eza --tree --icons"
else
    if [ "$(uname)" = "Darwin" ]; then
        alias ls="ls -G"
        alias ll="ls -laG"
    else
        alias ls="ls --color=auto"
        alias ll="ls -la"
    fi
fi

# cat の代替 (bat がある場合は使用)
if command -v bat > /dev/null 2>&1; then
    alias cat="bat --paging=never"
    alias less="bat"
fi

# Git 短縮
alias g="git"
alias gs="git status"
alias gd="git diff"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline -20"

# よく使うコマンド
alias c="clear"
alias q="exit"
alias v="hx"
alias vi="hx"
alias vim="hx"

# 確認付き操作
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# grep にカラー表示
alias grep="grep --color=auto"

# mkdir は親ディレクトリも作成
alias mkdir="mkdir -pv"

# =============================================================================
# 開発ツール
# =============================================================================

# Lazygit (Git TUI)
if command -v lazygit > /dev/null 2>&1; then
    alias lg="lazygit"
fi

# Chezmoi (dotfiles管理)
if command -v chezmoi > /dev/null 2>&1; then
    alias cm="chezmoi"
    alias cma="chezmoi apply"
    alias cme="chezmoi edit"
    alias cmd="chezmoi diff"
    alias cms="chezmoi status"
    alias cmu="chezmoi update"
fi

# Zellij (ターミナルマルチプレクサ)
if command -v zellij > /dev/null 2>&1; then
    alias zj="zellij attach main --create"
    alias zja="zellij a"
    alias zjl="zellij ls"
    alias zjk="zellij k"
    alias zjka="zellij ka"
    alias zjda="zellij da"
fi

# =============================================================================
# Workspace ナビゲーション
# =============================================================================

# Workspace ディレクトリへの移動 (zoxide使用)
# Note: zoxide は --cmd cd で初期化されているため、cd コマンドを使用
if command -v zoxide > /dev/null 2>&1; then
    alias ws='cd $HOME/workspace'
    alias wsp='cd $HOME/workspace/personal'
    alias wsw='cd $HOME/workspace/work'
fi
