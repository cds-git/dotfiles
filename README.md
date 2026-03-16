# dotfiles

Greatest config known to mankind

## What's Included

### Terminal
- **WezTerm** - GPU-accelerated terminal emulator
- **Tmux** - Terminal multiplexer with status bar

### Code Editor
- **Neovim** - Code editor with LSP, treesitter, and fuzzy finding

### Shell
- **Zsh** (Linux) / **PowerShell** (Windows) - Shell configs and aliases
- **Starship** - Prompt
- **Eza** - Modern ls
- **Zoxide** - Smarter cd
- **FZF** - Fuzzy finder

### Version Control
- **Git** - With delta pager and custom aliases
- **Lazygit** - TUI for git

### Docker
- **Lazydocker** - TUI for docker

### Databases
- **Lazysql** - TUI for databases

### File Management
- **Yazi** - Terminal file manager
- **Bat** - Syntax-highlighted cat

**Theme**: Catppuccin Mocha across all tools

## Tools Managed by mise (Linux)

[mise](https://mise.jdx.dev) manages CLI tool versions on Linux from a single `mise/config.toml`:

On Windows, tools are installed via winget/chocolatey/GitHub releases through PowerShell modules.

## Installation

### Windows

Run as Administrator:

```powershell
.\scripts\install.ps1
```

### Linux

```bash
./scripts/install.sh
```

## Setup

### Git Identity

The install script will prompt for your name and email. You can also set manually:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Git Hooks in Existing Repos

Run `git init` in existing repos to install the commit-msg hook (safe for existing repos).

## Keybindings

- **Vim-style navigation** (hjkl) with arrow key alternatives
- **Homerow mod friendly** - arrow keys work everywhere hjkl does
- **Leader key**: Space (Neovim)
- **Consistent across tools** - similar bindings in Neovim, tmux, lazygit

## Notes

- Git hooks use file copies instead of symlinks for Windows compatibility
- Neovim config is maintained as a submodule
- All configurations use Catppuccin Mocha theme

### GitHub Token for mise (Linux)

mise uses the GitHub API to fetch tool releases. Without a token, you're limited to 60 requests/hr which can cause rate limit errors during setup. To fix this:

1. Create a token at https://github.com/settings/tokens with no scopes
2. Add to your machine's `~/.zshrc` **before** the mise activate line:
   ```bash
   export GITHUB_TOKEN="ghp_yourtoken"
   ```

This is machine-local and not committed to the dotfiles.

## TODO

- Add tiling window manager for Linux
- Add screenshots to showcase the config
