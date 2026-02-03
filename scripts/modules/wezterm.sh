#!/bin/bash
# WezTerm installation and configuration module

install_wezterm() {
    echo ""
    echo "=== WezTerm ==="
    
    if command_exists wezterm; then
        echo "✓ WezTerm already installed"
    else
        echo "Installing WezTerm..."
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            # Add WezTerm APT repo
            curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
            echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
            sudo apt update
            sudo apt install -y wezterm
        elif [ "$ID" = "arch" ]; then
            sudo pacman -S --noconfirm wezterm
        elif [ "$ID" = "fedora" ]; then
            sudo dnf copr enable -y wezfurlong/wezterm-nightly
            sudo dnf install -y wezterm
        fi
        echo "✓ WezTerm installed"
    fi
    
    # Create symlink
    local wezterm_config="$HOME/.wezterm.lua"
    local dotfiles_wezterm="$HOME/dotfiles/wezterm/wezterm.lua"
    
    if [ -L "$wezterm_config" ]; then
        echo "✓ WezTerm config symlink exists"
    elif [ -f "$wezterm_config" ]; then
        echo "⚠ Backing up existing config"
        mv "$wezterm_config" "$wezterm_config.backup"
        ln -sf "$dotfiles_wezterm" "$wezterm_config"
        echo "✓ Created WezTerm config symlink"
    else
        ln -sf "$dotfiles_wezterm" "$wezterm_config"
        echo "✓ Created WezTerm config symlink"
    fi
    
    # Install FiraCode Nerd Font
    install_wezterm_font
}

install_wezterm_font() {
    echo ""
    echo "=== FiraCode Nerd Font ==="
    
    # Check if font is already installed
    if fc-list | grep -qi "FiraCode Nerd Font"; then
        echo "✓ FiraCode Nerd Font already installed"
        return
    fi
    
    echo "Installing FiraCode Nerd Font..."
    
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    local font_dir="$HOME/.local/share/fonts"
    local temp_dir=$(mktemp -d)
    local temp_zip="$temp_dir/FiraCode.zip"
    
    # Download
    curl -L "$download_url" -o "$temp_zip" 2>/dev/null
    
    # Extract
    unzip -q "$temp_zip" -d "$temp_dir"
    
    # Install
    mkdir -p "$font_dir"
    find "$temp_dir" -name "*.ttf" ! -name "*Windows Compatible*" -exec cp {} "$font_dir/" \;
    
    # Update font cache
    fc-cache -f "$font_dir" 2>/dev/null
    
    echo "✓ FiraCode Nerd Font installed"
    
    # Cleanup
    rm -rf "$temp_dir"
}
