# グローバルのエージェントスキル

GitHub 配布のスキルを APM でユーザー単位に導入します。chezmoi は [apm.yml](../home/dot_apm/apm.yml) と [apm.lock.yaml](../home/dot_apm/apm.lock.yaml) を `~/.apm/` に配置します。APM は共通のスキルディレクトリと Claude Code 向けのディレクトリに展開します。

初期構成は Vercel Skills に登録されていた37件です。各スキルのディレクトリと Git コミット SHA を固定しています。`yomiyasu` は APM で通常のスキルとして導入できる v3.1.0 を採用しています。

## 新しい端末で復元する

dotfiles のセットアップ後、APM が使えるシェルで実行します。この構成は APM 0.37.0 で検証しています。Apple Silicon の Mac では Devbox のツール定義で APM を導入します。

```bash
chezmoi apply ~/.apm
apm install --global --only apm --https --frozen
apm deps list --global
```

Codex と Cursor が参照する `~/.agents/skills/` と、Claude Code が参照する `~/.claude/skills/` に配置されます。`chezmoi apply` で設定を配布し、`apm install` で固定版を取得します。

## Vercel Skills から移行する

すでに使っている端末では、APM に切り替えるスキルの既存ディレクトリやシンボリックリンクを、スキルの検索対象外に退避してから復元します。退避対象は `apm.yml` に載せたスキルの同名エントリです。Vercel Skills の通常の削除コマンドは共有ディレクトリとリンクを消すため、退避と復元が済んだスキルの管理は以降 APM に任せます。

## 更新する

1. `chezmoi edit ~/.apm/apm.yml` で、更新したいスキルのパスとコミット SHA を確認して変更します。
2. `chezmoi apply ~/.apm/apm.yml` で編集した定義を配置し、`apm install --global --only apm --https --no-frozen` でロックファイルを再生成します。
3. `chezmoi re-add ~/.apm/apm.lock.yaml` でロックファイルをソースに反映し、マニフェストとロックファイルの差分をまとめて確認します。

ライブラリに同梱されるスキルは、各プロジェクトの依存関係と一緒に更新します。
