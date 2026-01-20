# GNOME Configuration

GNOME デスクトップ環境の設定ファイル（Linux のみ）

## 含まれる設定

### 拡張機能

- dash-to-dock (ドック)
- gTile (ウィンドウタイリング)
- user-themes (テーマカスタマイズ)
- blur-my-shell (背景ぼかし)
- pip-on-top (ピクチャーインピクチャー)
- space-bar (ワークスペースバー)
- system-monitor (システムモニター)

### 外観

- ダークモード (prefer-dark)
- アクセントカラー: teal
- 壁紙: interstellar.jpg

### キーボード

- US キーボード + Mozc (日本語入力)

### Dash to Dock

- 位置: 下部
- アイコンサイズ: 32
- 透明度: 0.8
- 動的透明度

### gTile

- グリッド: 3x3

## 適用方法

```bash
# Linux (GNOME) で自動適用
~/.config/gnome/apply-settings.sh

# または手動で
dconf load / < ~/.config/gnome/dconf-settings.ini
```

## エクスポート

現在の設定をエクスポート:

```bash
dconf dump / > ~/.config/gnome/dconf-settings.ini
```

## 必要な拡張機能のインストール

拡張機能は GNOME Extensions サイトまたはパッケージマネージャーでインストール:

- [https://extensions.gnome.org/](https://extensions.gnome.org/)

または:

```bash
# Ubuntu/Debian
sudo apt install gnome-shell-extension-*

# Fedora
sudo dnf install gnome-shell-extension-*
```

## 注意

- macOS では適用されません（Linux のみ）
- chezmoi apply 時に自動的に OS をチェックしてスキップします
