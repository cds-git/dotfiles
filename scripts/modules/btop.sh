#!/bin/bash
# btop configuration module
# Installation handled by mise

install_btop_config() {
    echo ""
    echo "=== btop Configuration ==="

    ensure_link "$HOME/dotfiles/btop/themes/catppuccin_mocha.theme" \
        "$HOME/.config/btop/themes/catppuccin_mocha.theme" "btop theme"
    ensure_link "$HOME/dotfiles/btop/btop.conf" \
        "$HOME/.config/btop/btop.conf" "btop config"
}
