#!/bin/bash
# Fastfetch configuration module
# Installation handled by OS package manager

install_fastfetch_config() {
    echo ""
    echo "=== Fastfetch Configuration ==="

    local config_dir="$HOME/.config/fastfetch"
    local config_file="$config_dir/config.jsonc"
    local dotfiles_config="$HOME/dotfiles/fastfetch/config.jsonc"

    mkdir -p "$config_dir"

    if [ -L "$config_file" ]; then
        echo "✓ Fastfetch config symlink exists"
    elif [ -f "$config_file" ]; then
        echo "⚠ Backing up existing config"
        mv "$config_file" "$config_file.backup"
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ Created Fastfetch config symlink"
    else
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ Created Fastfetch config symlink"
    fi
}
