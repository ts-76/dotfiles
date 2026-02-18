# SSH運用セットアップ（必要時のみ）

このドキュメントは、GitHubへのGit操作をSSH鍵で行いたい場合の手順です。
通常運用は `docs/CREDENTIALS_SETUP.md` の HTTPS + `gh` を推奨します。

## 対象

- remote URL を `git@...` 形式で使う
- `github-main` / `github-sub` のHostエイリアスで鍵を切り替える

## 鍵の準備

```bash
dot-github-main-ssh-key-ensure --source gen
dot-github-main-ssh-pubkey

dot-github-sub-ssh-key-ensure --source gen
dot-github-sub-ssh-pubkey
```

表示した公開鍵を、対応するGitHubアカウントに登録します。

## SSH接続確認

```bash
ssh -T git@github-main
ssh -T git@github-sub
```

## remote URL の使い分け

- MAIN: `git@github-main:OWNER/REPO.git`（または `git@github.com:OWNER/REPO.git`）
- SUB: `git@github-sub:OWNER/REPO.git`

切り替え例:

```bash
git remote -v
git remote set-url origin git@github-sub:OWNER/REPO.git
git remote -v
```

## repo単位で鍵を固定する（任意）

`core.sshCommand` をrepoローカルで指定できます。

```bash
git config --local core.sshCommand "ssh -i ~/.ssh/id_ed25519_github_sub -o IdentitiesOnly=yes"
```
