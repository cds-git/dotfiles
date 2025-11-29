# dotfiles

Greatest dotfiles known to mankind

## What's Included

- **Neovim** - Modern Neovim config with LSP, fuzzy finding, and more
- **WezTerm** - GPU-accelerated terminal with tmux-style bindings
- **Tmux** - Terminal multiplexer with custom status bar
- **Starship** - Fast, customizable shell prompt
- **Git** - Git configuration with delta integration and useful aliases
- **Lazygit** - Terminal UI for git with Catppuccin theme
- **PowerShell/Zsh** - Shell configurations and aliases

**Theme**: Catppuccin Mocha across all tools

## Installation and Setup

### Windows

Run the following command in PowerShell as Administrator:

```powershell
.\scripts\install-new.ps1
```

This will:
1. Install development tools (Chocolatey, .NET SDK, nvm-windows for Node.js)
2. Install terminal tools (WezTerm, Neovim, Starship, Lazygit, Git utilities)
3. Create symlinks/configs for all tools
4. Set up PowerShell profile
5. Install git hooks (JIRA ticket extraction)

### Linux

To install and configure everything for Ubuntu or Arch:

```bash
sudo ./scripts/install.sh
```

## Configuration Details

### Neovim
- **Plugin Manager**: lazy.nvim
- **LSP**: Configured for C#, TypeScript, Lua, and more
- **Fuzzy Finder**: Snacks.nvim picker
- **Key Features**: Blink completion, Treesitter, Gitsigns, Oil file explorer

### Git
- **Delta** for beautiful diffs with syntax highlighting
- **Useful aliases** (see `git/README.md`)
- **Auto-setup remote** on push
- **Catppuccin Mocha** theme for delta
- **Local config** - Personal info (name/email) kept in `~/.gitconfig.local` (not tracked)

### Lazygit
- **Catppuccin Mocha** theme
- **Delta integration** for diffs
- **Vim keybindings** throughout
- **Auto-fetch** enabled

### WezTerm
- Arrow key support in copy mode (for homerow mod users)
- Vi-style navigation
- Alt+Arrow scrolling (consistent with tmux)

## Post-Installation

After running the install script, configure your personal git information:

**Windows:**
```powershell
notepad ~/.gitconfig.local
```

**Linux:**
```bash
vim ~/.gitconfig.local
```

Update with your name and email:
```ini
[user]
    name = Your Name
    email = your.email@example.com
```

## Keybinding Philosophy

- **Vim-style navigation** (hjkl) with arrow key alternatives
- **Homerow mod friendly** - arrow keys work everywhere hjkl does
- **Leader key**: Space (Neovim)
- **Consistent across tools** - similar bindings in Neovim, tmux, lazygit

## TODO

- ✅ ~~Add config for git~~
- ✅ ~~Add config with theming for lazygit~~
- Split scripts into install packages and symlinks
- Add pre-commit hook to extract JIRA issue ID from branch
- Add tiling window manager for Windows
- Add Windows status bar
- Add tiling window manager for Linux
- Add screenshots to showcase the config
