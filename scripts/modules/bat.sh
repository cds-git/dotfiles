#!/bin/bash
# bat (syntax highlighter) installation module

install_bat() {
    echo ""
    echo "=== bat (Syntax Highlighter) ==="
    
    if command_exists bat; then
        local version=$(bat --version)
        echo "✓ bat already installed ($version)"
    else
        echo "Installing bat..."
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            sudo apt install -y bat
            # Create alias since Ubuntu packages it as 'batcat'
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
        elif [ "$ID" = "arch" ]; then
            sudo pacman -S --noconfirm bat
        elif [ "$ID" = "fedora" ]; then
            sudo dnf install -y bat
        fi
        echo "✓ bat installed"
    fi
    
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
}

install_bat_config() {
    echo ""
    echo "=== bat Configuration ==="
    
    local dotfiles_root="$HOME/dotfiles"
    local source="$dotfiles_root/bat/config"
    local target="$HOME/.config/bat/config"
    local target_dir=$(dirname "$target")
    
    mkdir -p "$target_dir"
    
    if [ -L "$target" ]; then
        echo "✓ bat config already symlinked"
    elif [ -f "$target" ]; then
        echo "⚠ bat config exists but is not a symlink"
        echo "  Backing up existing config..."
        mv "$target" "$target.backup"
        ln -sf "$source" "$target"
        echo "✓ bat config symlinked (old config backed up)"
    else
        echo "Creating symlink for bat config..."
        ln -sf "$source" "$target"
        echo "✓ bat config symlinked"
    fi
}
