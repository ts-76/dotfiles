# Vite Plusでグローバル開発ツールを管理する

Devboxで汎用CLIとVite Plus本体を導入し、Vite PlusでNode.js、npm、pnpm、BunとJavaScript製CLIを管理する。
設定の管理元はchezmoiとする。
現在のchezmoi配布元は`chezmoi source-path`で確認する。このリポジトリでは`home/`を使う。

## 設定を変更する

- `home/dot_config/vite-plus/config.json`でNode.jsとパッケージマネージャーの既定バージョンを変更する。
- `tools.yaml` の対象カテゴリの `vitePlus` で CLI の名前、固定バージョン、実行用 Node.js を変更する。 [カテゴリ別の定義](../home/.chezmoidata/tools.yaml)
- Node.jsの既定値は`lts`を指定し、最新LTSを選択する。完全なバージョンへの固定もできる。
- npm・pnpm・BunにはLTSタグがないため、既定値は完全なバージョンで指定する。
- CLI一覧のバージョンと実行用Node.jsは完全なバージョンで指定する。`lts`、`latest`、バージョン範囲は指定しない。

たとえば、Codex は `toolCategories` の下で次のように定義する。

```yaml
  ai:
    vitePlus:
      - name: "@openai/codex"
        version: "0.171.0"
        node: "26.13.1"
```

`config.json`はVite Plusの設定ファイル。
chezmoi は各カテゴリの `vitePlus` をまとめて `~/.config/dev-tools/global-tools.json` を生成する。
`vp-tools` は生成された導入一覧を読み込む。

## 端末へ適用する

Nix、Devbox、chezmoiを導入してから`chezmoi apply`を実行する。
Devboxの導入が先に走り、その後でVite Plusの環境とCLIが復元される。

`home/run_onchange_after_20-devbox.sh.tmpl`は生成したDevbox設定が変わったときに実行する。
`home/run_onchange_after_30-vite-plus-tools.sh.tmpl`はVite Plus設定、CLI一覧、復元スクリプトが変わったときに実行する。
ネットワークエラーが起きたら原因を解消して再実行する。
正常に終了するまで、chezmoiはそのスクリプトの完了を記録しない。

一覧の差分だけ確認する場合は`vp-tools --check`を実行する。
必要な導入を再実行する場合は`vp-tools`を実行する。
既存のCLIが名前、バージョン、Node.jsのバージョンまで一致し、パッケージ定義とコマンドの入口が存在すれば再インストールしない。
ファイルの破損や依存ライブラリの不足は、個別の起動確認で調べる。

一覧から外したCLIは`UNMANAGED`と表示し、残す。
削除する場合は表示された名前を確認して`vp uninstall -g <名前>`を実行する。
`vp-tools --check`は一覧の全CLIが一致すれば0、未導入や版の不一致があれば1、定義が不正なら2で終了する。

## プロジェクトごとのバージョンを維持する

グローバル設定は既定値として使う。
Node.jsの`lts`は固定バージョンではなく、Vite Plusが解決する最新LTSに追従する。
グローバルCLIの実行用Node.jsはCLI一覧の固定バージョンを使う。
プロジェクトにNode.jsやパッケージマネージャーの指定があれば、その指定を優先する。
移行のために既存のlockfileやビルドツールを置き換えない。

非対話のZshでも使えるように、`.zshenv`でVite Plusの環境設定を読み込む。
対話のZshではDevboxを読み込んだ後に再度読み込み、Vite Plusを優先する。
生成済みのshim、環境設定スクリプト、ランタイム、キャッシュはchezmoiに保存しない。
`vp env setup --refresh`で端末ごとに生成する。
`vp`本体をDevboxで更新したら`vp-tools`を実行し、shimの参照先も更新する。

## 動作を確認する

```sh
vp-tools --check
vp env doctor
vp env which node
node --version
pnpm --version
bun --version
vp list -g
codex --version
claude --version
```

ホームと対象プロジェクトの両方で確認する。
IDEやCodexの既存プロセスは以前のPATHを保持するため、切替後に再起動する。

## 復元処理を検証する

dotfilesの管理元で`python3 tools/vite-plus/test_reconcile.py`を実行する。
テストは一時ディレクトリと代替CLIで、再実行、版変更、失敗、不正な定義、一覧外ツールの保持を検証する。
実ツールの導入と起動確認は、別途実行する。

公式仕様は[環境管理](https://viteplus.dev/guide/env)と[グローバルパッケージ管理](https://viteplus.dev/guide/package-management)を参照する。

## bdを導入する

`bd 1.3.4` は Devbox から Nixpkgs の `beads` を使って導入する。
`tools.yaml` の `git` カテゴリでパッケージのバージョンを固定する。Apple Silicon 版は Devbox のパッケージ索引で解決し、Nix の公式バイナリキャッシュから取得する。

## 起動リンクが切れた場合

Nixの旧ストアを参照するリンクが残ると、パッケージ本体が存在していても起動できない。
`vp-tools`はshimを生成した後、旧Nixストアへのリンク切れを修復する。
`vp`の入口はDevboxのプロファイルを参照させ、本体の管理をDevboxに揃える。
`vp upgrade`で別の本体を導入せず、更新は`devbox global update`、続いて`vp-tools`を実行する。

CLIを個別に更新した場合は、`vp list -g --json`でバージョンと`platform.node`を確認し、
`tools.yaml` の該当カテゴリにも反映する。適用した一覧が古いまま `vp-tools` を実行すると一覧の版へ戻る。

## npmの旧グローバル環境

旧`~/.local/share/npm`は2026-11-13に保管領域へ移動した。
`agent-browser 0.43.0`を含むグローバルCLIはVite+で管理する。
`.npmrc`の旧prefix指定は削除済み。グローバルCLIの導入には`vp install -g`を使い、導入後は台帳にも反映する。
