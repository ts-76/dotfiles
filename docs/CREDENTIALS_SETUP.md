# 認証情報設定（HTTPS運用）

このドキュメントは、Private/WorkのPC差分を維持しつつ、GitHub連携をHTTPS + `gh` で運用する手順をまとめています。

## 目次

- [使い分けの概要](#使い分けの概要)
- [chezmoi init時の設定](#chezmoi-init時の設定)
- [Git認証情報（MAIN/SUB）](#git認証情報mainsub)
- [gh 認証セットアップ（HTTPS）](#gh-認証セットアップhttps)
- [Gitユーザー/ghアカウントの切り替え](#gitユーザーghアカウントの切り替え)
- [セキュリティ注意点](#セキュリティ注意点)
- [(任意) SSH運用が必要な場合](#任意-ssh運用が必要な場合)

## 使い分けの概要

- PCの種類: `private` / `work`（どこから認証情報を読むか）
- アカウント: `MAIN` / `SUB`（gitの `user.name` / `user.email` を切り替えるための区分）

使うファイル/仕組み:

- `~/.config/zsh/profile.local.zsh`（chezmoi生成）: PCごとの既定（private/work）
- `~/.config/zsh/credentials.local.zsh`（手元で作成）: ローカル管理時の `GIT_MAIN_*` / `GIT_SUB_*`
- `~/.config/zsh/credentials.zsh`: `DOT_PROFILE` に応じて local / 1Password の取得元を切り替え

## chezmoi init時の設定

初回の `chezmoi init --apply` で以下が質問されます。

- `dot_profile`: `private` / `work`
- `dot_workspace_create`: `y` / `n`（workspaceフォルダを作成するか）
- (privateのみ/任意) GitHub SSH鍵用の 1Password vault-id / item-id

生成物:

- `~/.config/zsh/profile.local.zsh`

後から変更したい場合:

```bash
chezmoi edit ~/.config/zsh/profile.local.zsh
chezmoi apply
```

## Git認証情報（MAIN/SUB）

### Work PC（ローカル方式）

以下のファイルを手元で作成してください（chezmoi管理外）。

`~/.config/zsh/credentials.local.zsh`:

```sh
export GIT_MAIN_NAME="Your Name"
export GIT_MAIN_EMAIL="you@example.com"
export GIT_SUB_NAME="Sub Name"
export GIT_SUB_EMAIL="you@sub.example"
```

### Private PC（1Password方式）

1Passwordに以下の値を保存します。

- MAIN
  - `op://Personal/Git Main Account/name`
  - `op://Personal/Git Main Account/email`
- SUB
  - `op://Personal/Git Sub Account/name`
  - `op://Personal/Git Sub Account/email`

読み込み確認（Work/Private共通）:

```bash
dot-cred-refresh
dot-cred-status
```

## gh 認証セットアップ（HTTPS）

まず `gh` をHTTPS運用でログインします。

```bash
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git --hostname github.com
gh auth status
```

この設定で、HTTPS remote（`https://github.com/...`）の `fetch/push` は `gh` のcredential helper経由で認証されます。

## Gitユーザー/ghアカウントの切り替え

### repoローカルの git user + gh アカウント切り替え

```bash
git-account-switch main
git-account-switch sub
```

`git-account-switch` は `GIT_MAIN_*` / `GIT_SUB_*` を使って、現在のrepoへ `git config --local user.name` / `user.email` を設定し、続けて `gh auth switch` を実行します。

### 初回オンボーディング（MAIN/SUB分）

```bash
dot-gh-onboard
```

`dot-gh-onboard` は以下を順に実行します。

1. `GIT_MAIN_*` / `GIT_SUB_*` の存在確認
2. MAIN/SUBそれぞれで `gh auth switch -u <username>` を試行
3. 未ログインなら `gh auth login --git-protocol https --web` を実行
4. 最後に `gh auth setup-git` と `gh auth status`

## セキュリティ注意点

- 2FAは必須ですが、CLIのGit操作はトークン認証なのでトークン保護が重要です
- `gh auth login` 後は `gh auth status` で保存先/状態を確認してください
- `GH_TOKEN` をファイルに置く運用は避ける（必要なら `.envrc.local` 等で非コミットを厳守）

## (任意) SSH運用が必要な場合

SSH鍵での運用手順は別ドキュメントに分離しています。

- [`docs/CREDENTIALS_SSH_SETUP.md`](./CREDENTIALS_SSH_SETUP.md)
