# キーバインド

Zellij / Yazi / Helix の連携や追加キーバインドをまとめています。

## 目次

- [Zellij](#zellij)
- [Yazi](#yazi)
- [Helix](#helix)

## Zellij

- 既定レイアウト: `startup`
- 追加レイアウト: `agent`
  - 左: Yazi (Editor)
  - 右上: Implement
  - 右下: Review

## Yazi

### 追加キーバインド

- `g i` : lazygit を現在のディレクトリで起動
- `d d` : 選択中のファイルをゴミ箱へ移動

### Zellij 連携

- `z r` : 右スプリットに開く
  - ディレクトリ: bash を起動
  - ファイル: helix で開く
- `z d` : 下スプリットに開く
  - ディレクトリ: bash を起動
  - ファイル: helix で開く
- `z c` : 右スプリットに Open Code で開く
  - ファイルの場合は helix で開く
- `z a` : `agent` レイアウトの新規タブで開く

## Helix

### 追加キーバインド

- `Ctrl+y` : Zellij のフローティングペインで Yazi を開き、選択したパスを Helix で開く
  - スクリプト: `~/.config/helix/yazi-picker.sh`
