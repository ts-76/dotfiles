# Vite Plusでグローバル開発ツールを管理する

Devboxで汎用CLIとVite Plus本体を導入し、Vite PlusでNode.js、npm、pnpm、BunとJavaScript製CLIを管理する。
設定の管理元はchezmoiとする。
現在のchezmoi管理元は `chezmoi source-path` で確認する。標準パスとは限らない。

## 設定を変更する

- `dot_config/vite-plus/config.json`でNode.jsとパッケージマネージャーの既定バージョンを変更する。
- `dot_config/dev-tools/global-tools.json`でCLIの名前、固定バージョン、実行用Node.jsを変更する。
- どちらも完全なバージョンを指定する。`latest`やバージョン範囲は指定しない。

CLI一覧の例は次のとおり。

```json
{
  "packages": [
    {
      "name": "@openai/codex",
      "version": "0.163.0",
      "node": "24.22.1"
    }
  ]
}
```

`config.json`はVite Plusの設定ファイル。
`global-tools.json`は、このdotfiles専用の導入一覧。
Vite PlusにCLI一覧を自動同期する機能を追加するものではない。

## 端末へ適用する

Nix、Devbox、chezmoiを導入してから`chezmoi apply`を実行する。
Devboxの導入が先に走り、その後でVite Plusの環境とCLIが復元される。

`run_onchange_after_20-devbox.sh.tmpl`はDevbox定義が変わったときに実行する。
`run_onchange_after_30-vite-plus-tools.sh.tmpl`はVite Plus設定、CLI一覧、復元スクリプトが変わったときに実行する。
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

## bdのバージョンを維持する

`bd 1.0.5`はDevboxで公式Nix flakeのコミット`6a3f515ced18406c189c55fff789a4925bfaa35c`を固定して導入する。
npmの`@beads/bd@1.0.5`はGitHubに存在しないバイナリ配布物を参照するため、Vite Plusの一覧には入れない。
このコミットは移行前の実行ファイルのビルドコミットと一致する。
