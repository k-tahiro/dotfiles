## このリポジトリについて

[chezmoi](https://www.chezmoi.io/) を使ったdotfiles管理リポジトリ。Windows / macOS / Linux (WSL含む) のマルチOS環境に対応し、Work/Private・GUI有無で設定を切り替える。

## よく使うコマンド

```bash
chezmoi apply          # ホームディレクトリに設定を適用
chezmoi diff           # 適用前の差分を確認
chezmoi status         # 管理ファイルの状態確認
chezmoi add <file>     # ファイルをchezmoi管理下に追加
chezmoi edit <file>    # 管理ファイルを編集（ソースを直接開く）
chezmoi data           # テンプレートで使える変数一覧を表示
chezmoi execute-template < <file.tmpl>  # テンプレートのレンダリング確認
```

## アーキテクチャ

### ファイル命名規則

chezmoi固有のプレフィックス・サフィックスでファイルの役割を定義する：

| ソースファイル | 展開先 |
|---|---|
| `dot_foo` | `~/.foo` |
| `dot_config/bar` | `~/.config/bar` |
| `foo.tmpl` | テンプレートとして処理してから展開 |
| `modify_foo` | 既存ファイルにパッチを適用するスクリプト |
| `private_foo` | パーミッション600で展開 |
| `readonly_foo` | パーミッション444で展開 |

### テンプレート変数

`.chezmoidata/` 配下のTOML/JSONファイルでデータを定義し、テンプレート内で参照する。

- `homebrew.toml` — Homebrewパッケージ（bootstrap/shell/system系 + GUI cask、`shared` / `work` / `private`別）
- `claude.json` — Claude Code権限設定
- `mcp.toml` — MCPサーバー設定（`shared` / `work` / `private`別）
- `winget.toml` — Windows Packageマネージャー設定

テンプレート内では `.chezmoi.os`、`.chezmoi.hostname` 等の組み込み変数に加え、`.chezmoidata` 以下のカスタム変数が使える。`chezmoi data` で現在の変数値を確認できる。

### ツール管理の責務分担

CLIツールとランタイムのインストール先は以下のルールで使い分ける：

- **mise**（`dot_config/mise/config.toml.tmpl`）— CLIツール全般（bat, ripgrep, gh, jq 等）と言語/ランタイム（node, uv, terraform 等）。GitHub API依存が強いものは `aqua:` バックエンドを明示する
- **Homebrew**（`.chezmoidata/homebrew.toml`）— ブートストラップ/シェル/システム系（mise, chezmoi, zsh, gcc, herdr, rtk）と、mise非対応または相互依存の強いもの（gnupg, container stack 等）、GUIアプリ（cask）

### 環境分岐の仕組み

`.chezmoi.toml.tmpl` で初回セットアップ時にプロンプト入力し、以下の変数を確定する：

- `data.work` — Work機かどうか（Work専用ツールの有無）
- `data.headless` — ヘッドレス環境かどうか（WezTerm等GUIツールの有無）
- `data.windows` / `data.macos` / `data.wsl` / `data.linux` — OS種別

これらの変数は `.chezmoiignore.tmpl` と各テンプレートファイルの条件分岐で使われる。

### スクリプト実行条件

`.chezmoiscripts/` 内のスクリプトはファイル名のプレフィックスで実行タイミングが決まる：

| プレフィックス | 実行タイミング |
|---|---|
| `run_once_` | 一度だけ実行（実行済みはスキップ） |
| `run_onchange_` | ファイル内容が変わったときのみ実行 |
| `run_after_` | `chezmoi apply` 後に毎回実行 |
| `_before` / `_after` | `apply` の前後いずれかで実行 |

数字プレフィックス（`01_`, `02_`）は実行順序を制御する。

### Git自動コミット

`.chezmoi.toml.tmpl` で `autoCommit = true` と `autoPush = true` が設定されているため、`chezmoi apply` 実行時にソースディレクトリへの変更が自動コミット・プッシュされる。

## 主要ファイル

| ファイル | 用途 |
|---|---|
| `.chezmoi.toml.tmpl` | chezmoi本体設定・環境変数プロンプト |
| `.chezmoiignore.tmpl` | OS/環境別の無視ファイル設定 |
| `dot_config/zsh/dot_zshrc.tmpl` | Zsh設定（エイリアス・関数・プラグイン） |
| `dot_config/homebrew/Brewfile.tmpl` | Homebrewパッケージ（bootstrap/shell/system系・GUI cask） |
| `dot_config/mise/config.toml.tmpl` | CLIツール + 言語/ランタイムのバージョン管理（bat, ripgrep, gh, node, uv等） |
| `dot_gitconfig.tmpl` | Git設定 |
| `dot_claude/modify_settings.json` | Claude Code権限設定 |
