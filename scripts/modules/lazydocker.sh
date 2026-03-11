#!/bin/bash
# lazydocker configuration module
# Installation handled by mise

install_lazydocker_config() {
    echo ""
    echo "=== lazydocker Configuration ==="

    local config_dir="$HOME/.config/lazydocker"
    local config_file="$config_dir/config.yml"
    local source_config="$HOME/dotfiles/lazydocker/config.yml"

    mkdir -p "$config_dir"

    if [ -L "$config_file" ]; then
        echo "✓ lazydocker config symlink exists"
    else
        [ -f "$config_file" ] && mv "$config_file" "$config_file.backup"
        ln -sf "$source_config" "$config_file"
        echo "✓ Created lazydocker config symlink"
    fi
}
