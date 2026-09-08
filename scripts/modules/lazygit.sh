#!/bin/bash
# Lazygit configuration module
# Installation of lazygit and delta handled by mise

install_lazygit_config() {
    echo ""
    echo "=== Lazygit Configuration ==="

    ensure_link "$HOME/dotfiles/lazygit/config.yml" \
        "$HOME/.config/lazygit/config.yml" "Lazygit config"
}
