#!/bin/bash
# Fastfetch configuration module
# Installation handled by OS package manager

install_fastfetch_config() {
    echo ""
    echo "=== Fastfetch Configuration ==="

    ensure_link "$HOME/dotfiles/fastfetch/config.jsonc" \
        "$HOME/.config/fastfetch/config.jsonc" "Fastfetch config"
}
