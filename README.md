# dotfiles

Personal dotfiles managed with [Chezmoi](https://www.chezmoi.io/) for cross-platform development environment configuration.

## ✨ Features

- 🔄 **Cross-platform support**: Windows (WSL), macOS, Linux
- 🎯 **Environment-aware**: Separate configurations for work and personal setups
- 📦 **Automated package management**: Homebrew and Mise integration
- 🚀 **Modern CLI tools**: Pre-configured with modern replacements for traditional Unix tools
- 🎨 **Customized shell**: Zsh with Starship prompt, Zellij multiplexer, and quality-of-life improvements

## 🛠️ Tools Included

### Shell & Terminal
- **Zsh**: Shell with custom configuration
- **Starship**: Cross-shell prompt with beautiful customization
- **WezTerm**: Modern terminal emulator (GUI environments)
- **Zellij**: Terminal multiplexer with modern features

### Modern CLI Replacements
- `bat` → replaces `cat` (syntax highlighting)
- `eza` → replaces `ls` (better file listing)
- `fd` → replaces `find` (faster file search)
- `ripgrep` → replaces `grep` (faster text search)
- `bottom` → replaces `top` (system monitor)
- `zoxide` → smart `cd` (directory jumping)

### Development Tools
- **Neovim**: Modern Vim-based editor
- **Mise**: Version manager (Node.js, Python, Terraform)
- **Git**: With GitHub CLI (`gh`) integration
- **lazygit**: Terminal UI for Git

### Additional Tools
- `fzf`: Fuzzy finder
- `jq`/`yq`: JSON/YAML processors
- `ghq`: Git repository manager

## 📋 Prerequisites

### Required
- [Chezmoi](https://www.chezmoi.io/install/) - Dotfile manager

### Automatically Installed
- [Homebrew](https://brew.sh/) - Package manager (installed via Chezmoi script)
- All other tools listed above (installed via Homebrew)

## 🚀 Installation

### First-time Setup

1. **Install Chezmoi** (if not already installed):
   ```bash
   # macOS/Linux
   sh -c "$(curl -fsLS get.chezmoi.io)"
   
   # Windows (PowerShell)
   (irm -useb https://get.chezmoi.io/ps1) | powershell -c -
   ```

2. **Initialize with this repository**:
   ```bash
   chezmoi init k-tahiro
   ```

3. **Review changes before applying**:
   ```bash
   chezmoi diff
   ```

4. **Apply the dotfiles**:
   ```bash
   chezmoi apply -v
   ```

5. **Restart your shell**:
   ```bash
   exec $SHELL -l
   ```

### Updating

To pull and apply the latest changes:

```bash
chezmoi update -v
```

## ⚙️ Configuration

### Environment Detection

The dotfiles automatically detect your environment:

- **`isWsl`**: Running in Windows Subsystem for Linux
- **`isWork`**: macOS or native Linux (work environment)
- **`isHeadless`**: Server/headless environment (no GUI)

### Package Sets

Packages are organized in `.chezmoidata/homebrew.toml`:

- **shared**: Common tools for all environments
- **work**: Work-specific tools (cloud CLIs, development tools)
- **private**: Personal tools and utilities

### Customization

#### Local Overrides

Create local configuration files that won't be tracked:

- `~/.config/zsh/.zshenv.local` - Local environment variables
- `~/.config/zsh/.zprofile.local` - Local profile settings
- `~/.config/zsh/.zshrc.local` - Local shell configuration

#### Editing Configurations

```bash
# Edit any dotfile
chezmoi edit ~/.zshrc

# Automatically apply changes after editing
chezmoi edit --apply ~/.zshrc
```

## 📁 Repository Structure

```
.
├── .chezmoi.toml.tmpl           # Main Chezmoi configuration
├── .chezmoidata/                # Data for templates
│   └── homebrew.toml            # Package definitions
├── .chezmoiscripts/             # Post-installation scripts
│   ├── run_onchange_after_01_brew.sh.tmpl
│   └── run_onchange_after_02_mise.sh.tmpl
├── dot_config/                  # ~/.config/ directory
│   ├── homebrew/                # Homebrew Brewfile
│   ├── mise/                    # Mise version manager config
│   ├── starship.toml            # Starship prompt
│   ├── wezterm/                 # WezTerm terminal config
│   └── zsh/                     # Zsh shell configuration
├── dot_gitconfig.tmpl           # Git configuration
├── dot_zshenv                   # Zsh environment setup
└── readonly_Documents/          # Read-only documentation
    └── PowerShell/              # Windows PowerShell profile
```

## 🔧 Troubleshooting

### Homebrew Not Found

If Homebrew commands aren't found after installation:

```bash
# macOS
eval "$(/opt/homebrew/bin/brew shellenv)"

# Linux
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

### Chezmoi Scripts Not Running

Ensure scripts have execution permissions:

```bash
chezmoi verify
```

### Mise Tools Not Available

Install configured tools manually:

```bash
mise install
```

### Font Issues in Terminal

Install the Nerd Font required by Starship:

```bash
# Automatically installed via Homebrew cask
brew install --cask font-fira-code-nerd-font
```

Configure your terminal to use "FiraCode Nerd Font".

## 🤝 Contributing

This is a personal dotfiles repository, but suggestions and improvements are welcome! Feel free to:

- Open an issue for bugs or suggestions
- Submit a pull request for improvements
- Fork and adapt for your own use

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Chezmoi](https://www.chezmoi.io/) - Excellent dotfile manager
- [Starship](https://starship.rs/) - Beautiful shell prompt
- The amazing maintainers of all the modern CLI tools

---

**Author**: Keisuke Hirota  
**GitHub**: [@k-tahiro](https://github.com/k-tahiro)