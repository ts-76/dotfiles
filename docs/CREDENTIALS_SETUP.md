# 認証情報設定（HTTPS運用）

このドキュメントは、GitHub連携を HTTPS + `gh` で運用する手順をまとめています。

## 目次

- [chezmoi init時の設定](#chezmoi-init時の設定)
- [生成されるGit認証情報ファイル](#生成されるgit認証情報ファイル)
- [gh 認証セットアップ（HTTPS）](#gh-認証セットアップhttps)
- [Gitユーザー/ghアカウントの切り替え](#gitユーザーghアカウントの切り替え)
- [repo単位でmain/subを自動判定する](#repo単位でmainsubを自動判定する)
- [セキュリティ注意点](#セキュリティ注意点)
- [(任意) SSH運用が必要な場合](#任意-ssh運用が必要な場合)

## chezmoi init時の設定

初回の `chezmoi init --apply` で以下を入力します。

- `name` / `email`
- `dot_git_main_name` / `dot_git_main_email`（空なら `name` / `email` を利用）
- `dot_git_sub_name` / `dot_git_sub_email`（任意）
- `dot_workspace_create`（workspaceフォルダを作成するか）

`GITHUB_MAIN_USERNAME` / `GITHUB_SUB_USERNAME` は `GIT_MAIN_NAME` / `GIT_SUB_NAME` と同じ値で生成されます。

## 生成されるGit認証情報ファイル

`~/.config/zsh/credentials.local.zsh` は chezmoi が自動生成します。

例:

```sh
export GIT_MAIN_NAME="Your Name"
export GIT_MAIN_EMAIL="you@example.com"
export GITHUB_MAIN_USERNAME="Your Name"
export GIT_SUB_NAME="Sub Name"
export GIT_SUB_EMAIL="you@sub.example"
export GITHUB_SUB_USERNAME="Sub Name"
```

値を変更する場合:

```bash
chezmoi apply
# または
chezmoi edit ~/.config/zsh/credentials.local.zsh
```

確認:

```bash
dot-cred-refresh
dot-cred-status
```

## gh 認証セットアップ（HTTPS）

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

## repo単位でmain/subを自動判定する

初回だけrepoを紐づける場合:

```bash
git-account-bind main
# または
git-account-bind sub
```

`git-account-bind` は以下を実行します。

1. `dot-cred-refresh` で環境変数を再読込
2. `dot.account` をrepoローカルへ保存
3. `GITHUB_MAIN_USERNAME` / `GITHUB_SUB_USERNAME`（= Git name）から `dot.ghUser.<account>` を保存
4. `.envrc` を生成し、`DOT_ACCOUNT` を設定して `git-account-auto --direnv` を呼ぶ
5. `direnv allow` を実行（direnv導入済みの場合）

日常運用:

```bash
git-account-auto
```

`.envrc` から自動実行されるモード（`--direnv`）では非対話で動作し、未確定情報がある場合は安全にスキップします。

`git-account-auto` の判定優先順位:

1. `git config --local dot.account`（`git-account-bind` で保存した値）
2. `git config --local user.email` と `GIT_MAIN_EMAIL` / `GIT_SUB_EMAIL` の一致
3. `dot.mainOwners` / `dot.subOwners` と origin owner の一致（任意設定）
4. 判定不能時は `main/sub` を質問して `dot.account` に保存

補足（ownerベース判定を使う場合）:

```bash
git config --global dot.mainOwners "your-main-org,your-main-user"
git config --global dot.subOwners "your-sub-org,your-sub-user"
```

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
