_dot_git_account_valid() {
    [[ "$1" == "main" || "$1" == "sub" ]]
}

_dot_git_account_env_user() {
    local account="$1"
    if [[ "$account" == "main" ]]; then
        printf '%s\n' "${GITHUB_MAIN_USERNAME:-}"
        return
    fi
    printf '%s\n' "${GITHUB_SUB_USERNAME:-}"
}

_dot_git_write_envrc() {
    local account="$1"
    cat > .envrc <<EOF
export DOT_ACCOUNT="$account"

if command -v zsh >/dev/null 2>&1; then
  zsh -lc 'source "\$HOME/.config/zsh/credentials.zsh"; source "\$HOME/.config/zsh/git-account-switch.zsh"; source "\$HOME/.config/zsh/git-account-auto.zsh"; git-account-auto --direnv' >/dev/null 2>&1 || true
fi
EOF
}

_dot_git_origin_owner() {
    local remote path owner
    remote="$(git remote get-url origin 2>/dev/null || true)"
    [[ -n "$remote" ]] || return 1

    case "$remote" in
        *://*/*)
            path="${remote#*://}"
            path="${path#*/}"
            ;;
        *@*:*/*)
            path="${remote#*:}"
            ;;
        *)
            return 1
            ;;
    esac

    owner="${path%%/*}"
    [[ -n "$owner" ]] || return 1
    printf '%s\n' "$owner"
}

_dot_git_owner_matches() {
    local owner candidates candidate
    owner="$1"
    candidates="$2"
    [[ -n "$owner" && -n "$candidates" ]] || return 1

    for candidate in ${(s:,:)candidates}; do
        candidate="${candidate## }"
        candidate="${candidate%% }"
        [[ -n "$candidate" ]] || continue
        [[ "$owner" == "$candidate" ]] && return 0
    done
    return 1
}

_dot_git_detect_account() {
    local account email owner main_owners sub_owners

    account="${DOT_ACCOUNT:-}"
    if _dot_git_account_valid "$account"; then
        printf '%s\n' "$account"
        return 0
    fi

    account="$(git config --local --get dot.account 2>/dev/null || true)"
    if _dot_git_account_valid "$account"; then
        printf '%s\n' "$account"
        return 0
    fi

    email="$(git config --local --get user.email 2>/dev/null || true)"
    if [[ -n "$email" ]]; then
        if [[ -n "${GIT_MAIN_EMAIL:-}" && "$email" == "$GIT_MAIN_EMAIL" ]]; then
            printf 'main\n'
            return 0
        fi
        if [[ -n "${GIT_SUB_EMAIL:-}" && "$email" == "$GIT_SUB_EMAIL" ]]; then
            printf 'sub\n'
            return 0
        fi
    fi

    owner="$(_dot_git_origin_owner || true)"
    if [[ -n "$owner" ]]; then
        main_owners="$(git config --get dot.mainOwners 2>/dev/null || true)"
        sub_owners="$(git config --get dot.subOwners 2>/dev/null || true)"

        if _dot_git_owner_matches "$owner" "$main_owners"; then
            printf 'main\n'
            return 0
        fi
        if _dot_git_owner_matches "$owner" "$sub_owners"; then
            printf 'sub\n'
            return 0
        fi
    fi

    return 1
}

git-account-bind() {
    local account gh_user
    account="${1:-}"

    if ! _dot_git_account_valid "$account"; then
        echo "Usage: git-account-bind [main|sub] [--gh-user <github-username>]" >&2
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Run this command inside a git repository." >&2
        return 1
    fi

    shift
    if [[ $# -gt 0 ]]; then
        echo "Usage: git-account-bind [main|sub]" >&2
        return 1
    fi

    if command -v dot-cred-refresh >/dev/null 2>&1; then
        dot-cred-refresh >/dev/null 2>&1 || true
    fi

    gh_user="$(_dot_git_account_env_user "$account")"

    git config --local dot.account "$account"
    if [[ -n "$gh_user" ]]; then
        git config --local "dot.ghUser.$account" "$gh_user"
    fi

    _dot_git_write_envrc "$account"
    if command -v direnv >/dev/null 2>&1; then
        direnv allow || true
    fi

    echo "Bound repo account: $account"
    if [[ -n "$gh_user" ]]; then
        echo "Saved gh username for $account: $gh_user"
    else
        echo "Note: GITHUB_${(U)account}_USERNAME is empty. gh switch will be skipped in auto mode."
    fi
    echo "Generated .envrc with DOT_ACCOUNT=$account"
}

git-account-auto() {
    local account gh_user direnv_mode
    direnv_mode="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --direnv)
                direnv_mode="true"
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        [[ "$direnv_mode" == "true" ]] && return 0
        echo "Run this command inside a git repository." >&2
        return 1
    fi

    if command -v dot-cred-refresh >/dev/null 2>&1; then
        dot-cred-refresh >/dev/null 2>&1 || true
    fi

    account="$(_dot_git_detect_account || true)"
    if ! _dot_git_account_valid "$account"; then
        if [[ "$direnv_mode" == "true" ]]; then
            return 0
        fi
        read -r "account?Account for this repo (main/sub): "
        if ! _dot_git_account_valid "$account"; then
            echo "Invalid account: $account" >&2
            return 1
        fi
        git config --local dot.account "$account"
        echo "Saved repo account: $account"
    fi

    gh_user="$(git config --local --get "dot.ghUser.$account" 2>/dev/null || true)"
    if [[ -z "$gh_user" ]]; then
        gh_user="$(git config --global --get "dot.ghUser.$account" 2>/dev/null || true)"
    fi
    if [[ -z "$gh_user" ]]; then
        gh_user="$(_dot_git_account_env_user "$account")"
    fi
    if [[ -z "$gh_user" ]]; then
        if [[ "$direnv_mode" == "true" ]]; then
            git-account-switch "$account" --skip-gh
            return $?
        fi
        read -r "gh_user?GitHub username for ${(U)account} (empty to skip): "
        if [[ -n "$gh_user" ]]; then
            git config --local "dot.ghUser.$account" "$gh_user"
        fi
    fi

    if [[ -n "$gh_user" ]]; then
        git-account-switch "$account" --gh-user "$gh_user"
    else
        git-account-switch "$account"
    fi
}
