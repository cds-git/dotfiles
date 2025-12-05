#!/bin/bash
# OpenCode installation and configuration module

install_opencode() {
    echo ""
    echo "=== OpenCode ==="
    
    if command_exists opencode; then
        echo "✓ OpenCode already installed"
    else
        echo "Installing OpenCode..."
        # Use official install script (downloads pre-built binary, distro-independent)
        curl -fsSL https://opencode.ai/install | bash
        
        if wait_for_command opencode; then
            echo "✓ OpenCode installed"
        else
            echo "✗ OpenCode installed but not in PATH yet. Restart shell."
        fi
    fi
}

install_opencode_config() {
    echo ""
    echo "=== OpenCode Configuration ==="
    
    local config_dir="$HOME/.config/opencode"
    mkdir -p "$config_dir"
    
    # Symlink AGENTS.md
    local agents_file="$config_dir/AGENTS.md"
    local dotfiles_agents="$HOME/dotfiles/opencode/AGENTS.md"
    
    if [ -L "$agents_file" ]; then
        echo "✓ OpenCode AGENTS.md already configured"
    elif [ -f "$agents_file" ]; then
        echo "⚠ Backing up existing AGENTS.md"
        mv "$agents_file" "$agents_file.backup"
        ln -sf "$dotfiles_agents" "$agents_file"
        echo "✓ OpenCode AGENTS.md configured"
    else
        ln -sf "$dotfiles_agents" "$agents_file"
        echo "✓ OpenCode AGENTS.md configured"
    fi
    
    # Symlink opencode.json
    local config_file="$config_dir/opencode.json"
    local dotfiles_config="$HOME/dotfiles/opencode/opencode.json"
    
    if [ -L "$config_file" ]; then
        echo "✓ OpenCode opencode.json already configured"
    elif [ -f "$config_file" ]; then
        echo "⚠ Backing up existing opencode.json"
        mv "$config_file" "$config_file.backup"
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ OpenCode opencode.json configured"
    else
        ln -sf "$dotfiles_config" "$config_file"
        echo "✓ OpenCode opencode.json configured"
    fi
}
