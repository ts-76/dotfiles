dot-gh-onboard() {
    local setup_git="true"
    local account
    local gh_user
    local name_var
    local email_var

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-setup-git)
                setup_git="false"
                shift
                ;;
            -h|--help)
                cat <<'EOF'
Usage:
  dot-gh-onboard [--skip-setup-git]

Flow:
  1) Validate MAIN/SUB git name/email variables
  2) Confirm gh login for MAIN/SUB (login when missing)
  3) Configure gh credential helper for HTTPS (unless --skip-setup-git)
EOF
                return 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    if ! command -v gh >/dev/null 2>&1; then
        echo "gh is not installed." >&2
        return 1
    fi

    if command -v dot-cred-refresh >/dev/null 2>&1; then
        dot-cred-refresh >/dev/null 2>&1 || true
    fi

    for account in main sub; do
        if [[ "$account" == "main" ]]; then
            name_var="${GIT_MAIN_NAME:-}"
            email_var="${GIT_MAIN_EMAIL:-}"
        else
            name_var="${GIT_SUB_NAME:-}"
            email_var="${GIT_SUB_EMAIL:-}"
        fi

        if [[ -z "$name_var" || -z "$email_var" ]]; then
            echo "Skip $account: git identity is not configured (name/email)." >&2
            continue
        fi

        read -r "gh_user?GitHub username for ${account^^} (empty to skip): "

        if [[ -z "$gh_user" ]]; then
            echo "Skip $account: GitHub username is not provided."
            continue
        fi

        if gh auth switch -u "$gh_user" >/dev/null 2>&1; then
            echo "OK $account: gh account '$gh_user' is available."
        else
            echo "Login required for $account ($gh_user)."
            gh auth login --hostname github.com --git-protocol https --web || return 1
            gh auth switch -u "$gh_user" >/dev/null 2>&1 || {
                echo "Failed to switch gh account to '$gh_user'." >&2
                echo "Run: gh auth switch -u $gh_user" >&2
                return 1
            }
        fi
    done

    if [[ "$setup_git" == "true" ]]; then
        gh auth setup-git --hostname github.com
    fi

    gh auth status
}
