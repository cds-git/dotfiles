#!/bin/bash
# lazydocker configuration module
# Installation handled by mise

install_lazydocker_config() {
    echo ""
    echo "=== lazydocker Configuration ==="

    ensure_link "$HOME/dotfiles/lazydocker/config.yml" \
        "$HOME/.config/lazydocker/config.yml" "lazydocker config"
}
