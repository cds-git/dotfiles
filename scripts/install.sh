#!/bin/bash
# Master installation script for dotfiles

echo '╔═══════════════════════════════════════╗'
echo '║   Dotfiles Installation Script        ║'
echo '║   Greatest config known to mankind    ║'
echo '╚═══════════════════════════════════════╝'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# Auto-detect WSL environment
WSL_MODE=false
if grep -iq Microsoft /proc/version 2>/dev/null; then
    WSL_MODE=true
    echo ""
    echo "⚠ WSL environment detected"
    echo "  The terminal itself is Windows Terminal, configured by scripts/install.ps1"
fi

# Detect the Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Cannot detect the OS."
    exit 1
fi

# Utility functions
command_exists() {
    command -v "$1" &>/dev/null
}

refresh_path() {
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc" 2>/dev/null || true
    fi
    if [ -f "$HOME/.zshrc" ]; then
        source "$HOME/.zshrc" 2>/dev/null || true
    fi
    export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:/usr/local/bin:$PATH"
}

# Point a config path at a file/dir in the dotfiles repo.
#
# Unlike a bare `[ -L "$target" ]` check, this re-points symlinks that have
# drifted to a stale target, so re-running the installer repairs the link
# instead of reporting "already exists" and leaving it broken.
ensure_link() {
    local source="$1"
    local target="$2"
    local label="$3"

    if [ ! -e "$source" ]; then
        echo "✗ $label: missing in dotfiles ($source)"
        return 1
    fi

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        if [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
            echo "✓ $label already linked"
            return 0
        fi
        echo "⚠ $label pointed at $(readlink -f "$target") — re-linking"
        rm "$target"
    elif [ -e "$target" ]; then
        echo "⚠ $label exists as a real file — backing up to $target.backup"
        mv "$target" "$target.backup"
    fi

    # -n so a directory target is replaced rather than linked *inside*
    ln -sfn "$source" "$target"
    echo "✓ $label linked"
}

# Append a line to ~/.zshrc unless a regex already matches it.
#
# Takes pattern and line as separate arguments: the previous "pattern|line"
# encoding broke on values containing `||`, and matching with `grep -F`
# meant regex patterns never matched and their lines were re-appended on
# every run.
ensure_zshrc_line() {
    local pattern="$1"
    local line="$2"

    if grep -qE -- "$pattern" "$HOME/.zshrc" 2>/dev/null; then
        echo "✓ .zshrc already has: $pattern"
    else
        printf '%s\n' "$line" >> "$HOME/.zshrc"
        echo "✓ Added to .zshrc: $line"
    fi
}

wait_for_command() {
    local cmd="$1"
    local max_attempts="${2:-5}"
    local delay="${3:-1}"

    for i in $(seq 1 $max_attempts); do
        refresh_path
        if command_exists "$cmd"; then
            return 0
        fi
        if [ $i -lt $max_attempts ]; then
            sleep $delay
        fi
    done

    return 1
}

echo ""
echo "Loading modules..."
modules=(
    "mise.sh"
    "dev-tools.sh"
    "bat.sh"
    "git.sh"
    "neovim.sh"
    "lazygit.sh"
    "lazydocker.sh"
    "yazi.sh"
    "btop.sh"
    "fastfetch.sh"
    "starship.sh"
    "opencode.sh"
)

for module in "${modules[@]}"; do
    module_path="$MODULES_DIR/$module"
    if [ -f "$module_path" ]; then
        . "$module_path"
        echo "  ✓ Loaded $module"
    else
        echo "  ✗ Missing $module"
    fi
done

echo ""
echo '========================================'
echo 'Starting installation...'
echo '========================================'

# --- Phase 1: OS-level packages ---
echo ""
echo '--- OS Packages ---'
install_common_packages

# --- Phase 2: mise + all tools (includes neovim) ---
echo ""
echo '--- mise + Development Tools ---'
install_mise
install_mise_tools
install_opencode

# --- Phase 4: Configurations ---
echo ""
echo '--- Configurations ---'
install_git_config
install_git_hooks
install_bat_config
install_neovim_config
install_starship_config
install_lazygit_config
install_lazydocker_config
install_yazi_config
install_btop_config
install_fastfetch_config
install_opencode_config

# --- Phase 5: Shell setup ---
echo ""
echo '--- Shell Setup (ZSH & Tmux) ---'

# Setup ZSH as the default shell
zsh_path="$(command -v zsh)"
current_shell=$(grep "^$(whoami):" /etc/passwd | cut -d: -f7)

if [ "$current_shell" != "$zsh_path" ]; then
    echo "Setting Zsh as the default shell..."

    if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
        echo "Adding $zsh_path to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    chsh -s "$zsh_path"

    echo "✓ Zsh set as default shell ($zsh_path)"
    if [ "$WSL_MODE" = true ]; then
        echo "  Note: Restart WSL with 'wsl --terminate <distro>' then 'wsl'"
    else
        echo "  Note: Log out and back in for changes to take effect"
    fi
else
    echo "✓ Zsh already default shell"
fi

# Remove old symlink if present, but don't touch real files
if [ -L "$HOME/.zshrc" ]; then
    rm "$HOME/.zshrc"
    echo "Removed old .zshrc symlink"
fi

# Ensure .zshrc exists
[ ! -f "$HOME/.zshrc" ] && touch "$HOME/.zshrc"

# Lines to ensure are present in .zshrc.
# Order matters: mise/fzf/starship install shell hooks, and zoxide checks that
# nothing registers a hook after it, so zoxide is initialized last.
ensure_zshrc_line 'dotfiles/zsh/zshrc'        'source "$HOME/dotfiles/zsh/zshrc"'
ensure_zshrc_line '\.local/bin.*mise.*shims'  'export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"'
ensure_zshrc_line '\.opencode/bin'            'export PATH="$HOME/.opencode/bin:$PATH"'
ensure_zshrc_line 'mise activate zsh'         'eval "$(mise activate zsh --shims)"'
ensure_zshrc_line 'fzf --zsh'                 'source <(fzf --zsh 2>/dev/null) || true'
ensure_zshrc_line 'starship init zsh'         'eval "$(starship init zsh)"'
ensure_zshrc_line 'zoxide init'               'eval "$(zoxide init --cmd cd zsh)"'

ensure_link "$HOME/dotfiles/tmux/tmux.conf" "$HOME/.tmux.conf" "tmux config"

echo ""
echo '========================================'
echo 'Installation Complete!'
echo '========================================'
echo ""

existing_name=$(git config --global user.name 2>/dev/null)
existing_email=$(git config --global user.email 2>/dev/null)

if [ -z "$existing_name" ]; then
    read -p "Enter your git user.name: " git_name
    if [ -n "$git_name" ]; then
        git config --global user.name "$git_name"
        echo "✓ Set git user.name to: $git_name"
    fi
else
    echo "✓ Git user.name already set: $existing_name"
fi

if [ -z "$existing_email" ]; then
    read -p "Enter your git user.email: " git_email
    if [ -n "$git_email" ]; then
        git config --global user.email "$git_email"
        echo "✓ Set git user.email to: $git_email"
    fi
else
    echo "✓ Git user.email already set: $existing_email"
fi

echo ""
echo 'Next steps:'
echo '  1. Reload shell (exec zsh or logout/login)'
echo '  2. Run git init in repos to install hooks'
echo ""
