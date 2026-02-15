# 認証情報設定（Private/Work）

このドキュメントは、Private PC（1Password）と Work PC（ローカル）の両方で同じdotfilesを使うための、認証情報（Git/SSH/gh）の設定手順をまとめています。

## 目次

- [使い分けの概要](#使い分けの概要)
- [chezmoi init時の設定](#chezmoi-init時の設定)
- [Work PC（ローカル方式 / 1Passwordなし）](#work-pcローカル方式--1passwordなし)
- [Private PC（1Password）](#private-pc1password)
- [Gitユーザー切り替え（MAIN/SUB）](#gitユーザー切り替えmainsub)
- [GitHub SSH（main/sub鍵とHostエイリアス）](#github-sshmainsub鍵とhostエイリアス)
- [git remoteの使い分け（github-main/github-sub）](#git-remoteの使い分けgithub-maingithub-sub)
- [リポジトリ単位で認証を切り替える（SSH/HTTPS）](#リポジトリ単位で認証を切り替えるsshhttps)
- [gh が使えるまで](#gh-が使えるまで)
- [(任意) PCごとの挙動固定（profile.local.zsh）](#任意-pcごとの挙動固定profilelocalzsh)

## 使い分けの概要

- PCの種類: Private / Work（どこから認証情報を読むか）
- アカウント: MAIN / SUB（gitの `user.name` / `user.email` を切り替えるための区分）

使うファイル/仕組み:

- `~/.config/zsh/profile.local.zsh`（chezmoi生成）: PCごとの既定（Private/Work）
- `~/.config/zsh/credentials.local.zsh`（手元で作成）: Work PCでの `GIT_MAIN_*` / `GIT_SUB_*`
- `~/.ssh/config`（chezmoi生成）: `github-main` / `github-sub` のHostエイリアスで鍵を切替

## chezmoi init時の設定

初回の `chezmoi init --apply` で以下が質問されます。

- `dot_profile`: `private` / `work`
- `dot_workspace_create`: `y` / `n`（workspaceフォルダを作成するか）
- (privateのみ/任意) GitHub MAIN/SUB の SSH鍵を 1Password から取得するための vault-id / item-id

生成物:

- `~/.config/zsh/profile.local.zsh`

後から変更したい場合:

```bash
chezmoi edit ~/.config/zsh/profile.local.zsh
chezmoi apply
```

## Work PC（ローカル方式 / 1Passwordなし）

### Git認証情報（名前/メール）

以下のファイルを手元で作成してください（chezmoi管理外）。

`~/.config/zsh/credentials.local.zsh`:

```sh
export GIT_MAIN_NAME="Your Name"
export GIT_MAIN_EMAIL="you@example.com"
export GIT_SUB_NAME="Sub Name"
export GIT_SUB_EMAIL="you@sub.example"
```

読み込み確認:

```bash
dot-cred-refresh
dot-cred-status
```

### GitHub SSH鍵（ローカル生成）

```bash
dot-github-main-ssh-key-ensure --source gen
dot-github-main-ssh-pubkey

dot-github-sub-ssh-key-ensure --source gen
dot-github-sub-ssh-pubkey
```

表示した公開鍵を、それぞれ対応するGitHubアカウントに登録してください。

## Private PC（1Password）

### 前提

- 1Password アプリがセットアップ済み
- 1Password CLI (`op`) がインストール済み

### Git認証情報（名前/メール）

1Passwordに以下の値を保存します。

- MAIN
  - `op://Personal/Git Main Account/name`
  - `op://Personal/Git Main Account/email`
- SUB
  - `op://Personal/Git Sub Account/name`
  - `op://Personal/Git Sub Account/email`

補足:

- SUB を使わない場合（SUB アカウントを作らない場合）は、SUB 側のアイテムは未作成でも構いません
  - この場合 `dot-cred-refresh` は MAIN だけ読み込み、`GIT_SUB_NAME` / `GIT_SUB_EMAIL` は空のままになります

読み込み:

```bash
eval "$(op signin)"
dot-cred-refresh
dot-cred-status
```

### GitHub SSH鍵（Private: 1Passwordから取得）

このdotfilesは、1Passwordを「鍵の保管庫」として使い、必要時に `op read` で秘密鍵を
`~/.ssh/id_ed25519_github_main` / `~/.ssh/id_ed25519_github_sub` に書き出して利用します。

ここでは、vault名/item名ではなく、vault-id/item-id を指定します（名前変更に強い）。
テンプレート側で OpenSSH 形式（`?ssh-format=openssh`）の参照に変換します。

```bash
# まずは sign-in（既に有効なら不要）
eval "$(op signin)"

# vault-id / item-id の調べ方
op vault list
op item list --vault <vault>

# 以降は、chezmoi init 時に入力した vault-id / item-id から
# ~/.config/zsh/profile.local.zsh が環境変数を生成します。
# (必要なら: chezmoi edit ~/.config/zsh/profile.local.zsh; chezmoi apply)

# 鍵を書き出す
dot-github-main-ssh-key-ensure --source op
dot-github-main-ssh-pubkey

dot-github-sub-ssh-key-ensure --source op
dot-github-sub-ssh-pubkey
```

補足:

- vault-id/item-id を未設定の場合は、`--source op` でも鍵は生成されません（参照先が無い）。
- 以前の設定で `DOT_OP_GITHUB_*_SSH_PRIVATE_KEY_REF` を name ベースで書いていた場合は、
  `~/.config/zsh/profile.local.zsh` を再生成（または編集）してください。

## Gitユーザー切り替え（MAIN/SUB）

```bash
gmain
gsub
```

## GitHub SSH（main/sub鍵とHostエイリアス）

`~/.ssh/config` は以下のHostエイリアスで鍵を切り替えます。

- MAIN: `github.com` / `github-main` → `~/.ssh/id_ed25519_github_main`
- SUB: `github-sub` → `~/.ssh/id_ed25519_github_sub`

疎通確認:

```bash
ssh -T git@github-main
ssh -T git@github-sub
```

## git remoteの使い分け（github-main/github-sub）

リモートURLのホスト名で、どの鍵を使うかが決まります。

- MAIN: `git@github-main:OWNER/REPO.git`（または `git@github.com:OWNER/REPO.git`）
- SUB: `git@github-sub:OWNER/REPO.git`

既存repoでの切り替え例:

```bash
git remote -v
git remote set-url origin git@github-sub:OWNER/REPO.git
git remote -v
```

## リポジトリ単位で認証を切り替える（SSH/HTTPS）

ここでいう「認証の切り替え」は、GitHub に対する `git fetch/push` の“権限として使われる”認証手段を、リポジトリごとに切り替えることを指します。

結論:

- リポジトリ内だけで閉じたいなら SSH（remoteのホストエイリアス、または `core.sshCommand`）が扱いやすいです
- HTTPS に寄せるなら repoローカルの `credential.helper=!gh auth git-credential` を使うと、ghのトークン管理に寄せられます

### ケースA: SSH（OpenSSHで管理する / repoに閉じやすい）

#### A1) remote URL のホスト名で切り替え（推奨）

このドキュメントの [git remoteの使い分け（github-main/github-sub）](#git-remoteの使い分けgithub-maingithub-sub) の方式です。

#### A2) repoローカルの `core.sshCommand` で強制する

`~/.ssh/config` を使わずに、リポジトリ単位で「どの鍵を使うか」を固定したい場合に使えます。

例:

```bash
git config --local core.sshCommand "ssh -i ~/.ssh/id_ed25519_github_sub -o IdentitiesOnly=yes"
```

direnvで自動化したい場合（`.envrc` は各repo直下に作成）:

```sh
# .envrc
git config --local core.sshCommand "ssh -i ~/.ssh/id_ed25519_github_sub -o IdentitiesOnly=yes"
```

### ケースB: HTTPS（gh credential helperに寄せる）

前提:

- remote が HTTPS（例: `https://github.com/OWNER/REPO.git`）
- `gh auth login` 済み

repoローカルに credential helper を設定:

```bash
git config --local credential.helper "!gh auth git-credential"
git config --local credential.useHttpPath true
```

direnvで自動化したい場合:

```sh
# .envrc
git config --local credential.helper "!gh auth git-credential"
git config --local credential.useHttpPath true
```

補足（重要）:

- `gh auth switch` は gh の“アクティブアカウント”をグローバルに切り替えるため、repoに閉じた切り替えには向きません
- repoごとに `GH_TOKEN` を注入する方式もありますが、トークンをファイルで扱うことになるため、`.envrc.local` に置いて絶対にコミットしない運用が必須です

## gh が使えるまで

```bash
gh auth login
gh auth status
```

補足:

- `gh` の認証（トークン）と、gitのSSH鍵は別物です
- `gh auth login` の途中で Git operations を SSH にすると、既存のSSH公開鍵をアップロードする選択肢が出ます
  - このセットアップで作成した `~/.ssh/id_ed25519_github_main.pub` / `~/.ssh/id_ed25519_github_sub.pub` も対象になります
  - main/sub を両方登録したい場合は、それぞれの公開鍵を選んでアップロードしてください
- originの解釈で詰まる場合は `gh -R OWNER/REPO <command>` のように `-R` で明示してください

## (任意) PCごとの挙動固定（profile.local.zsh）

`~/.config/zsh/profile.local.zsh` で `DOT_PROFILE` / `DOT_CRED_BACKEND` / `DOT_GITHUB_SSH_SOURCE` などを固定できます。
