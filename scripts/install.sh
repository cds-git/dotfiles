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
    echo "  GUI applications (like WezTerm) will be skipped"
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
    "wezterm.sh"
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

# --- Phase 3: GUI applications (non-WSL only) ---
echo ""
echo '--- GUI Applications ---'
if [ "$WSL_MODE" = false ]; then
    install_wezterm
else
    echo ""
    echo "=== WezTerm ==="
    echo "⊘ Skipped (WSL mode - GUI application)"
fi

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
    if grep -iq Microsoft /proc/version; then
        echo "  Note: Restart WSL with 'wsl --terminate archlinux' then 'wsl'"
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

# Lines to ensure are present in .zshrc
# Each entry: grep pattern | line to append
zshrc_entries=(
    'dotfiles/zsh/zshrc|source "$HOME/dotfiles/zsh/zshrc"'
    'mise activate zsh|eval "$(mise activate zsh --shims)"'
    'fzf --zsh|source <(fzf --zsh 2>/dev/null) || true'
    'zoxide init|eval "$(zoxide init --cmd cd zsh)"'
    'starship init zsh|eval "$(starship init zsh)"'
    '.opencode/bin|export PATH="$HOME/.opencode/bin:$PATH"'
)

for entry in "${zshrc_entries[@]}"; do
    pattern="${entry%%|*}"
    line="${entry##*|}"
    if ! grep -qF "$pattern" "$HOME/.zshrc" 2>/dev/null; then
        echo "$line" >> "$HOME/.zshrc"
        echo "✓ Added to .zshrc: $line"
    else
        echo "✓ .zshrc already has: $pattern"
    fi
done

if [ -L "$HOME/.tmux.conf" ]; then
    echo "✓ .tmux.conf symlink exists"
else
    [ -f "$HOME/.tmux.conf" ] && mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup"
    ln -sf "$HOME/dotfiles/tmux/tmux.conf" "$HOME/.tmux.conf"
    echo "✓ Created .tmux.conf symlink"
fi

echo ""
echo '========================================'
echo 'Installation Complete!'
echo '========================================'
echo ""
echo 'Next steps:'
echo '  1. Configure git identity'
echo '  2. Reload shell (exec zsh or logout/login)'
echo '  3. Run git init in repos to install hooks'
echo ""
