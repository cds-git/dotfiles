#!/bin/bash
# OpenCode installation and configuration module

install_opencode() {
    echo ""
    echo "=== OpenCode ==="

    if command_exists opencode; then
        echo "✓ OpenCode already installed"
        echo "Checking for a newer OpenCode..."
        if opencode upgrade; then
            echo "✓ OpenCode up to date"
        else
            echo "⚠ OpenCode upgrade failed (continuing)"
        fi
        return 0
    fi

    echo "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
    refresh_path

    if command_exists opencode; then
        echo "✓ OpenCode installed"
    else
        echo "✗ Failed to install OpenCode"
        return 1
    fi
}

install_opencode_config() {
    echo ""
    echo "=== OpenCode Configuration ==="

    local src="$HOME/dotfiles/opencode"
    local dst="$HOME/.config/opencode"

    ensure_link "$src/AGENTS.md"    "$dst/AGENTS.md"    "OpenCode AGENTS.md"
    ensure_link "$src/opencode.json" "$dst/opencode.json" "OpenCode opencode.json"
    ensure_link "$src/tui.json"     "$dst/tui.json"     "OpenCode tui.json"
    ensure_link "$src/skills"       "$dst/skills"       "OpenCode skills"
    ensure_link "$src/agents"       "$dst/agents"       "OpenCode agents"
}
