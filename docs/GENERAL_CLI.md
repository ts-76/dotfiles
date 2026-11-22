# 汎用CLIをDevboxで管理する

汎用CLIはDevboxで導入し、設定をchezmoiで配布する。
Node.js、パッケージマネージャー、JavaScript製CLIは引き続きVite Plusで管理する。
Azure CLIとTerraformは不要になったため、導入対象から外す。
認証設定やTerraformのプロジェクトデータは削除しない。

## バージョンを変更する

| CLI | 固定バージョン | 定義 |
| --- | --- | --- |
| direnv | 2.37.1 | `tools.yaml` の `shell-and-terminal.devbox` |
| mo | 1.8.2 | nix/packages/mo.nix |
| Stripe CLI | 1.55.14 | nix/packages/stripe.nix |
| Microsoft APM | 0.37.0 | nix/packages/apm.nix |
| Google Cloud CLI | 594.0.0 | nix/packages/gcloud.nix |

カテゴリ別の定義は [`home/.chezmoidata/tools.yaml`](../home/.chezmoidata/tools.yaml) にある。
独自 Nix 定義は `home/dot_local/share/devbox/global/default/nix/` にある。
独自定義は公式アーカイブのURLとSHA256を固定する。
`nix/flake.lock`でNixpkgsのリビジョンも固定する。
独自flakeの公開対象は、現在検証しているApple SiliconのmacOSのみ。

moはMarkdownビューアのk1LoW/moを使う。
Nixpkgsの同名パッケージは別のツールなので使わない。
APMは同梱Pythonとライブラリを含むディレクトリ構造を維持する。
Google Cloud CLIはNixのPythonを使用し、HomebrewやuvのPythonへ依存しない。
SDKのcore、alpha、bq、gsutil、gcloud-crc32cを維持する。

GhosttyとsbxはHomebrewで管理する。
chezmoiはDevboxの対象外で、dotfilesを適用する前に導入する。

## 変更を適用する

パッケージの追加・更新は `tools.yaml` の対象カテゴリで行う。
`devbox` にはパッケージ名または flake 参照とバージョンを記入する。
`devboxLocal` にはリポジトリ内の flake のパッケージ名と対象プラットフォームを記入する。
`devbox.json.tmpl` は各カテゴリの定義をまとめて `devbox.json` を生成する。
chezmoiは独自Nix定義の内容ハッシュを計算し、各flake参照の`narHash`へ埋め込む。
これにより、Nix定義を変更したときもDevboxが古い導入情報を使い続けない。
参照先は端末のホームを基準に絶対パスで生成するため、作業ディレクトリに依存しない。

`chezmoi apply` は生成した `devbox.json` の内容が変わると Devbox 導入スクリプトを実行する。
スクリプトが実行するコマンドは`devbox global install`。
ローカルNix定義は管理元で編集し、chezmoiで適用する。
適用先のNixファイルを直接編集すると、記録済みのハッシュと一致しなくなるため使わない。
版の更新と管理元の移行は分ける。

Google Cloud CLIの追加コンポーネントやSDKの更新もNix定義で管理する。
`gcloud components install`や`gcloud components update`でNixストアを書き換えない。

## 実ツールで確認する

dotfilesの管理元で次を実行する。

```sh
python3 tools/devbox/verify_general_cli.py
```

4つのCLIのバージョンと、bq、gsutil、alpha、5つのSDKコンポーネントを確認する。
検証用の一時設定を使うため、実際のGoogle Cloud・Stripeの認証情報は使わない。
テスト時のPATHからHomebrewを外し、隠れた依存がないことも確認する。

新端末では、Nix、Devbox、chezmoiの順に初期導入してからdotfilesを適用する。
シェルを再起動し、`command -v mo stripe apm gcloud`でDevboxの実行ファイルが選ばれることを確認する。
