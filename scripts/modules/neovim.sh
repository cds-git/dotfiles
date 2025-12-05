#!/bin/bash
# Neovim installation and configuration module

install_neovim() {
    echo ""
    echo "=== Neovim ==="
    
    if command_exists nvim; then
        echo "✓ Neovim already installed"
    else
        echo "Installing Neovim..."
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            # Remove old version if exists
            sudo apt remove -y neovim 2>/dev/null
            
            # Add unstable PPA for latest version
            sudo apt install -y software-properties-common
            sudo add-apt-repository -y ppa:neovim-ppa/unstable
            sudo apt update
            sudo apt install -y neovim
        elif [ "$ID" = "arch" ]; then
            sudo pacman -S --noconfirm neovim
        elif [ "$ID" = "fedora" ]; then
            sudo dnf install -y neovim
        fi
        echo "✓ Neovim installed"
    fi
    
    # Install utilities for Neovim
    echo "Installing Neovim utilities..."
    
    local tools=("ripgrep" "fd-find" "fzf")
    
    if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
        for tool in "${tools[@]}"; do
            if ! command_exists "$tool" && ! command_exists "${tool#fd-}"; then
                sudo apt install -y "$tool" 2>/dev/null || echo "  ⚠ Could not install $tool"
            else
                echo "  ✓ $tool already installed"
            fi
        done
    elif [ "$ID" = "arch" ]; then
        # Arch uses different package names
        local arch_tools=("ripgrep" "fd" "fzf")
        for tool in "${arch_tools[@]}"; do
            if ! command_exists "$tool"; then
                sudo pacman -S --noconfirm "$tool" 2>/dev/null
            else
                echo "  ✓ $tool already installed"
            fi
        done
    elif [ "$ID" = "fedora" ]; then
        local fedora_tools=("ripgrep" "fd-find" "fzf")
        for tool in "${fedora_tools[@]}"; do
            if ! command_exists "$tool"; then
                sudo dnf install -y "$tool" 2>/dev/null || echo "  ⚠ Could not install $tool"
            else
                echo "  ✓ $tool already installed"
            fi
        done
    fi
    
    # Update nvim submodule
    echo "Updating nvim submodule..."
    cd "$HOME/dotfiles" || return 1
    git submodule update --init --recursive 2>&1 | grep -v "^Submodule" || true
    cd - >/dev/null || return 1
    
    # Create symlink
    local nvim_config="$HOME/.config/nvim"
    local dotfiles_nvim="$HOME/dotfiles/nvim"
    
    if [ -L "$nvim_config" ]; then
        echo "✓ Neovim config symlink exists"
    elif [ -d "$nvim_config" ]; then
        echo "⚠ Backing up existing config"
        mv "$nvim_config" "$nvim_config.backup"
        ln -sf "$dotfiles_nvim" "$nvim_config"
        echo "✓ Created Neovim config symlink"
    else
        ln -sf "$dotfiles_nvim" "$nvim_config"
        echo "✓ Created Neovim config symlink"
    fi
}
