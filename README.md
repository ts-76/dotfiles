# dotfiles

**Devbox × chezmoi** で構築する、クロスプラットフォーム対応の開発環境設定です。

MacとWindows (WSL2) で**同じコマンド、同じバージョン、同じ設定**を実現します。

---

## 目次

- [特徴](#特徴)
- [前提（ネイティブでインストールしておくもの）](#前提ネイティブでインストールしておくもの)
- [クイックスタート](#クイックスタート)
- [ドキュメント](#ドキュメント)
- [採用ツールと役割](#採用ツールと役割)
- [ディレクトリ構成](#ディレクトリ構成)
- [インストールされるツール](#インストールされるツール)
- [主要ファイルの説明](#主要ファイルの説明)
- [よく使うコマンド](#よく使うコマンド)
- [ライセンス](#ライセンス)
- [参考](#参考)

---

## 特徴

- 🚀 **2段階セットアップ** - 基本環境 → 認証情報設定（HTTPS + gh）で完全運用
- 🔄 **クロスプラットフォーム** - Mac / Linux / WSL2 で同じ環境
- 🐧 **WSL最適化** - `DOT_IS_WSL` を自動判定し、WSLとLinuxで実行時分岐
- 📦 **再現性の保証** - Devbox (Nix) によるバージョン固定
- 🎨 **モダンなツールセット** - starship, eza, bat, fzf など
- 🔧 **モジュール設計** - 機能別に分割された設定ファイル
- 🔐 **認証情報設定** - Git/gh を MAIN/SUB で切り替え可能

---

## 前提（ネイティブでインストールしておくもの）

このリポジトリは「Devboxで管理するツール群を、chezmoiで配置・適用する」構成です。
そのため、以下は事前にOS側のパッケージマネージャ等でインストールしておいてください。

- **git** - リポジトリ取得に使用
- **chezmoi** - dotfiles の適用に使用（`chezmoi init --apply` を実行するために必須）
- **nix** - Devbox のバックエンド（WSL2/Linux/Mac いずれも必要）
- **devbox** - ツールのバージョン管理（`devbox global shellenv` を利用）
- **zsh** - このdotfilesの標準シェル

---

## クイックスタート

### 1) 基本環境のインストール

まず、[前提（ネイティブでインストールしておくもの）](#前提ネイティブでインストールしておくもの) をインストールした上で、dotfilesを適用します：

```bash
# リポジトリから初期化して適用
chezmoi init --apply https://github.com/YOUR_USERNAME/dotfiles.git

# または、既にcloneしている場合
chezmoi init
chezmoi apply
```

この段階で以下がセットアップされます：
- ✅ dotfiles の配置（zsh / starship / helix / yazi / zellij / lazygit / opencode など）
- ✅ Devbox (global) によるツール導入（gh, helix, fzf, `op` など）
- ⚠️ Git認証情報はまだ設定されていません（次の手順で設定）

### 2) 認証情報の設定（任意）

- 認証情報は [`docs/CREDENTIALS_SETUP.md`](./docs/CREDENTIALS_SETUP.md) に集約しています
- 初期化時の質問で `GIT_MAIN_*` / `GIT_SUB_*` を設定し、`~/.config/zsh/credentials.local.zsh` が生成されます（`GITHUB_*_USERNAME` は `GIT_*_NAME` と同値）
- Workspaceフォルダ作成（`~/workspace/personal` / `~/workspace/work`）はスキップ可能です

### 3) 確認

```bash
# インストールされたツールを確認
devbox global list

# Git設定を確認
git config --global user.name
git config --global user.email

# (任意) 認証情報の状態を確認
dot-cred-status
```

---

## ドキュメント

- 認証情報設定（HTTPS運用）: [`docs/CREDENTIALS_SETUP.md`](./docs/CREDENTIALS_SETUP.md)
- SSH運用（必要時のみ）: [`docs/CREDENTIALS_SSH_SETUP.md`](./docs/CREDENTIALS_SSH_SETUP.md)
- キーバインド: [`docs/KEYBINDINGS.md`](./docs/KEYBINDINGS.md)

---

## 採用ツールと役割

| カテゴリ | 採用ツール | 役割・選定理由 |
| --- | --- | --- |
| **管理** | **chezmoi** | dotfilesの配置、テンプレート処理、機密情報管理。Go製で高速。 |
| **ツール** | **Devbox** | Node, Go, Rust, k8s系ツールなどのバージョン管理。`nix` ベースで完全な再現性を保証。 |
| **シェル** | **zsh** | MacとLinux(WSL)の標準シェルとして共通化。 |
| **環境** | **WSL2** | Windows側での実行環境。Devboxを動かすために必須。 |
| **Terminal** | (任意) | Windows Terminal (Win) / iTerm2 or Ghostty (Mac) など、OSネイティブなものを推奨。 |

---

## ディレクトリ構成

```text
~/.local/share/chezmoi/
├── docs/                           # ドキュメント
│   ├── CREDENTIALS_SETUP.md        # 認証情報設定（HTTPS運用）
│   ├── CREDENTIALS_SSH_SETUP.md    # SSH運用手順（必要時のみ）
│   └── KEYBINDINGS.md              # Zellij / Yazi / Helix のキーバインド
├── .chezmoiignore                   # chezmoi 管理対象から除外するパス
├── .chezmoi.yaml.tmpl               # 初回init時にメールなどを聞く設定
│
├── dot_zshrc                        # Zsh の設定 (~/.zshrc)
│
├── dot_bun/                         # bun のグローバル設定
│   └── install/global/package.json  # bun のグローバルパッケージ
│
├── dot_config/                      # ~/.config に展開されるディレクトリ
│   ├── zsh/                         # zshの設定を機能別に分割
│   │   ├── aliases.zsh
│   │   ├── credentials.zsh
│   │   ├── credentials.local.zsh.tmpl
│   │   ├── exports.zsh.tmpl
│   │   ├── functions.zsh
│   │   ├── gh-onboard.zsh
│   │   ├── git-account-auto.zsh
│   │   ├── git-account-switch.zsh
│   │   └── profile.local.zsh.tmpl
│   │
│   ├── starship.toml                # プロンプト設定
│   ├── yazi/                        # TUI ファイルマネージャー設定
│   ├── zellij/                      # ターミナルマルチプレクサ設定
│   ├── ghostty/                     # Ghostty 設定 (任意)
│   └── opencode/                    # opencode 設定
│
├── dot_local/bin/executable_ide     # エディタ起動用の簡易コマンド
├── dot_local/share/devbox/global/default/devbox.json  # Devbox のグローバル定義
└── private_dot_ssh/config.tmpl      # ~/.ssh/config のテンプレート（GitHub SSH）

```

---

## インストールされるツール

すべてのツールは `dot_local/share/devbox/global/default/devbox.json`（適用後は `~/.local/share/devbox/global/default/devbox.json`）で管理されています。

### 開発ツール
- **gh** - GitHub CLI
- **lazygit** - Git TUI
- **delta** - Git diff viewer
- **helix** - テキストエディタ

### 検索・ナビゲーション
- **ripgrep** - 高速grep
- **fd** - 高速find
- **fzf** - ファジーファインダー
- **zoxide** - スマートcd
- **direnv** - `.envrc` の自動読み込み

### シェル体験
- **starship** - クロスシェル対応プロンプト

### ファイル操作
- **eza** - モダンなls
- **bat** - シンタックスハイライト付きcat
- **yazi** - TUIファイルマネージャー

### ターミナル
- **zellij** - ターミナルマルチプレクサ

### ユーティリティ
- **jq** - JSONプロセッサ
- **yq** - YAMLプロセッサ
- **bun** - 高速JavaScriptランタイム

### AI
- **github-copilot-cli** - GitHub Copilot CLI

---

## 主要ファイルの説明

### 設定ファイル
- `dot_zshrc` - Zsh のエントリーポイント
- `dot_config/zsh/exports.zsh.tmpl` - 環境変数（`DOT_IS_WSL` 判定を含む）
- `dot_config/zsh/aliases.zsh` - エイリアス
- `dot_config/zsh/credentials.zsh` - 資格情報（localファイル）
- `dot_config/zsh/credentials.local.zsh.tmpl` - local認証情報ファイルのテンプレート
- `dot_config/zsh/functions.zsh` - カスタム関数
- `dot_config/zsh/gh-onboard.zsh` - MAIN/SUBのgh認証オンボーディング（HTTPS）
- `dot_config/zsh/git-account-auto.zsh` - repo単位でmain/subを自動判定し、direnv連携で適用
- `dot_config/zsh/git-account-switch.zsh` - repo単位でGit/ghアカウント切り替え
- `dot_config/lazygit/config.yml` - lazygit 設定（diff パネルで delta を使用: 行番号/横並び/hyperlinks）
- `dot_bun/install/global/package.json` - bun のグローバルパッケージ
- `dot_local/share/devbox/global/default/devbox.json` - Devbox の導入ツール一覧
- `private_dot_ssh/config.tmpl` - GitHub 向け SSH 設定テンプレ（鍵そのものは含めない）
- `docs/CREDENTIALS_SETUP.md` - 認証情報設定（HTTPS運用）の詳細手順
- `docs/CREDENTIALS_SSH_SETUP.md` - SSH運用が必要な場合の手順
- `docs/KEYBINDINGS.md` - Zellij / Yazi / Helix のキーバインドまとめ

---

## よく使うコマンド

### chezmoi

```bash
chezmoi update          # リポジトリから最新を取得して適用
chezmoi cd             # chezmoiのソースディレクトリに移動
chezmoi diff           # 変更差分を確認
chezmoi apply          # 変更を適用
chezmoi edit ~/.zshrc  # ファイルを編集
```

### pre-commit（ローカル）

`prek` + `secretlint` で、秘密鍵やトークンのコミットを防止できます。

```bash
# secretlint 依存（ルール含む）
bun install --cwd tools/secretlint

# git hook を導入
prek install

# (任意) 全ファイルをチェック
prek run --all-files
```

### カスタム関数

```bash
mkcd <dir>     # ディレクトリ作成 & 移動
fe             # fzfでファイルを選択してnvimで開く
fco            # fzfでGitブランチを選択してcheckout
git-account-switch main  # repoローカルのgit user + ghアカウント切り替え
git-account-bind main    # repoをmainに固定 + .envrc生成
git-account-auto            # repo設定から自動判定して適用
dot-gh-onboard           # MAIN/SUBのghログイン確認とsetup-git
killport 3000  # ポート3000を使用しているプロセスをkill
extract <file> # 様々な形式のアーカイブを自動展開
```

---

## ライセンス

MIT

---

## 参考

- [chezmoi](https://www.chezmoi.io/)
- [Devbox](https://www.jetpack.io/devbox/)
- [Starship](https://starship.rs/)
