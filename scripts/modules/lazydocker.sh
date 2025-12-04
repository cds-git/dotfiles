#!/bin/bash
# lazydocker installation module

install_lazydocker() {
    echo ""
    echo "=== lazydocker (Docker TUI) ==="
    
    if command_exists lazydocker; then
        local version=$(lazydocker --version 2>&1 | head -n1 || echo "unknown")
        echo "✓ lazydocker already installed ($version)"
    else
        echo "Installing lazydocker..."
        
        if [ "$ID" = "arch" ]; then
            if command_exists yay; then
                yay -S --noconfirm lazydocker
            else
                curl -sL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
            fi
        else
            curl -sL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
        fi
        
        refresh_path
        if wait_for_command lazydocker; then
            local version=$(lazydocker --version 2>&1 | head -n1 || echo "installed")
            echo "✓ lazydocker installed ($version)"
        else
            echo "✗ lazydocker installed but not in PATH yet. Restart shell."
        fi
    fi
}

install_lazydocker_config() {
    echo ""
    echo "=== lazydocker Configuration ==="
    
    local config_dir="$HOME/.config/lazydocker"
    local config_file="$config_dir/config.yml"
    local source_config="$HOME/dotfiles/lazydocker/config.yml"
    
    # Create config directory if it doesn't exist
    mkdir -p "$config_dir"
    
    # Create symlink
    if [ -L "$config_file" ]; then
        echo "✓ lazydocker config symlink exists"
    else
        [ -f "$config_file" ] && mv "$config_file" "$config_file.backup"
        ln -sf "$source_config" "$config_file"
        echo "✓ Created lazydocker config symlink"
    fi
}
