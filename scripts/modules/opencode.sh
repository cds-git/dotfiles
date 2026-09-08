#!/bin/bash
# OpenCode configuration module
# Installation handled by mise (opencode in mise/config.toml)

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
