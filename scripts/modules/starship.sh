#!/bin/bash
# Starship prompt configuration module
# Installation handled by mise

install_starship_config() {
    echo ""
    echo "=== Starship Configuration ==="

    ensure_link "$HOME/dotfiles/starship/starship.toml" \
        "$HOME/.config/starship.toml" "Starship config"
}
