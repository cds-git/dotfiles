#!/bin/bash
# Yazi configuration module
# Installation handled by mise

install_yazi_config() {
    echo ""
    echo "=== Yazi Configuration ==="

    local config_dir="$HOME/.config/yazi"
    mkdir -p "$config_dir"

    # Symlink theme
    local theme_file="$config_dir/theme.toml"
    local dotfiles_theme="$HOME/dotfiles/yazi/theme.toml"

    if [ -L "$theme_file" ]; then
        echo "✓ Yazi theme already configured"
    elif [ -f "$theme_file" ]; then
        echo "⚠ Backing up existing theme.toml"
        mv "$theme_file" "$theme_file.backup"
        ln -sf "$dotfiles_theme" "$theme_file"
        echo "✓ Yazi theme configured (Catppuccin Mocha)"
    else
        ln -sf "$dotfiles_theme" "$theme_file"
        echo "✓ Yazi theme configured (Catppuccin Mocha)"
    fi

    # Symlink config
    local config_file="$config_dir/yazi.toml"
    local dotfiles_config="$HOME/dotfiles/yazi/yazi.toml"

    if [ -L "$config_file" ]; then
        echo "✓ Yazi config already configured"
    elif [ -f "$config_file" ]; then
        echo "⚠ Backing up existing yazi.toml"
        mv "$config_file" "$config_file.backup"
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ Yazi config configured"
    else
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ Yazi config configured"
    fi
}
