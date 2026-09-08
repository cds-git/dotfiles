#!/bin/bash
# Neovim configuration module
# Installation handled by mise (neovim = "latest" in config.toml)

install_neovim_config() {
    echo ""
    echo "=== Neovim Configuration ==="

    ensure_link "$HOME/dotfiles/nvim" "$HOME/.config/nvim" "Neovim config"
}
