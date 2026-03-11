#!/bin/bash
# Starship prompt configuration module
# Installation handled by mise

install_starship_config() {
    echo ""
    echo "=== Starship Configuration ==="

    mkdir -p "$HOME/.config"

    local starship_config="$HOME/.config/starship.toml"
    local dotfiles_starship="$HOME/dotfiles/starship/starship.toml"

    if [ -L "$starship_config" ]; then
        echo "✓ Starship config symlink exists"
    elif [ -f "$starship_config" ]; then
        echo "⚠ Backing up existing config"
        mv "$starship_config" "$starship_config.backup"
        ln -sf "$dotfiles_starship" "$starship_config"
        echo "✓ Created Starship config symlink"
    else
        ln -sf "$dotfiles_starship" "$starship_config"
        echo "✓ Created Starship config symlink"
    fi
}
