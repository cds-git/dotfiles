#!/bin/bash
# Lazygit configuration module
# Installation of lazygit and delta handled by mise

install_lazygit_config() {
    echo ""
    echo "=== Lazygit Configuration ==="

    local config_dir="$HOME/.config/lazygit"
    mkdir -p "$config_dir"

    local config_file="$config_dir/config.yml"
    local dotfiles_config="$HOME/dotfiles/lazygit/config.yml"

    if [ -L "$config_file" ]; then
        echo "✓ Lazygit config symlink exists"
    elif [ -f "$config_file" ]; then
        echo "⚠ Backing up existing config"
        mv "$config_file" "$config_file.backup"
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ Created Lazygit config symlink"
    else
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ Created Lazygit config symlink"
    fi
}
