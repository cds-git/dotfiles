#!/bin/bash
# Lazygit installation and configuration module

install_lazygit() {
    echo ""
    echo "=== Lazygit ==="
    
    if command_exists lazygit; then
        echo "✓ Lazygit already installed"
    else
        echo "Installing Lazygit..."
        local tmp_dir=$(mktemp -d)
        cd "$tmp_dir" || return 1
        
        local version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_x86_64.tar.gz"
        tar -xzf lazygit.tar.gz
        sudo install lazygit /usr/local/bin
        
        cd - >/dev/null
        rm -rf "$tmp_dir"
        echo "✓ Lazygit v$version installed"
    fi
    
    # Install delta for better diffs
    if ! command_exists delta; then
        echo "Installing delta..."
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            local tmp_dir=$(mktemp -d)
            cd "$tmp_dir" || return 1
            
            local version=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
            curl -Lo delta.deb "https://github.com/dandavison/delta/releases/download/${version}/git-delta_${version}_amd64.deb"
            sudo dpkg -i delta.deb
            
            cd - >/dev/null
            rm -rf "$tmp_dir"
            echo "✓ delta $version installed"
        elif [ "$ID" = "arch" ]; then
            sudo pacman -S --noconfirm git-delta
            echo "✓ delta installed"
        elif [ "$ID" = "fedora" ]; then
            sudo dnf install -y git-delta
            echo "✓ delta installed"
        fi
    else
        echo "✓ delta already installed"
    fi
    
    # Create symlink for config
    local config_dir="$HOME/.config/lazygit"
    mkdir -p "$config_dir"
    
    local config_file="$config_dir/config.yml"
    local dotfiles_config="$HOME/dotfiles/lazygit/config.yml"
    
    if [ -L "$config_file" ]; then
        echo "✓ Lazygit config symlink exists"
    elif [ -f "$config_file" ]; then
        echo "⚠ Backing up existing config"
        mv "$config_file" "$config_file.backup"
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ Created Lazygit config symlink"
    else
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ Created Lazygit config symlink"
    fi
}
