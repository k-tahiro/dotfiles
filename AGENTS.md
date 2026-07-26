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
| 先頭が `{{- /* chezmoi:modify-template */ -}}` | 既存JSONファイルへ patch を当てる |

### テンプレート変数

`.chezmoidata/` 配下のデータファイルと、`.chezmoi.toml.tmpl` で計算される変数を使う。

**`.chezmoidata/` 配下**（chezmoi が自動ロード）：

- `claude.json` — Claude Code の permissions / hooks / env 設定
- `mcp.toml` — MCP サーバー設定（`[mcp.shared]` / `[mcp.work]` / `[mcp.private]`）

**`.chezmoi.toml.tmpl` で計算**:

| 変数 | 意味 |
|---|---|
| `data.isWsl` | WSL 環境か（`.chezmoi.os == "linux"` かつ kernel に `microsoft` を含む） |
| `data.isWork` | `promptBool "Is this a work machine"`（既定: 非 Windows かつ WSL 以外で true） |
| `data.isHeadless` | `promptBool "Is this a headless machine"`（既定: Windows / macOS 以外で true） |
| `data.brewPrefix` | `/opt/homebrew`（macOS）/ `/home/linuxbrew/.linuxbrew`（その他） |
| `data.brewBin` | `${brewPrefix}/bin/brew` |

> OS 判定はテンプレートローカル変数 `$isWindows` / `$isMac` / `$isWsl` / `$isLinux` として存在するが、これらは `[data]` にはエクスポートされない。テンプレートから OS を見るときは `.chezmoi.os` を直接参照する。

> Homebrew パッケージ定義はかつて `.chezmoidata/homebrew.toml` だったが、`dot_config/mise/config.toml.tmpl` の `[bootstrap.packages]`（`brew:` / `brew-cask:` バックエンド）に統合済み。Single Source of Truth は mise。

`chezmoi data` で現在の変数値を確認できる。

### MCP サーバー設定の出し分け

`.chezmoidata/mcp.toml` で `shared` / `work` / `private` の3系統を定義し、以下の `modify_*` テンプレートが `data.isWork` を見て work 系統と private 系統を切り替えて出力先に patch を当てる：

| ソース | 出力先 |
|---|---|
| `modify_private_dot_claude.json`（リポジトリ直下） | `~/.claude.json`（mode 600） |
| `dot_codex/modify_config.toml` | `~/.codex/config.toml` |
| `dot_config/opencode/modify_opencode.json` | `~/.config/opencode.json` |

serena サーバーには `claude-code` / `codex` のサフィックスを動的に付与する。`url` を持つサーバーは `type = "http"` を補完し、`bearer_token_env_var` は `Authorization: Bearer ${...}` ヘッダへ変換する。

### ツール管理の責務分担

**Single Source of Truth は mise**（`dot_config/mise/config.toml.tmpl`）。CLIツール・言語ランタイム・システムパッケージを集約する。

- **`[tools]`** — CLI と言語ランタイム。`bat`, `bottom`, `bun`, `chezmoi`, `direnv`, `eza`, `fd`, `fzf`, `gh`, `ghq`, `herdr`, `jq`, `lazygit`, `neovim`, `node` (lts), `ripgrep`, `rtk`, `starship`, `uv`, `yazi`, `yq`, `zoxide` など。Work 限定: `aws-cli`, `azure-cli`, `claude-code`, `copilot-cli`, `codex`, `crane`, `docker-cli`, `docker-compose`, `terraform` (1.9.7 pin), `aqua:DataDog/pup`, `aqua:docker/buildx`。Private 限定: `opencode`
- **`[bootstrap.packages]`** — バックエンド指定付きのパッケージ
  - `apt:` — Linux（`apt` がある場合）。例: `build-essential`, `zsh-autosuggestions`, `zsh-syntax-highlighting`
  - `brew:` — macOS の CLI パッケージ。例: `gcc`, `git-secret`, `gnupg`（work のみ）
  - `brew-cask:` — macOS の GUI アプリ。例: `arc`, `claude`, `codex-app`, `ghostty`, `karabiner-elements`, `raycast`, `rectangle`, `visual-studio-code`, `zed`, `zen`
  - `aqua:` — GitHub API 依存の強いツール（`DataDog/pup`, `docker/buildx`）

> Homebrew 自体は mise の `brew:` / `brew-cask:` バックエンドのランタイム依存としてのみ動作する。Homebrew を直接インストールするスクリプトは存在しない。

mise 本体の導入は `run_once_before_01_mise_install.sh`（公式インストーラ）。config の反映は `run_onchange_after_02_mise_apply.sh.tmpl`、日次アップグレードは `run_after_03_mise_upgrade.sh` で運用する。

### 環境分岐の仕組み

`.chezmoi.toml.tmpl` で初回セットアップ時にプロンプト入力し、`data.isWork` / `data.isHeadless` を確定する。OS 判定は自動（`$isWindows` / `$isMac` / `$isWsl` / `$isLinux`）。これらは `.chezmoiignore.tmpl` と各テンプレートファイルの条件分岐で使われる。

### スクリプト実行条件

`.chezmoiscripts/` 内のスクリプトはファイル名のプレフィックスで実行タイミングが決まる：

| プレフィックス | 実行タイミング | 現在の使用例 |
|---|---|---|
| `run_once_before_` | `chezmoi apply` の前、初回のみ | `01_mise_install` |
| `run_onchange_after_` | `apply` の後、内容変化時のみ | `02_mise_apply` |
| `run_after_` | `apply` の後、毎回 | `03_mise_upgrade` |

> timing（`_once_` / `_onchange_`）と position（`_before_` / `_after_`）の修飾子は組み合わせて使う。

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

1. **ベース名の一意性** — chezmoi は `run_<timing>[_<position>]_` を除いた残り（`<NN>_<tool>..._<action>`）でスクリプトを識別する。**同じベース名が複数存在すると `inconsistent state` エラーで `chezmoi diff` が失敗する**。特に同じ `tool` を複数タイミングで扱う場合は `action` で必ず区別する（例：`01_mise_install`（バイナリ導入）と `02_mise_apply`（config 適用））。
2. **番号はパイプライン全体**で振る — `run_once_before_*` の最大値より大きい数字を次の `run_onchange_after_*` に振る、という流れ。
3. **アクション動詞の明示** — 末尾に必ず動詞を付ける。`01_brew` のような動詞なしの名前は禁止。
4. **冪等性** — `run_once_*` はリネーム・状態リセット・chezmoi バージョンアップ等で再実行され得る。冒頭に `command -v <tool> &> /dev/null` 等のガードを入れ、既存環境では `exit 0` で no-op にする。
5. **追加前の検証** — 新規 / リネーム後は必ず `chezmoi execute-template < <file.tmpl>` でレンダリング確認し、`chezmoi diff` で `inconsistent state` が出ていないことを確認する。
6. **履歴保持** — リネームは `git mv` で行い、ファイル削除→新規作成にすると履歴が切れる。

### Git自動コミット

`.chezmoi.toml.tmpl` で `git.autoCommit = true` と `git.autoPush = true` が設定されているため、`chezmoi apply` 実行時にソースディレクトリへの変更が自動コミット・プッシュされる。

## 主要ファイル

### リポジトリルート

| ファイル | 用途 |
|---|---|
| `.chezmoi.toml.tmpl` | chezmoi 本体設定・OS 検出・プロンプト・data 変数・auto commit/push |
| `.chezmoiignore.tmpl` | OS / CLI ツール有無で dotfile ソースを除外（always / not-darwin / no-claude / no-codex / no-opencode の5セクション） |
| `.chezmoidata/claude.json` | Claude Code の permissions / hooks / env 設定 |
| `.chezmoidata/mcp.toml` | MCP サーバー設定（shared / work / private） |
| `dot_zshenv` | XDG ディレクトリ・`ZDOTDIR`・PATH・`.zshenv.local` の読み込み |
| `dot_vimrc.tmpl` | 最小 vimrc（`defaults.vim` + fzf runtimepath） |
| `dot_claude/modify_settings.json` | `~/.claude/settings.json` への modify-template（permissions / hooks / env を patch） |
| `dot_codex/modify_config.toml` | Codex の MCP サーバー設定（work/private 切り替え） |
| `modify_private_dot_claude.json` | `~/.claude.json` への modify-template（mode 600） |

### `dot_config/` 配下

| パス | 用途 |
|---|---|
| `dot_config/mise/config.toml.tmpl` | ツール管理の **Single Source of Truth**（`[tools]` / `[bootstrap.packages]`） |
| `dot_config/zsh/dot_zshrc.tmpl` | Zsh 設定（基本設定・fzf・エイリアス・関数・プラグイン・Starship） |
| `dot_config/zsh/dot_zprofile.tmpl` | Zsh profile（`mise activate` / `direnv` / `EDITOR=nvim` / `GITHUB_PAT` / macOS LM Studio PATH） |
| `dot_config/git/config` | Git 設定（user / credential helper / pull.rebase / `prune-branches` alias） |
| `dot_config/ghostty/config.ghostty` | Ghostty ターミナル設定（font-family ほか） |
| `dot_config/private_karabiner/private_karabiner.json` | Karabiner-Elements キーリマップ（macOS のみ、mode 600） |
| `dot_config/starship.toml` | Starship プロンプト（catppuccin テーマ） |
| `dot_config/yazi/yazi.toml` | Yazi ファイルマネージャ レイアウト |
| `dot_config/herdr/config.toml` | herdr（AI ターミナル）設定（catppuccin テーマ、cwd 追従、sound off） |
| `dot_config/opencode/modify_opencode.json` | `~/.config/opencode.json` の MCP 設定 patch |
| `dot_config/opencode/modify_oh-my-opencode-slim.json` | `~/.config/oh-my-opencode-slim.json` の multiplexer レイアウト patch |
