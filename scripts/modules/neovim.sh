#!/bin/bash
# Neovim configuration module
# Installation handled by mise (neovim = "latest" in config.toml)

install_neovim_config() {
    echo ""
    echo "=== Neovim Configuration ==="

    # Create symlink
    local nvim_config="$HOME/.config/nvim"
    local dotfiles_nvim="$HOME/dotfiles/nvim"

    if [ -L "$nvim_config" ]; then
        echo "✓ Neovim config symlink exists"
    elif [ -d "$nvim_config" ]; then
        echo "⚠ Backing up existing config"
        mv "$nvim_config" "$nvim_config.backup"
        ln -sf "$dotfiles_nvim" "$nvim_config"
        echo "✓ Created Neovim config symlink"
    else
        ln -sf "$dotfiles_nvim" "$nvim_config"
        echo "✓ Created Neovim config symlink"
    fi
}
