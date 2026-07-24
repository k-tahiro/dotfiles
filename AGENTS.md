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

- `claude.json` — Claude Code権限設定
- `mcp.toml` — MCPサーバー設定（`shared` / `work` / `private`別）
- `winget.toml` — Windows Packageマネージャー設定

> Homebrew パッケージ定義は `.chezmoidata/homebrew.toml` から `dot_config/mise/config.toml.tmpl` の `[bootstrap.packages]` セクション（`brew:` / `brew-cask:` バックエンド）に統合済み。Single Source of Truth は mise。

テンプレート内では `.chezmoi.os`、`.chezmoi.hostname` 等の組み込み変数に加え、`.chezmoidata` 以下のカスタム変数が使える。`chezmoi data` で現在の変数値を確認できる。

### ツール管理の責務分担

CLIツールとランタイムのインストール先は以下のルールで使い分ける：

- **mise**（`dot_config/mise/config.toml.tmpl`）— ツール管理の **Single Source of Truth**。`[tools]` セクションに CLI ツール（bat, ripgrep, gh, jq, lazygit, uv, terraform 等）と言語/ランタイム（node, bun, lts）を、`[bootstrap.packages]` セクションにバックエンド指定付きのパッケージ（`apt:` / `brew:` / `brew-cask:` / `aqua:`）を集約する。GitHub API 依存が強いものは `aqua:` バックエンドを明示する
- **Homebrew** — パッケージ管理の責務は mise に統一済み。Homebrew 自体は mise の `brew:` / `brew-cask:` バックエンドのランタイム依存としてのみ動作する。Homebrew 自体の導入は `run_once_before_01_brew_install.sh.tmpl`、mise 本体の導入は `run_once_before_02_mise_install.sh.tmpl`（公式インストーラ）で行う

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

### スクリプトの追加ルール

ファイル名は以下のパターンに従う：

```
run_<timing>[_<position>]_<NN>_<tool>[_<descriptor>]_<action>.sh[.tmpl]
```

| 要素 | 値 |
|---|---|
| `timing` | `once` / `onchange` / (空) |
| `position` | `before` / `after` / (空) |
| `NN` | 2桁数字。タイミングクラスをまたいで**パイプライン全体**の実行順に連番 |
| `tool` | 操作対象（`brew`, `mise`, `zsh`, `herdr` 等） |
| `descriptor` | 任意（`bundle` 等） |
| `action` | **必ず動詞**（`install` / `apply` / `upgrade` / `check` / `set_default` 等） |

**追加時の必須チェック**：

1. **ベース名の一意性** — chezmoi は `run_<timing>[_<position>]_` を除いた残り（`<NN>_<tool>..._<action>`）でスクリプトを識別する。**同じベース名が複数存在すると `inconsistent state` エラーで `chezmoi diff` が失敗する**。特に同じ `tool` を複数タイミングで扱う場合は `action` で必ず区別する（例：`02_mise_install`（バイナリ導入）と `04_mise_apply`（config 適用））。
2. **番号はパイプライン全体**で振る — `run_once_before_*` の最大値より大きい数字を次の `run_onchange_after_*` に振る、という流れ。
3. **アクション動詞の明示** — 末尾に必ず動詞を付ける。`01_brew` のような動詞なしの名前は禁止。
4. **冪等性** — `run_once_*` はリネーム・状態リセット・chezmoi バージョンアップ等で再実行され得る。冒頭に `command -v <tool> &> /dev/null` 等のガードを入れ、既存環境では `exit 0` で no-op にする。
5. **追加前の検証** — 新規 / リネーム後は必ず `chezmoi execute-template < <file.tmpl>` でレンダリング確認し、`chezmoi diff` で `inconsistent state` が出ていないことを確認する。
6. **履歴保持** — リネームは `git mv` で行い、ファイル削除→新規作成にすると履歴が切れる。

### Git自動コミット

`.chezmoi.toml.tmpl` で `autoCommit = true` と `autoPush = true` が設定されているため、`chezmoi apply` 実行時にソースディレクトリへの変更が自動コミット・プッシュされる。

## 主要ファイル

| ファイル | 用途 |
|---|---|
| `.chezmoi.toml.tmpl` | chezmoi本体設定・環境変数プロンプト |
| `.chezmoiignore.tmpl` | OS/環境別の無視ファイル設定 |
| `dot_config/zsh/dot_zshrc.tmpl` | Zsh設定（エイリアス・関数・プラグイン） |
| `dot_config/mise/config.toml.tmpl` | ツール管理の Single Source of Truth。CLIツール・言語/ランタイム・`brew:` / `brew-cask:` 経由のパッケージ集約（bat, ripgrep, gh, node, uv, arc, raycast, ghostty 等） |
| `dot_gitconfig.tmpl` | Git設定 |
| `dot_claude/modify_settings.json` | Claude Code権限設定 |
