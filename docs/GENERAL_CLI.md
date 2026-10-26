# 汎用CLIをDevboxで管理する

汎用CLIはDevboxで導入し、設定をchezmoiで配布する。
Node.js、パッケージマネージャー、JavaScript製CLIは引き続きVite Plusで管理する。
Azure CLIとTerraformは不要になったため、導入対象から外す。
認証設定やTerraformのプロジェクトデータは削除しない。

## バージョンを変更する

| CLI | 固定バージョン | 定義 |
| --- | --- | --- |
| rtk | 0.43.0 | devbox.jsonの標準パッケージ |
| chezmoi | 2.69.3 | devbox.jsonの標準パッケージ |
| terminal-notifier | 2.0.0 | devbox.jsonの標準パッケージ |
| mo | 1.6.7 | nix/packages/mo.nix |
| Stripe CLI | 1.40.9 | nix/packages/stripe.nix |
| Microsoft APM | 0.16.1 | nix/packages/apm.nix |
| Google Cloud CLI | 559.0.0 | nix/packages/gcloud.nix |

定義は`dot_local/share/devbox/global/default/`にある。
独自定義は公式アーカイブのURLとSHA256を固定する。
`nix/flake.lock`でNixpkgsのリビジョンも固定する。
独自flakeの公開対象は、現在検証しているApple SiliconのmacOSのみ。

moはMarkdownビューアのk1LoW/moを使う。
Nixpkgsの同名パッケージは別のツールなので使わない。
APMは同梱Pythonとライブラリを含むディレクトリ構造を維持する。
Google Cloud CLIはNixのPythonを使用し、HomebrewやuvのPythonへ依存しない。
SDKのcore、alpha、bq、gsutil、gcloud-crc32cを維持する。

macOSの通知CLIであるterminal-notifierもDevboxで管理する。
Homebrew版と同じ2.0.0を使い、通知の動作を確認してからHomebrew版を削除する。
GhosttyとsbxはHomebrewで管理する。

## 変更を適用する

Devbox設定の管理元は`devbox.json.tmpl`、適用先は通常の`devbox.json`。
chezmoiは独自Nix定義の内容ハッシュを計算し、各flake参照の`narHash`へ埋め込む。
これにより、Nix定義を変更したときもDevboxが古い導入情報を使い続けない。
参照先は端末のホームを基準に絶対パスで生成するため、作業ディレクトリに依存しない。

`chezmoi apply`で定義を配置し、変更されたDevbox導入スクリプトを実行する。
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

6つのCLIのバージョンと、bq、gsutil、alpha、5つのSDKコンポーネントを確認する。
検証用の一時設定を使うため、実際のGoogle Cloud・Stripeの認証情報は使わない。
テスト時のPATHからHomebrewを外し、隠れた依存がないことも確認する。

terminal-notifierはこの検証スクリプトの対象外なので、Devbox版を直接指定して確認する。

```sh
"${XDG_DATA_HOME:-$HOME/.local/share}/devbox/global/default/.devbox/nix/profile/default/bin/terminal-notifier" -help
"${XDG_DATA_HOME:-$HOME/.local/share}/devbox/global/default/.devbox/nix/profile/default/bin/terminal-notifier" -title "Devbox" -message "terminal-notifierの動作確認"
```

ヘルプのバージョンが2.0.0であることと、macOSに通知が表示されることを確認する。

新端末では、Nix、Devbox、chezmoiの順に初期導入してからdotfilesを適用する。
シェルを再起動し、`command -v rtk chezmoi mo stripe apm gcloud`でDevboxの実行ファイルが選ばれることを確認する。
