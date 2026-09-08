#!/bin/bash
# bat (syntax highlighter) configuration module
# Installation handled by mise

install_bat_config() {
    echo ""
    echo "=== bat Configuration ==="

    # Install Catppuccin theme
    local bat_config_dir="$HOME/.config/bat/themes"
    local theme_file="$bat_config_dir/Catppuccin Mocha.tmTheme"

    if [ -f "$theme_file" ]; then
        echo "✓ Catppuccin Mocha theme already installed"
    else
        echo "Installing Catppuccin Mocha theme..."
        mkdir -p "$bat_config_dir"

        local theme_url="https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme"
        curl -fsSL "$theme_url" -o "$theme_file"
        echo "✓ Catppuccin Mocha theme installed"
    fi

    # Build bat cache to register themes
    echo "Building bat cache..."
    if command_exists bat; then
        bat cache --build &>/dev/null
        echo "✓ bat cache built successfully"
    fi

    ensure_link "$HOME/dotfiles/bat/config" "$HOME/.config/bat/config" "bat config"
}
