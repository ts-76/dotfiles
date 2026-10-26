# dotfiles

macOS、Linux、WSL2 向けの CLI・開発環境設定です。chezmoi で設定ファイルを配置し、Devbox と Vite Plus でツールを管理します。Graphify は Devbox の `uv` で導入します。

## リポジトリの構成

```text
.
├── .chezmoiroot     # chezmoiの配布元をhome/に指定
├── home/            # ホームへ配置する設定と導入スクリプト
├── docs/            # 運用手順
└── tools/           # 検証とリポジトリ用ツール
```

chezmoi形式の`dot_`などの名前は`home/`内にまとめています。
ホームへ配置されるファイル名と場所は変わりません。
`chezmoi source-path`は`home/`、`chezmoi git`はリポジトリ全体を扱います。

## セットアップ

Git、chezmoi、Nix、Devbox、Zsh を先にインストールしてください。

```bash
chezmoi init --apply https://github.com/ts-76/dotfiles.git
~/.local/bin/dot-graphify-install
exec zsh
```

`chezmoi apply` は設定ファイルを配置し、変更された定義に応じてDevboxとVite Plusの導入処理を実行します。Graphifyは上記の専用スクリプトで導入してください。

Vite+ のグローバル CLI `vp` は、[nix-vite-plus](https://github.com/ryoppippi/nix-vite-plus) の Nix flake を Devbox から導入します。現在の flake は Apple Silicon の macOS、x86_64 と aarch64 の Linux に対応しています。WSL2 は Linux として扱います。更新には `devbox global update` を使います。

Node.js、npm、pnpm、BunとJavaScript製CLIはVite Plusで管理します。[設定・復元手順](docs/VITE_PLUS.md)を参照してください。

認証情報の初期設定では名前、メールアドレス、Git MAIN/SUB の情報を入力します。GitHub のユーザー名は Git の表示名とは別に任意で入力します。

```bash
devbox global list
vp-tools --check
vp list -g
vp --version
wrangler --version
hono --help
ast-grep --version
graphify --help
command -v node bun pnpm vp spf herdr
```

## 既存環境を移行する

既存のBun/npmの導入先は、Vite Plus側の導入と起動確認が済むまで残してください。
今回の移行では、Vite Plusの導入後にDevboxの重複ランタイムを整理し、最後にシェルのPATHを切り替えています。
新しいターミナルで`vp-tools --check`と各CLIの起動を確認してください。

`home/.chezmoiremove` は、以前管理していた Zellij、Yazi、OpenCode、lazygit、Starship の設定ファイル、Helix の Yazi picker を削除します。対象は列挙したファイルだけです。認証情報やセッションデータ、親ディレクトリは削除しません。

ターミナル管理は `herdr`、ファイル管理は `spf` を起動してください。Helix からのファイル選択は標準の `Space f` を使います。

## ツールの管理元

### Devbox

定義は [`home/dot_local/share/devbox/global/default/devbox.json.tmpl`](home/dot_local/share/devbox/global/default/devbox.json.tmpl) にあります。適用先は `~/.local/share/devbox/global/default/devbox.json` です。

| 用途 | パッケージ |
| --- | --- |
| Pythonツールの導入 | `uv` |
| Web 開発 | `vite-plus`（起動コマンドは `vp`） |
| Git・ホスティング | `gh`、`glab`、`ghq` |
| 設定管理 | `chezmoi 2.69.3` |
| CLI出力の圧縮 | `rtk 0.43.0` |
| Markdown閲覧 | `mo 1.6.7`。k1LoW版の公式配布物 |
| クラウド・サービス | `gcloud 559.0.0`、`stripe 1.40.9` |
| エージェント資材管理 | `apm 0.16.1` |
| エディタ・ファイル管理 | `helix`、`superfile`（起動コマンドは `spf`） |
| 検索・移動 | `ripgrep`、`fd`、`fzf`、`zoxide` |
| コードの構文検索・書き換え | `ast-grep` |
| シェル・環境 | `zsh-powerlevel10k`、`direnv` |
| ファイル表示 | `eza`、`bat` |
| ターミナル管理 | `herdr` |
| データ処理 | `jq`、`yq`、`xq` |
| 認証 | `_1password-cli`（`op`） |
| コミット検査 | `prek` |
| AI 開発支援 | `takt` |
| Web 取得 | `ax` |
| Issue管理 | `bd 1.0.5`。公式Nix flakeのコミットを固定 |

`herdr`、`takt`、`ax`、`vite-plus` は GitHub の Nix flake を参照します。`direnv`、`rtk`、`chezmoi`、`terminal-notifier`は固定バージョンを指定し、その他の通常パッケージは`latest`を指定しています。Devbox の lockfile はローカル生成で、このリポジトリには含めません。

汎用CLIの版固定、独自Nix定義、確認手順は[汎用CLIの運用手順](docs/GENERAL_CLI.md)を参照してください。
Azure CLIとTerraformは導入対象から外しています。

```bash
devbox global install
devbox global update
```

### Vite Plusのグローバル環境

環境の既定値は[`home/dot_config/vite-plus/config.json`](home/dot_config/vite-plus/config.json)にあります。
CLI一覧は[`home/dot_config/dev-tools/global-tools.json`](home/dot_config/dev-tools/global-tools.json)にあります。
Node.jsの既定値は`lts`を指定します。npm・pnpm・BunはLTSタグがないため固定バージョンを使います。
CLI一覧では各CLIの名前、固定バージョン、実行用Node.jsを指定します。

```bash
vp-tools --check
vp-tools
vp list -g
```

一覧にないツールは表示だけ行い、自動削除しません。
導入済みCLIの版とNode.jsが一致し、パッケージ定義とコマンドの入口が存在する場合は再インストールしません。
一覧の変更方法と端末の復元は[運用手順](docs/VITE_PLUS.md)を参照してください。

### Graphify

[`home/dot_local/bin/executable_dot-graphify-install`](home/dot_local/bin/executable_dot-graphify-install) を `~/.local/bin/dot-graphify-install` として配置します。このスクリプトは `uv tool` で公式パッケージ `graphifyy==0.9.90` を Python 3.12 の環境に導入します。Python 3.12 がない場合は `uv` が取得します。起動コマンドは `graphify` です。

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

Vite Plusが生成する環境設定をDevboxの初期化後に読み込みます。
`VP_SELF_SETUP_NO_MODIFY_PATH=1`でシェル設定の自動書き換えを止め、読み込み位置をchezmoiで管理します。
Node.jsとパッケージマネージャーはVite Plusのmanaged modeで選択します。
Devboxで`vp`本体を更新した場合は`vp-tools`を実行し、shimを更新してください。

## 設定ファイル

| ファイル | 内容 |
| --- | --- |
| `home/dot_zshenv` | Graphifyのログ設定、Vite Plusの環境初期化、自動設定書き換えの無効化 |
| `home/dot_zshrc` | Zsh の初期化、Devbox の PATH、補完、プロンプト |
| `home/dot_config/zsh/exports.zsh.tmpl` | `EDITOR=hx`、XDG、PATH、Linux の Fcitx5 |
| `home/dot_config/zsh/aliases.zsh` | eza、bat、Git、chezmoi のエイリアス |
| `home/dot_config/zsh/functions.zsh` | fzf のファイル選択などの関数 |
| `home/dot_config/zsh/credentials.local.zsh.tmpl` | Git MAIN/SUB の認証情報 |
| `home/dot_config/zsh/git-account-auto.zsh` | リポジトリごとのアカウント判定 |
| `home/dot_config/zsh/git-account-switch.zsh` | Git・GitHub アカウント切り替え |
| `home/dot_config/zsh/gh-onboard.zsh` | GitHub 認証の初期設定 |
| `home/dot_p10k.zsh` | Powerlevel10k のプロンプト |
| `home/dot_config/helix/config.toml` | Helix のテーマ、行番号、自動保存 |
| `home/dot_config/ghostty/config` | Ghostty の設定 |
| `home/private_dot_ssh/config.tmpl` | GitHub 向け SSH 設定 |
| `home/.chezmoiremove` | 移行時に削除する旧設定ファイルの一覧 |

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
