#!/bin/bash
# btop configuration module
# Installation handled by mise

install_btop_config() {
    echo ""
    echo "=== btop Configuration ==="

    local config_dir="$HOME/.config/btop"
    local themes_dir="$config_dir/themes"

    mkdir -p "$themes_dir"

    # Symlink theme
    local theme_file="$themes_dir/catppuccin_mocha.theme"
    local dotfiles_theme="$HOME/dotfiles/btop/themes/catppuccin_mocha.theme"

    if [ -L "$theme_file" ]; then
        echo "✓ btop theme symlink exists"
    else
        [ -f "$theme_file" ] && mv "$theme_file" "$theme_file.backup"
        ln -sf "$dotfiles_theme" "$theme_file"
        echo "✓ Created btop theme symlink"
    fi

    # Symlink config
    local config_file="$config_dir/btop.conf"
    local dotfiles_config="$HOME/dotfiles/btop/btop.conf"

    if [ -L "$config_file" ]; then
        echo "✓ btop config symlink exists"
    else
        [ -f "$config_file" ] && mv "$config_file" "$config_file.backup"
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ Created btop config symlink"
    fi
}
