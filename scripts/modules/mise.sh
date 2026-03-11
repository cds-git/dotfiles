#!/bin/bash
# mise (tool version manager) installation module
# Replaces: fnm, rustup/cargo, distro-specific installs for CLI tools
# See: https://mise.jdx.dev

install_mise() {
    echo ""
    echo "=== mise (Tool Manager) ==="

    if command_exists mise; then
        echo "✓ mise already installed"
    else
        echo "Installing mise..."
        curl https://mise.run | sh

        # Add mise to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"

        if wait_for_command mise; then
            echo "✓ mise installed"
        else
            echo "✗ mise installed but not in PATH yet. Restart shell."
            return 1
        fi
    fi
}

install_mise_tools() {
    echo ""
    echo "=== mise Tools ==="

    # Symlink mise config from dotfiles
    local config_dir="$HOME/.config/mise"
    local config_file="$config_dir/config.toml"
    local dotfiles_config="$HOME/dotfiles/mise/config.toml"

    mkdir -p "$config_dir"

    if [ -L "$config_file" ]; then
        echo "✓ mise config symlink exists"
    else
        [ -f "$config_file" ] && mv "$config_file" "$config_file.backup"
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ Created mise config symlink"
    fi

    # Trust the config so mise doesn't prompt
    mise trust "$dotfiles_config" 2>/dev/null

    # Install all tools defined in config
    echo "Installing tools (this may take a moment)..."
    mise install --yes

    echo ""
    echo "Installed tools:"
    mise ls --current 2>/dev/null || mise ls
    echo ""
    echo "✓ All mise tools installed"
}
