# dotfiles

macOS、Linux、WSL2 向けの CLI・開発環境設定です。chezmoi で設定ファイルを配置し、Devbox と Bun でツールを管理します。Graphify は Devbox の `uv` で導入します。

## セットアップ

Git、chezmoi、Nix、Devbox、Zsh を先にインストールしてください。

```bash
chezmoi init --apply https://github.com/ts-76/dotfiles.git
devbox global install
eval "$(devbox global shellenv)"
~/.local/bin/dot-graphify-install
jq -r '.dependencies | to_entries[] | "\(.key)@\(.value)"' ~/.bun/install/global/package.json \
  | xargs bun add --global
exec zsh
```

`chezmoi apply` は設定ファイル、Devbox・Bun のマニフェスト、Graphify の導入スクリプトを配置します。パッケージ導入は上記のコマンドで実行してください。

Vite+ のグローバル CLI `vp` は、[nix-vite-plus](https://github.com/ryoppippi/nix-vite-plus) の Nix flake を Devbox から導入します。現在の flake は Apple Silicon の macOS、x86_64 と aarch64 の Linux に対応しています。WSL2 は Linux として扱います。更新には `devbox global update` を使います。

Node.js、Bun、pnpm も Devbox で管理します。

認証情報の初期設定では名前、メールアドレス、Git MAIN/SUB の情報を入力します。GitHub のユーザー名は Git の表示名とは別に任意で入力します。

```bash
devbox global list
bun pm -g ls --depth 0
vp --version
wrangler --version
hono --help
ast-grep --version
graphify --help
command -v node bun pnpm vp spf herdr
```

## 既存環境を移行する

不要になった Bun global パッケージを削除してから、新しい定義を適用してください。マニフェストからの削除だけでは、既存のグローバルパッケージの削除を保証しません。

```bash
bun remove --global @google/gemini-cli @larksuiteoapi/lark-mcp aws-azure-login oh-my-opencode
chezmoi diff
chezmoi apply
devbox global install
eval "$(devbox global shellenv)"
~/.local/bin/dot-graphify-install
jq -r '.dependencies | to_entries[] | "\(.key)@\(.value)"' ~/.bun/install/global/package.json \
  | xargs bun add --global
exec zsh
```

`.chezmoiremove` は、以前管理していた Zellij、Yazi、OpenCode、lazygit、Starship の設定ファイル、Helix の Yazi picker を削除します。対象は列挙したファイルだけです。認証情報やセッションデータ、親ディレクトリは削除しません。

ターミナル管理は `herdr`、ファイル管理は `spf` を起動してください。Helix からのファイル選択は標準の `Space f` を使います。

## ツールの管理元

### Devbox

定義は [`dot_local/share/devbox/global/default/devbox.json`](dot_local/share/devbox/global/default/devbox.json) にあります。適用先は `~/.local/share/devbox/global/default/devbox.json` です。

| 用途 | パッケージ |
| --- | --- |
| ランタイム・パッケージ管理 | `nodejs_24`、`bun`、`pnpm`、`uv` |
| Web 開発 | `vite-plus`（起動コマンドは `vp`） |
| Git・ホスティング | `gh`、`glab`、`ghq` |
| エディタ・ファイル管理 | `helix`、`superfile`（起動コマンドは `spf`） |
| 検索・移動 | `ripgrep`、`fd`、`fzf`、`zoxide` |
| コードの構文検索・書き換え | `ast-grep` |
| シェル・環境 | `zsh-powerlevel10k`、`direnv` |
| ファイル表示 | `eza`、`bat` |
| ターミナル管理 | `herdr` |
| データ処理 | `jq`、`yq`、`xq` |
| 認証 | `_1password-cli`（`op`） |
| コミット検査 | `prek` |
| AI 開発支援 | `github-copilot-cli`、`takt` |
| Web 取得 | `ax` |

`herdr`、`takt`、`ax`、`vite-plus` は GitHub の Nix flake を参照します。`direnv` は `2.36.0`、その他の通常パッケージは `latest` を指定しています。Devbox の lockfile はローカル生成で、このリポジトリには含めません。

```bash
devbox global install
devbox global update
```

### Bun global

定義は [`dot_bun/install/global/package.json`](dot_bun/install/global/package.json) にあります。適用先は `~/.bun/install/global/package.json` です。

| パッケージ | 用途 |
| --- | --- |
| `@anthropic-ai/claude-code` | Claude Code |
| `@hono/cli` | Hono CLI |
| `@openai/codex` | Codex CLI |
| `mastracode` | Mastra Code |
| `@playwright/cli` | ブラウザ操作・自動化 |
| `wrangler` | Cloudflare Workers などの管理 |

```bash
jq -r '.dependencies | to_entries[] | "\(.key)@\(.value)"' ~/.bun/install/global/package.json \
  | xargs bun add --global
```

### Graphify

[`dot_local/bin/executable_dot-graphify-install`](dot_local/bin/executable_dot-graphify-install) を `~/.local/bin/dot-graphify-install` として配置します。このスクリプトは `uv tool` で公式パッケージ `graphifyy==0.9.90` を Python 3.12 の環境に導入します。Python 3.12 がない場合は `uv` が取得します。起動コマンドは `graphify` です。

```bash
~/.local/bin/dot-graphify-install
graphify --help
```

更新する場合は、スクリプトのバージョン指定を変更して再実行してください。バージョンを固定しているため、`uv tool upgrade graphifyy` では更新しません。

Graphify 0.9.90 のローカルクエリログは初期状態で無効です。この dotfiles でも `~/.zshenv` に `GRAPHIFY_QUERY_LOG_DISABLE=1` を設定し、対話・非対話の Zsh で `GRAPHIFY_QUERY_LOG_ENABLE` やログ保存先の指定があっても記録を無効にします。シェルの環境変数を引き継がない MCP クライアントで Graphify を使う場合は、MCP サーバーの環境変数にも `GRAPHIFY_QUERY_LOG_DISABLE=1` を設定してください。この設定は API 呼び出しなどのネットワーク通信を無効にするものではありません。

コードのみの解析には API キーは不要です。解析対象のリポジトリで次のコマンドを実行します。グラフの出力は各リポジトリの `graphify-out/` に保存します。

```bash
graphify extract . --code-only
graphify cluster-only . --no-label
graphify query "authentication flow"
graphify update .
```

Codex のスキル連携が必要なリポジトリでは、次のコマンドを追加で実行します。

```bash
graphify install --project --platform codex
```

登録処理はリポジトリ内のスキル・指示ファイルやフックを変更します。変更内容を確認してからコミットしてください。CLI の導入スクリプトはスキル登録やグラフ生成を実行しません。他のエージェントとの連携は [Graphify の連携ガイド](https://docs.graphify.com/integrations/overview) を参照してください。

### Vite+

Devbox の `github:ryoppippi/nix-vite-plus#vp` が standalone の `vp` を導入します。npm のプロジェクト用 `vite-plus` パッケージは global CLI と別のものです。

初回起動では Vite+ がユーザー環境を初期化します。この dotfiles の Zsh では `VP_SELF_SETUP_NO_MODIFY_PATH=1` でシェル設定の自動書き換えを止め、PATH は Devbox で管理します。Devbox の Node.js とパッケージマネージャーを優先するには、次の環境変数を付けて初回起動してください。

```bash
VP_NODE_MANAGER=no VP_PM_MANAGER=no vp --help
devbox global update
```

## 設定ファイル

| ファイル | 内容 |
| --- | --- |
| `dot_zshenv` | Graphify のクエリログ、Vite+ のシェル設定書き換えを無効化 |
| `dot_zshrc` | Zsh の初期化、Devbox の PATH、補完、プロンプト |
| `dot_config/zsh/exports.zsh.tmpl` | `EDITOR=hx`、XDG、npm global の PATH、Linux の Fcitx5 |
| `dot_config/zsh/aliases.zsh` | eza、bat、Git、chezmoi のエイリアス |
| `dot_config/zsh/functions.zsh` | fzf のファイル選択などの関数 |
| `dot_config/zsh/credentials.local.zsh.tmpl` | Git MAIN/SUB の認証情報 |
| `dot_config/zsh/git-account-auto.zsh` | リポジトリごとのアカウント判定 |
| `dot_config/zsh/git-account-switch.zsh` | Git・GitHub アカウント切り替え |
| `dot_config/zsh/gh-onboard.zsh` | GitHub 認証の初期設定 |
| `dot_p10k.zsh` | Powerlevel10k のプロンプト |
| `dot_config/helix/config.toml` | Helix のテーマ、行番号、自動保存 |
| `dot_config/ghostty/config` | Ghostty の設定 |
| `private_dot_ssh/config.tmpl` | GitHub 向け SSH 設定 |
| `.chezmoiremove` | 移行時に削除する旧設定ファイルの一覧 |

superfile と herdr は既定設定を使います。Nix 版の実行名は `superfile` のため、`spf` ラッパーから起動します。ファイル編集には既存の `EDITOR=hx` を使います。

対話的な Bash は Zsh へ委譲します。非対話的な Bash は通常どおり動作します。補完、プロンプト、Devbox、direnv、zoxide の初期化は Zsh にまとめています。

## よく使うコマンド

```bash
chezmoi update
chezmoi diff
chezmoi apply
chezmoi edit ~/.zshrc

herdr
spf
fe                      # fzf でファイルを選び、EDITOR（hx）で開く
mkcd <dir>
fco
git-account-switch main
git-account-bind main
git-account-auto
dot-gh-onboard
killport 3000
extract <file>
```

## コミット前の検査

Secretlint はリポジトリ内の開発依存です。`prek` から実行します。

```bash
bun install --cwd tools/secretlint
prek install
prek run --all-files
```

## ドキュメント

- [Git・GitHub の認証情報設定](docs/CREDENTIALS_SETUP.md)
- [SSH の設定](docs/CREDENTIALS_SSH_SETUP.md)
- [キーバインド](docs/KEYBINDINGS.md)
- [herdr の使い方](https://herdr.dev/docs/)
- [superfile のキーバインド](https://superfile.dev/list/hotkeys-list/)
- [Vite+ のセットアップ](https://viteplus.dev/guide/)
- [Wrangler のドキュメント](https://developers.cloudflare.com/workers/wrangler/)
- [Hono CLI のドキュメント](https://hono.dev/docs/agents/cli)
- [ast-grep のクイックスタート](https://ast-grep.github.io/guide/quick-start.html)
- [Graphify の導入方法](https://docs.graphify.com/installation)

## ライセンス

MIT
