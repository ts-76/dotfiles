git-account-switch() {
    local account="${1:-}"
    local gh_user=""
    local skip_gh="false"

    usage() {
        cat <<'EOF'
Usage:
  git-account-switch [main|sub] [--gh-user <github-username>] [--skip-gh]

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
        if [[ "$target_account" == "main" ]]; then
            git config --local user.name "$GIT_MAIN_NAME"
            git config --local user.email "$GIT_MAIN_EMAIL"
            printf 'Switched Git user to MAIN: %s <%s>\n' "$GIT_MAIN_NAME" "$GIT_MAIN_EMAIL"
            return
        fi

        git config --local user.name "$GIT_SUB_NAME"
        git config --local user.email "$GIT_SUB_EMAIL"
        printf 'Switched Git user to SUB: %s <%s>\n' "$GIT_SUB_NAME" "$GIT_SUB_EMAIL"
    }

    switch_gh_account() {
        local target_gh_user="$1"

        if ! command -v gh >/dev/null 2>&1; then
            echo "gh is not installed. Skipped gh auth switch." >&2
            return 0
        fi

        if [[ -n "$target_gh_user" ]]; then
            gh auth switch -u "$target_gh_user"
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
        switch_gh_account "$gh_user"
        gh auth status || true
    fi

    echo "Current local git identity:"
    echo "  Name:  $(git config --local user.name)"
    echo "  Email: $(git config --local user.email)"
}
