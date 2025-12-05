#!/bin/bash
# Starship prompt installation and configuration module

install_starship() {
    echo ""
    echo "=== Starship ==="
    
    if command_exists starship; then
        echo "✓ Starship already installed"
    else
        echo "Installing Starship prompt..."
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            curl -sS https://starship.rs/install.sh | sh -s -- --yes
        elif [ "$ID" = "arch" ]; then
            sudo pacman -S --noconfirm starship
        elif [ "$ID" = "fedora" ]; then
            sudo dnf install -y starship
        fi
        echo "✓ Starship installed"
    fi
    
    # Create .config directory if it doesn't exist
    mkdir -p "$HOME/.config"
    
    # Create symlink
    local starship_config="$HOME/.config/starship.toml"
    local dotfiles_starship="$HOME/dotfiles/starship/starship.toml"
    
    if [ -L "$starship_config" ]; then
        echo "✓ Starship config symlink exists"
    elif [ -f "$starship_config" ]; then
        echo "⚠ Backing up existing config"
        mv "$starship_config" "$starship_config.backup"
        ln -sf "$dotfiles_starship" "$starship_config"
        echo "✓ Created Starship config symlink"
    else
        ln -sf "$dotfiles_starship" "$starship_config"
        echo "✓ Created Starship config symlink"
    fi
}
