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
    # Refresh PATH by sourcing common profile locations
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc" 2>/dev/null || true
    fi
    if [ -f "$HOME/.zshrc" ]; then
        source "$HOME/.zshrc" 2>/dev/null || true
    fi
    # Also manually add common bin directories
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/bin:$PATH"
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
    "dev-tools.sh"
    "bat.sh"
    "eza.sh"
    "git.sh"
    "wezterm.sh"
    "neovim.sh"
    "starship.sh"
    "lazygit.sh"
    "yazi.sh"
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

echo ""
echo '--- Development Tools ---'
install_common_packages
install_dotnet
install_nodejs
install_bat
install_eza
install_yazi
install_opencode

echo ""
echo '--- Terminal and Utilities ---'
if [ "$WSL_MODE" = false ]; then
    install_wezterm
else
    echo ""
    echo "=== WezTerm ==="
    echo "⊘ Skipped (WSL mode - GUI application)"
fi
install_starship
install_lazygit
install_neovim

echo ""
echo '--- Configurations ---'
install_git_config
install_git_hooks
install_bat_config
install_yazi_config
install_opencode_config

echo ""
echo '--- Shell Setup (ZSH & Tmux) ---'

# Setup ZSH as the default shell
if [ "$SHELL" != "$(command -v zsh)" ]; then
    echo "Setting Zsh as the default shell..."
    chsh -s "$(command -v zsh)"
    echo "✓ Zsh set as default shell"
else
    echo "✓ Zsh already default shell"
fi

# Create symlinks for zsh and tmux
if [ -L "$HOME/.zshrc" ]; then
    echo "✓ .zshrc symlink exists"
else
    [ -f "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
    ln -sf "$HOME/dotfiles/zsh/zshrc" "$HOME/.zshrc"
    echo "✓ Created .zshrc symlink"
fi

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
