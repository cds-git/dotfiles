#!/bin/bash
# Git configuration setup module

install_git_config() {
    echo ""
    echo "=== Git Configuration ===" 
    
    local gitconfig_path="$HOME/.gitconfig"
    local dotfiles_git_config="$HOME/dotfiles/git/gitconfig"
    
    # Check if ~/.gitconfig already includes our dotfiles
    if [ -f "$gitconfig_path" ]; then
        if grep -q "dotfiles/git/gitconfig" "$gitconfig_path"; then
            echo "✓ Git config already set up"
            return
        else
            # Backup existing config
            echo "⚠ Backing up existing ~/.gitconfig"
            cp "$gitconfig_path" "$gitconfig_path.backup"
        fi
    fi
    
    # Create ~/.gitconfig
    cat > "$gitconfig_path" << EOF
# Machine-specific git configuration
# This file is NOT tracked in dotfiles

# Include standard settings from dotfiles
[include]
	path = $dotfiles_git_config

# Personal information (REQUIRED)
[user]
	name = your-name
	email = your-email@example.com

# Machine-specific settings
# Examples:
#   [safe]
#       directory = /home/user/admin-repo
#   [core]
#       sshCommand = ssh -i ~/.ssh/work_key
EOF
    
    echo "✓ Created ~/.gitconfig"
    echo ""
    echo "⚠ Configure your identity:"
    echo "  git config --global user.name 'Your Name'"
    echo "  git config --global user.email 'your@email.com'"
}

install_git_hooks() {
    echo ""
    echo "=== Git Hooks ==="
    
    local templates_dir="$HOME/.git-templates/hooks"
    local dotfiles_hooks_dir="$HOME/dotfiles/git/hooks"
    
    mkdir -p "$templates_dir"
    
    local source_hook="$dotfiles_hooks_dir/commit-msg"
    local target_hook="$templates_dir/commit-msg"
    
    if [ ! -f "$source_hook" ]; then
        echo "✗ Hook not found: $source_hook"
        return 1
    fi
    
    # Copy hook and make executable
    if [ -f "$target_hook" ]; then
        echo "⚠ Updating existing hook"
    fi
    
    cp "$source_hook" "$target_hook"
    chmod +x "$target_hook"
    echo "✓ Installed commit-msg hook"
    
    git config --global init.templatedir "$HOME/.git-templates"
    
    echo "✓ Configured git template directory"
    echo "  Example: feature/ABC-123-fix → Commit: 'ABC-123: fix bug'"
}
