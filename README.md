# dotfiles

Greatest config known to mankind

## What's Included

- **Neovim** - Modern Neovim config with LSP, fuzzy finding, and more
- **WezTerm** - GPU-accelerated terminal with tmux-style bindings
- **Tmux** - Terminal multiplexer with custom status bar
- **Starship** - Fast, customizable shell prompt
- **Git** - Git configuration with delta integration and useful aliases
- **Lazygit** - Terminal UI for git with Catppuccin theme
- **PowerShell/Zsh** - Shell configurations and aliases

**Theme**: Catppuccin across all tools

## Installation and Setup

### Windows

Run the following command in PowerShell as Administrator:

```powershell
.\scripts\install.ps1
```

This will:
1. Install development tools (Chocolatey, .NET SDK, Node.js)
2. Install terminal tools (WezTerm, Neovim, Starship, Lazygit)
3. Configure Git with shared settings and useful aliases
4. Set up PowerShell profile
5. Install git hooks (automatic JIRA ticket extraction from branch names)

### Linux

To install and configure everything:

```bash
./scripts/install.sh
```

## Post-Installation

### 1. Configure Git Identity

After running the install script, update your personal git information in `~/.gitconfig`:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

The dotfiles use an include-based approach where `~/.gitconfig` includes the shared config from `dotfiles/git/gitconfig`. This allows you to safely use `git config --global` commands without modifying tracked files.

### 2. Install Hooks in Existing Repositories

For existing git repositories, install the commit-msg hook by either:
- Running `git init` in the repository (safe for existing repos)
- Or manually copying: `cp ~/.git-templates/hooks/commit-msg <repo>/.git/hooks/commit-msg`

New clones will automatically get the hooks via the git template directory.

## Keybinding Philosophy

- **Vim-style navigation** (hjkl) with arrow key alternatives
- **Homerow mod friendly** - arrow keys work everywhere hjkl does
- **Leader key**: Space (Neovim)
- **Consistent across tools** - similar bindings in Neovim, tmux, lazygit

## Notes

### Windows-Specific
- Git hooks use file copies instead of symlinks for Windows compatibility
- PowerShell profile is configured for optimal development experience

### Cross-Platform
- All configurations use Catppuccin Mocha theme for consistency
- Neovim config is maintained as a submodule for easier updates

## TODO

- Add tiling window manager for Windows
- Add Windows status bar
- Add tiling window manager for Linux
- Add screenshots to showcase the config
