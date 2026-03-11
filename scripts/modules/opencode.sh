#!/bin/bash
# OpenCode configuration module
# Installation handled by mise

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

    # Symlink skills directory
    local skills_dir="$config_dir/skills"
    local dotfiles_skills="$HOME/dotfiles/opencode/skills"

    if [ -L "$skills_dir" ]; then
        echo "✓ OpenCode skills already configured"
    elif [ -d "$skills_dir" ]; then
        echo "⚠ Backing up existing skills directory"
        mv "$skills_dir" "$skills_dir.backup"
        ln -sf "$dotfiles_skills" "$skills_dir"
        echo "✓ OpenCode skills configured"
    else
        ln -sf "$dotfiles_skills" "$skills_dir"
        echo "✓ OpenCode skills configured"
    fi
}
