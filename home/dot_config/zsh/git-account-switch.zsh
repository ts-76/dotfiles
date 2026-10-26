git-account-switch() {
    local account="${1:-}"
    local gh_user=""
    local skip_gh="false"
    local quiet="false"

    usage() {
        cat <<'EOF'
Usage:
  git-account-switch [main|sub] [--gh-user <github-username>] [--skip-gh] [--quiet]

Examples:
  git-account-switch main
  git-account-switch sub --gh-user your-sub-account
EOF
    }

    choose_account() {
        local answer
        read -r "answer?Account (main/sub): "
        case "$answer" in
            main|sub)
                printf '%s\n' "$answer"
                ;;
            *)
                return 1
                ;;
        esac
    }

    ensure_credentials() {
        local target_account="$1"
        if [[ "$target_account" == "main" ]]; then
            if [[ -z "${GIT_MAIN_NAME:-}" || -z "${GIT_MAIN_EMAIL:-}" ]]; then
                if command -v dot-cred-refresh >/dev/null 2>&1; then
                    dot-cred-refresh >/dev/null 2>&1 || true
                fi
            fi
            [[ -n "${GIT_MAIN_NAME:-}" && -n "${GIT_MAIN_EMAIL:-}" ]]
            return
        fi

        if [[ -z "${GIT_SUB_NAME:-}" || -z "${GIT_SUB_EMAIL:-}" ]]; then
            if command -v dot-cred-refresh >/dev/null 2>&1; then
                dot-cred-refresh >/dev/null 2>&1 || true
            fi
        fi
        [[ -n "${GIT_SUB_NAME:-}" && -n "${GIT_SUB_EMAIL:-}" ]]
    }

    set_git_identity() {
        local target_account="$1"
        local target_name target_email current_name current_email
        if [[ "$target_account" == "main" ]]; then
            target_name="$GIT_MAIN_NAME"
            target_email="$GIT_MAIN_EMAIL"
        else
            target_name="$GIT_SUB_NAME"
            target_email="$GIT_SUB_EMAIL"
        fi

        current_name="$(git config --local user.name 2>/dev/null || true)"
        current_email="$(git config --local user.email 2>/dev/null || true)"
        if [[ "$current_name" == "$target_name" && "$current_email" == "$target_email" ]]; then
            return 0
        fi

        git config --local user.name "$target_name"
        git config --local user.email "$target_email"
        [[ "$quiet" == "true" ]] || printf 'Switched Git user to %s: %s <%s>\n' "${(U)target_account}" "$target_name" "$target_email"
    }

    switch_gh_account() {
        local target_gh_user="$1"
        local current_gh_user

        if ! command -v gh >/dev/null 2>&1; then
            [[ "$quiet" == "true" ]] || echo "gh is not installed. Skipped gh auth switch." >&2
            return 0
        fi

        if [[ -n "$target_gh_user" ]]; then
            current_gh_user="$(gh config get user --host github.com 2>/dev/null || true)"
            if [[ "$current_gh_user" == "$target_gh_user" ]]; then
                return 0
            fi
            gh auth switch --hostname github.com --user "$target_gh_user"
            return
        fi

        gh auth switch
    }

    shift $(( $# > 0 ? 1 : 0 ))
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --gh-user)
                if [[ $# -lt 2 ]]; then
                    echo "--gh-user requires a value" >&2
                    return 1
                fi
                gh_user="$2"
                shift 2
                ;;
            --skip-gh)
                skip_gh="true"
                shift
                ;;
            --quiet)
                quiet="true"
                shift
                ;;
            -h|--help)
                usage
                return 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                return 1
                ;;
        esac
    done

    if [[ -z "$account" ]]; then
        account="$(choose_account || true)"
    fi

    if [[ "$account" != "main" && "$account" != "sub" ]]; then
        usage
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Run this command inside a git repository." >&2
        return 1
    fi

    if ! ensure_credentials "$account"; then
        if [[ "$account" == "main" ]]; then
            echo "MAIN credentials are not set (GIT_MAIN_NAME/GIT_MAIN_EMAIL)." >&2
        else
            echo "SUB credentials are not set (GIT_SUB_NAME/GIT_SUB_EMAIL)." >&2
        fi
        echo "- Run: chezmoi apply" >&2
        echo "- Or edit: ~/.config/zsh/credentials.local.zsh" >&2
        return 1
    fi

    set_git_identity "$account"

    if [[ "$skip_gh" == "false" ]]; then
        switch_gh_account "$gh_user" || return
        if [[ "$quiet" == "false" ]]; then
            gh auth status --active --hostname github.com || true
        fi
    fi

    if [[ "$quiet" == "false" ]]; then
        echo "Current local git identity:"
        echo "  Name:  $(git config --local user.name)"
        echo "  Email: $(git config --local user.email)"
    fi
}
