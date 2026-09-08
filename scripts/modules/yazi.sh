#!/bin/bash
# Yazi configuration module
# Installation handled by mise

install_yazi_config() {
    echo ""
    echo "=== Yazi Configuration ==="

    ensure_link "$HOME/dotfiles/yazi/theme.toml" \
        "$HOME/.config/yazi/theme.toml" "Yazi theme (Catppuccin Mocha)"
    ensure_link "$HOME/dotfiles/yazi/yazi.toml" \
        "$HOME/.config/yazi/yazi.toml" "Yazi config"
}
