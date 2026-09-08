#!/bin/bash
# mise (tool version manager) installation module
# Replaces: fnm, rustup/cargo, distro-specific installs for CLI tools
# See: https://mise.jdx.dev

install_mise() {
    echo ""
    echo "=== mise (Tool Manager) ==="

    if command_exists mise; then
        echo "✓ mise already installed ($(mise --version 2>/dev/null | head -1))"
        echo "Checking for a newer mise..."
        if mise self-update -y &>/dev/null; then
            echo "✓ mise up to date ($(mise --version 2>/dev/null | head -1))"
        else
            echo "⊘ mise self-update unavailable (installed by a package manager?)"
        fi
        return 0
    fi

    echo "Installing mise..."
    curl https://mise.run | sh

    if wait_for_command mise; then
        echo "✓ mise installed"
    else
        echo "✗ mise installed but not in PATH yet. Restart shell."
        return 1
    fi
}

install_mise_tools() {
    echo ""
    echo "=== mise Tools ==="

    local dotfiles_config="$HOME/dotfiles/mise/config.toml"

    ensure_link "$dotfiles_config" "$HOME/.config/mise/config.toml" "mise config"

    # Trust the config so mise doesn't prompt
    mise trust "$dotfiles_config" &>/dev/null

    # Install anything listed in config.toml that isn't present yet.
    echo "Installing missing tools..."
    mise install --yes

    # `mise install` is satisfied by ANY already-installed version, so a
    # `= "latest"` pin never moves forward once something is installed —
    # this is why a new Neovim release was being skipped. `mise upgrade` is
    # what actually fetches newer releases matching each pin.
    echo ""
    echo "Upgrading tools to the newest matching versions..."
    mise upgrade --yes

    echo ""
    echo "Installed tools:"
    mise ls --current 2>/dev/null || mise ls
    echo ""
    echo "✓ mise tools installed and up to date"
}
