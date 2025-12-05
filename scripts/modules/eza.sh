#!/bin/bash
# eza (modern ls) installation module

install_eza() {
    echo ""
    echo "=== eza (Modern ls) ==="
    
    if command_exists eza; then
        local version=$(eza --version | head -n1)
        echo "✓ eza already installed ($version)"
    else
        echo "Installing eza..."
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            # Install from cargo if not available in apt
            if ! sudo apt install -y eza 2>/dev/null; then
                if ! command_exists cargo; then
                    sudo apt install -y cargo
                fi
                cargo install eza
            fi
        elif [ "$ID" = "arch" ]; then
            sudo pacman -S --noconfirm eza
        elif [ "$ID" = "fedora" ]; then
            # eza not in default repos, use cargo
            if ! command_exists cargo; then
                sudo dnf install -y cargo
            fi
            cargo install eza
        fi
        echo "✓ eza installed"
    fi
}
