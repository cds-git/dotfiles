#!/bin/bash
# Yazi installation and configuration module

install_yazi() {
    echo ""
    echo "=== yazi (Terminal File Manager) ==="
    
    if command_exists yazi; then
        local version=$(yazi --version | head -n1)
        echo "✓ yazi already installed ($version)"
    else
        echo "Installing yazi..."
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            # Yazi requires newer Rust - update via rustup
            if ! command_exists rustup; then
                echo "Installing rustup (Rust toolchain manager)..."
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                source "$HOME/.cargo/env"
            fi
            
            # Ensure we have the latest stable Rust
            rustup update stable
            source "$HOME/.cargo/env"
            
            cargo install --locked yazi-fm yazi-cli
        elif [ "$ID" = "arch" ]; then
            sudo pacman -S --noconfirm yazi
        elif [ "$ID" = "fedora" ]; then
            # yazi not in default repos, use cargo
            if ! command_exists cargo; then
                sudo dnf install -y cargo
            fi
            cargo install --locked yazi-fm yazi-cli
            
            # Source cargo env to make yazi available immediately
            [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
            export PATH="$HOME/.cargo/bin:$PATH"
        fi
        echo "✓ yazi installed"
    fi
}

install_yazi_config() {
    echo ""
    echo "=== Yazi Configuration ==="
    
    local config_dir="$HOME/.config/yazi"
    mkdir -p "$config_dir"
    
    # Symlink theme
    local theme_file="$config_dir/theme.toml"
    local dotfiles_theme="$HOME/dotfiles/yazi/theme.toml"
    
    if [ -L "$theme_file" ]; then
        echo "✓ Yazi theme already configured"
    elif [ -f "$theme_file" ]; then
        echo "⚠ Backing up existing theme.toml"
        mv "$theme_file" "$theme_file.backup"
        ln -sf "$dotfiles_theme" "$theme_file"
        echo "✓ Yazi theme configured (Catppuccin Mocha)"
    else
        ln -sf "$dotfiles_theme" "$theme_file"
        echo "✓ Yazi theme configured (Catppuccin Mocha)"
    fi
    
    # Symlink config
    local config_file="$config_dir/yazi.toml"
    local dotfiles_config="$HOME/dotfiles/yazi/yazi.toml"
    
    if [ -L "$config_file" ]; then
        echo "✓ Yazi config already configured"
    elif [ -f "$config_file" ]; then
        echo "⚠ Backing up existing yazi.toml"
        mv "$config_file" "$config_file.backup"
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ Yazi config configured"
    else
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ Yazi config configured"
    fi
}
