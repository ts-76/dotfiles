#!/usr/bin/env zsh

# Runtime credentials loader.
#
# Concepts:
# - Account: MAIN / SUB (git config switch)
# - Backend: where credentials come from on *this machine* (local file or 1Password)
#
# Goals:
# - Private PC: use 1Password (`op`) managed values.
# - Work PC: read from a local file (no 1Password dependency).
# - No output at shell startup.

_dot_has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

_dot_log() {
  [[ "${DOT_CRED_VERBOSE:-0}" == "1" ]] || return 0
  print -r -- "$@" >&2
}

_dot_cred_local_file() {
  print -r -- "${DOT_CRED_LOCAL_FILE:-$HOME/.config/zsh/credentials.local.zsh}"
}

_dot_cred_backend() {
  # auto|local|op
  print -r -- "${DOT_CRED_BACKEND:-auto}"
}

_dot_profile() {
  # private|work|auto
  print -r -- "${DOT_PROFILE:-auto}"
}

dot-cred-source-local() {
  local f
  f="$(_dot_cred_local_file)"
  if [[ -f "$f" ]]; then
    source "$f"
    return 0
  fi
  return 1
}

dot-cred-source-op() {
  _dot_has_cmd op || return 1

  local main_name_ref main_email_ref sub_name_ref sub_email_ref
  main_name_ref="${DOT_OP_GIT_MAIN_NAME_REF:-op://Personal/Git Main Account/name}"
  main_email_ref="${DOT_OP_GIT_MAIN_EMAIL_REF:-op://Personal/Git Main Account/email}"
  sub_name_ref="${DOT_OP_GIT_SUB_NAME_REF:-op://Personal/Git Sub Account/name}"
  sub_email_ref="${DOT_OP_GIT_SUB_EMAIL_REF:-op://Personal/Git Sub Account/email}"

  # Don't prompt at startup: this is intended to be called manually.
  local main_name main_email sub_name sub_email
  main_name="$(op read "$main_name_ref" 2>/dev/null)" || return 1
  main_email="$(op read "$main_email_ref" 2>/dev/null)" || return 1
  sub_name="$(op read "$sub_name_ref" 2>/dev/null)" || return 1
  sub_email="$(op read "$sub_email_ref" 2>/dev/null)" || return 1

  export GIT_MAIN_NAME="$main_name"
  export GIT_MAIN_EMAIL="$main_email"
  export GIT_SUB_NAME="$sub_name"
  export GIT_SUB_EMAIL="$sub_email"
  return 0
}

dot-cred-refresh() {
  # Load credentials into env vars.
  # Policy:
  # - local: local file only
  # - op: op only
  # - auto: local if present, else op
  local backend profile
  backend="$(_dot_cred_backend)"
  profile="$(_dot_profile)"

  # If user didn't pin backend, a profile can guide the default.
  if [[ "$backend" == "auto" ]]; then
    case "$profile" in
      private) backend="op";;
      work) backend="local";;
      auto) :;;
      *)
        _dot_log "dot-cred-refresh: unknown DOT_PROFILE=$profile (expected: private|work|auto)";
        return 2
        ;;
    esac
  fi

  case "$backend" in
    local)
      dot-cred-source-local
      ;;
    op)
      dot-cred-source-op
      ;;
    auto)
      dot-cred-source-local || dot-cred-source-op
      ;;
    *)
      _dot_log "dot-cred-refresh: unknown DOT_CRED_BACKEND=$backend (expected: auto|local|op)"
      return 2
      ;;
  esac
}

dot-cred-status() {
  local backend f
  backend="$(_dot_cred_backend)"
  f="$(_dot_cred_local_file)"
  print -r -- "DOT_CRED_BACKEND=$backend"
  print -r -- "DOT_CRED_LOCAL_FILE=$f"
  print -r -- "op=$(command -v op 2>/dev/null || print -r -- 'not-found')"
  print -r -- "GIT_MAIN_NAME=${GIT_MAIN_NAME:-}"
  print -r -- "GIT_MAIN_EMAIL=${GIT_MAIN_EMAIL:-}"
  print -r -- "GIT_SUB_NAME=${GIT_SUB_NAME:-}"
  print -r -- "GIT_SUB_EMAIL=${GIT_SUB_EMAIL:-}"
}

_dot_github_main_key_path() {
  print -r -- "${DOT_GITHUB_MAIN_SSH_KEY:-$HOME/.ssh/id_ed25519_github_main}"
}

_dot_github_sub_key_path() {
  print -r -- "${DOT_GITHUB_SUB_SSH_KEY:-$HOME/.ssh/id_ed25519_github_sub}"
}

_dot_ssh_mkdir_and_perms() {
  local dir
  dir="$HOME/.ssh"
  mkdir -p "$dir" || return 1
  chmod 700 "$dir" 2>/dev/null || true
}

_dot_ssh_fix_key_perms() {
  local key="$1"
  chmod 600 "$key" 2>/dev/null || true
  if [[ -f "$key.pub" ]]; then
    chmod 644 "$key.pub" 2>/dev/null || true
  fi
}

dot-github-ssh-key-ensure() {
  # Usage:
  #   dot-github-ssh-key-ensure [--source local|gen|op] [--force]
  #
  # Source meanings:
  # - local: require key file exists
  # - gen: generate key if missing
  # - op: read private key from 1Password
  #   - use DOT_OP_GITHUB_MAIN_SSH_PRIVATE_KEY_REF / DOT_OP_GITHUB_SUB_SSH_PRIVATE_KEY_REF via wrapper funcs
  local source force
  source="${DOT_GITHUB_SSH_SOURCE:-auto}"
  force=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --source)
        source="$2"; shift 2;;
      --force)
        force=1; shift;;
      -h|--help)
        print -r -- "dot-github-ssh-key-ensure [--source local|gen|op] [--force]"; return 0;;
      *)
        print -r -- "dot-github-ssh-key-ensure: unknown arg: $1" >&2; return 2;;
    esac
  done

  local key
  key="${DOT_GITHUB_SSH_KEY:-}"
  if [[ -z "$key" ]]; then
    print -r -- "dot-github-ssh-key-ensure: DOT_GITHUB_SSH_KEY is not set (use dot-github-main-ssh-key-ensure or dot-github-sub-ssh-key-ensure)" >&2
    return 2
  fi

  _dot_ssh_mkdir_and_perms || return 1

  if [[ "$source" == "auto" ]]; then
    # If key already exists, just use it.
    if [[ -f "$key" ]]; then
      source="local"
    # If op is available and ref is configured, prefer op.
    elif _dot_has_cmd op && [[ -n "${DOT_OP_GITHUB_SSH_PRIVATE_KEY_REF:-}" ]]; then
      source="op"
    # Otherwise generate locally.
    else
      source="gen"
    fi
  fi

  case "$source" in
    local)
      [[ -f "$key" ]] || { print -r -- "SSH key not found: $key" >&2; return 1; }
      _dot_ssh_fix_key_perms "$key"
      ;;
    gen)
      if [[ -f "$key" ]]; then
        _dot_ssh_fix_key_perms "$key"
        return 0
      fi
      _dot_has_cmd ssh-keygen || { print -r -- "ssh-keygen not found" >&2; return 1; }
      local comment
      comment="${GIT_MAIN_EMAIL:-${GIT_SUB_EMAIL:-github}}"
      ssh-keygen -t ed25519 -a 64 -f "$key" -N "" -C "$comment" >/dev/null
      _dot_ssh_fix_key_perms "$key"
      ;;
    op)
      _dot_has_cmd op || { print -r -- "op not found" >&2; return 1; }
       local ref
       ref="${DOT_OP_GITHUB_SSH_PRIVATE_KEY_REF:-}"
       if [[ -z "$ref" ]]; then
        print -r -- "1Password ref is not set. Set DOT_OP_GITHUB_MAIN_SSH_PRIVATE_KEY_REF or DOT_OP_GITHUB_SUB_SSH_PRIVATE_KEY_REF." >&2
        print -r -- "Recommended: op://<vault-id>/<item-id>/private key?ssh-format=openssh" >&2
        print -r -- "(You can obtain IDs with: op vault list, op item list --vault <vault>)" >&2
        return 2
       fi
      if [[ -f "$key" && "$force" != "1" ]]; then
        _dot_ssh_fix_key_perms "$key"
        return 0
      fi
      umask 077
      op read "$ref" >| "$key" || return 1
      _dot_ssh_fix_key_perms "$key"
      ;;
    *)
      print -r -- "dot-github-ssh-key-ensure: unknown source: $source (expected: local|gen|op|auto)" >&2
      return 2
      ;;
  esac

  if [[ ! -f "$key.pub" ]] && _dot_has_cmd ssh-keygen; then
    ssh-keygen -y -f "$key" >| "$key.pub" 2>/dev/null || true
    _dot_ssh_fix_key_perms "$key"
  fi
}

dot-github-main-ssh-key-ensure() {
  DOT_GITHUB_SSH_KEY="$(_dot_github_main_key_path)" \
  DOT_OP_GITHUB_SSH_PRIVATE_KEY_REF="${DOT_OP_GITHUB_MAIN_SSH_PRIVATE_KEY_REF:-}" \
  dot-github-ssh-key-ensure "$@"
}

dot-github-sub-ssh-key-ensure() {
  DOT_GITHUB_SSH_KEY="$(_dot_github_sub_key_path)" \
  DOT_OP_GITHUB_SSH_PRIVATE_KEY_REF="${DOT_OP_GITHUB_SUB_SSH_PRIVATE_KEY_REF:-}" \
  dot-github-ssh-key-ensure "$@"
}

dot-github-ssh-pubkey() {
  local key
  key="${DOT_GITHUB_SSH_KEY:-}"
  if [[ -z "$key" ]]; then
    print -r -- "dot-github-ssh-pubkey: set DOT_GITHUB_SSH_KEY or use dot-github-main-ssh-pubkey/dot-github-sub-ssh-pubkey" >&2
    return 2
  fi
  [[ -f "$key" ]] || { print -r -- "SSH key not found: $key" >&2; return 1; }
  if [[ -f "$key.pub" ]]; then
    cat "$key.pub"
    return 0
  fi
  _dot_has_cmd ssh-keygen || { print -r -- "ssh-keygen not found" >&2; return 1; }
  ssh-keygen -y -f "$key"
}

dot-github-main-ssh-pubkey() {
  DOT_GITHUB_SSH_KEY="$(_dot_github_main_key_path)" dot-github-ssh-pubkey
}

dot-github-sub-ssh-pubkey() {
  DOT_GITHUB_SSH_KEY="$(_dot_github_sub_key_path)" dot-github-ssh-pubkey
}
