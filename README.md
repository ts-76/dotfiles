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

`chezmoi apply` は設定ファイルを配置し、変更された定義に応じてDevboxとVite Plusの導入処理を実行します。Cursor CLIとT3 Code CLIの導入も扱います。Graphifyは上記の専用スクリプトで導入してください。

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
command -v node bun pnpm vp spf
```

## グローバルのエージェントスキル

GitHub から導入するスキルは APM で管理します。chezmoi が APM の設定とロックファイルをホームに配置します。新しい端末への復元、既存環境からの移行、更新は [グローバルスキルの運用手順](docs/AGENT_SKILLS.md) を参照してください。

## 既存環境を移行する

既存のBun/npmの導入先は、Vite Plus側の導入と起動確認が済むまで残してください。
今回の移行では、Vite Plusの導入後にDevboxの重複ランタイムを整理し、最後にシェルのPATHを切り替えています。
新しいターミナルで`vp-tools --check`と各CLIの起動を確認してください。

`home/.chezmoiremove` は、以前管理していた Zellij、Yazi、OpenCode、lazygit、Starship の設定ファイル、Helix の Yazi picker を削除します。対象は列挙したファイルだけです。認証情報やセッションデータ、親ディレクトリは削除しません。

ファイル管理には `spf` を使います。Helix からのファイル選択は標準の `Space f` を使います。

## カテゴリ別のツール管理

CLI の追加・更新は `tools.yaml` の用途別カテゴリで行います。Devbox のパッケージ名や外部 flake 参照は `devbox`、リポジトリ内の Nix flake は `devboxLocal`、Vite Plus で導入する npm パッケージは `vitePlus` に記入します。 [カテゴリ別の定義](home/.chezmoidata/tools.yaml)

| カテゴリ | 主なツール | 専用の導入手順・設定 |
| --- | --- | --- |
| AI・エージェント開発 (`ai`) | Claude Code、Codex、MastraCode、APM | [Cursor CLI](#cursor-cli)、[T3 Code CLI](#t3-code-cli)、[Graphify](#graphify) |
| ブラウザ操作・Web 取得 (`browser`) | agent-browser、ax | |
| クラウド・外部サービス (`cloud`) | Google Cloud CLI、Stripe CLI、Wrangler、cf | |
| データ処理 (`data`) | jq、yq、xq | |
| 開発環境・ランタイム (`development`) | Vite Plus、uv、Hono CLI、Dev Containers CLI、Portless | [Node.js・npm・pnpm・Bun の既定値](docs/VITE_PLUS.md#設定を変更する) |
| エディタ・ファイル・検索 (`editor-and-files`) | Helix、superfile、mo、ripgrep、ast-grep、fd、fzf、eza、bat | [キーバインド](docs/KEYBINDINGS.md) |
| Git・課題管理 (`git`) | gh、glab、ghq、prek、bd | [Git・GitHub の設定](docs/CREDENTIALS_SETUP.md)、[SSH の設定](docs/CREDENTIALS_SSH_SETUP.md) |
| 認証 (`security`) | 1Password CLI (`op`) | |
| シェル・ターミナル (`shell-and-terminal`) | direnv、zoxide、Powerlevel10k | [Zsh・Bash・Ghostty の設定](#設定ファイル) |

### Devbox

chezmoi は各カテゴリの `devbox` と `devboxLocal` をまとめ、`~/.local/share/devbox/global/default/devbox.json` に配置します。Devbox の lockfile はローカルで生成します。

汎用CLIの版固定、独自Nix定義、確認手順は[汎用CLIの運用手順](docs/GENERAL_CLI.md)を参照してください。
Azure CLIとTerraformは導入対象から外しています。

```bash
devbox global install
devbox global update
```

### Vite Plusのグローバル環境

環境の既定値は[`home/dot_config/vite-plus/config.json`](home/dot_config/vite-plus/config.json)にあります。
chezmoi は各カテゴリの `vitePlus` をまとめ、`~/.config/dev-tools/global-tools.json` に配置します。
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

### Cursor CLI

`chezmoi apply` 時に `~/.local/bin/cursor-agent` がなければ、[公式インストーラー](https://cursor.com/install)で最新版を導入します。起動コマンドは `agent`（または `cursor-agent`）です。`~/.local/bin` は既存のPATH設定に含まれています。

更新・再インストールは、dotfilesで配置する専用コマンドを実行してください。バージョンは固定せず、実行時の公式最新版を取得します。

```bash
~/.local/bin/dot-cursor-install
cursor-agent --version
agent
```

インストーラーはダウンロード完了後に実行します。認証情報はdotfilesの管理対象に含めません。

### T3 Code CLI

初回の `chezmoi apply` と導入スクリプトを変更したときに、Apple Silicon Mac と x86_64・ARM64 の Linux（WSL2 を含む）へ `t3` を導入します。[導入スクリプト](home/dot_local/bin/executable_dot-t3-install)で公式リリースの版を固定し、同じ版が入っていればそのまま使います。再導入は `~/.local/bin/dot-t3-install` で行えます。

```bash
t3 --version
t3 connect status
```

同じ端末でデスクトップ版を開いている場合は、`t3 app` で現在のディレクトリを T3 Code で開けます。別の端末から接続するには、デスクトップ版の **Settings → Sharing & access** で T3 Connect にサインインします。CLI をバックグラウンドサービスとして使う場合は、ホストで `t3 connect` を実行します。認証と接続設定は端末ごとに T3 Code が保持します。 [公式の導入手順](https://github.com/pingdotgg/t3code/blob/v0.1.11/docs/user/install.md) · [T3 Connect の設定](https://github.com/pingdotgg/t3code/blob/v0.1.11/docs/user/remote-access.md)

この dotfiles は、シェルの初期化ファイルとバックグラウンドサービスの `~/.t3/service.env` にテレメトリーの無効化を設定します。デスクトップ版とサーバーでは、`T3CODE_TELEMETRY_ENABLED=false` で利用データと T3 Connect の接続トレースの送信を、`T3CODE_OTEL_SDK_DISABLED=true` で OpenTelemetry の診断データの送信を停止します。 [テレメトリーの公式資料](https://github.com/pingdotgg/t3code/blob/v0.1.11/docs/user/telemetry.md) · [OpenTelemetry の無効化](https://github.com/pingdotgg/t3code/blob/v0.1.11/docs/operations/observability.md#the-kill-switch)

chezmoi で反映したあと、デスクトップ版は終了して開き直し、バックグラウンドサービスは `t3 service restart` で再起動してください。 [サービスの環境変数](https://github.com/pingdotgg/t3code/blob/v0.1.11/docs/user/background-service.md#configure-the-service-environment)

Zsh と Bash では `T3CODE_NO_BROWSER=true` を設定し、`t3` の起動時に Web 版が自動で開くのを止めます。設定は chezmoi で反映したあとの新しいシェルで有効になります。 [CLI の設定](https://github.com/pingdotgg/t3code/blob/v0.1.11/apps/server/src/cli/config.test.ts#L411-L485)

### Graphify

[`home/dot_local/bin/executable_dot-graphify-install`](home/dot_local/bin/executable_dot-graphify-install) を `~/.local/bin/dot-graphify-install` として配置します。このスクリプトは `uv tool` で公式パッケージ `graphifyy==0.9.114` を Python 3.12 の環境に導入します。Python 3.12 がない場合は `uv` が取得します。起動コマンドは `graphify` です。

```bash
~/.local/bin/dot-graphify-install
graphify --help
```

更新する場合は、スクリプトのバージョン指定を変更して再実行してください。バージョンを固定しているため、`uv tool upgrade graphifyy` では更新しません。

Graphify 0.9.114 のローカルクエリログは初期状態で無効です。この dotfiles でも `~/.zshenv` に `GRAPHIFY_QUERY_LOG_DISABLE=1` を設定し、対話・非対話の Zsh で `GRAPHIFY_QUERY_LOG_ENABLE` やログ保存先の指定があっても記録を無効にします。シェルの環境変数を引き継がない MCP クライアントで Graphify を使う場合は、MCP サーバーの環境変数にも `GRAPHIFY_QUERY_LOG_DISABLE=1` を設定してください。この設定は API 呼び出しなどのネットワーク通信を無効にするものではありません。

#### コードと文書を解析する

Codex で解析するリポジトリのルートで、Graphify スキルを登録します。

```bash
graphify install --project --platform codex
```

登録処理はリポジトリ内のスキル・指示ファイルやフックを変更します。変更内容を確認してからコミットしてください。

対象リポジトリを Codex で開き、次の入力でコードと README、設計書などの文書からグラフを作成します。

```text
$graphify .
```

文書の内容は意味解析のために Codex が使用しているモデルへ渡ります。グラフはリポジトリの `graphify-out/` に保存されます。変更を反映するときは Codex で `$graphify . --update` を実行します。 [Graphify 0.9.114 のドキュメント](https://pypi.org/project/graphifyy/0.9.114/)

ターミナルからグラフを検索することもできます。

```bash
graphify query "authentication flow"
```

ターミナルからグラフを作る場合は、文書の意味解析用のバックエンドを準備し、`graphify extract .` の `--backend` で指定します。 [Graphify のバックエンド設定](https://docs.graphify.com/open-source/configuration/llm-providers)・[エージェントとの連携](https://docs.graphify.com/integrations/overview)

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

superfile は既定設定を使います。Nix 版の実行名は `superfile` のため、`spf` ラッパーから起動します。ファイル編集には既存の `EDITOR=hx` を使います。

対話的な Bash は Zsh へ委譲します。非対話的な Bash は通常どおり動作します。補完、プロンプト、Devbox、direnv、zoxide の初期化は Zsh にまとめています。

## よく使うコマンド

```bash
chezmoi update
chezmoi diff
chezmoi apply
chezmoi edit ~/.zshrc

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
- [superfile のキーバインド](https://superfile.dev/list/hotkeys-list/)
- [Vite+ のセットアップ](https://viteplus.dev/guide/)
- [Wrangler のドキュメント](https://developers.cloudflare.com/workers/wrangler/)
- [Hono CLI のドキュメント](https://hono.dev/docs/agents/cli)
- [ast-grep のクイックスタート](https://ast-grep.github.io/guide/quick-start.html)
- [Graphify の導入方法](https://docs.graphify.com/installation)

## ライセンス

MIT
