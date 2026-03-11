#!/bin/bash
# Development environment installation module
# Installs OS-level packages that can't be managed by mise
# Runtimes (dotnet, node) and CLI tools (bat, eza, etc.) are handled by mise

install_common_packages() {
    echo ""
    echo "=== Common Packages ==="

    if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
        local packages=("jq" "curl" "wget" "unzip" "build-essential" "zsh" "tmux" "fastfetch" "htop" "ncdu" "python3" "python3-pip" "gawk")
        sudo apt update
        sudo apt install -y "${packages[@]}"

        # WSL-specific utilities
        if grep -iq Microsoft /proc/version; then
            echo "Detected WSL environment. Installing wslu utilities..."
            sudo add-apt-repository -y ppa:wslutilities/wslu
            sudo apt update
            sudo apt install -y wslu
        fi
    elif [ "$ID" = "arch" ]; then
        sudo pacman -Syu --noconfirm
        local arch_packages=("jq" "curl" "wget" "unzip" "base-devel" "zsh" "tmux" "fastfetch" "htop" "ncdu" "python" "python-pip" "gawk")
        sudo pacman -S --noconfirm "${arch_packages[@]}"

        # Install yay (AUR helper) if not present
        if ! command_exists yay; then
            echo "Installing yay (AUR helper)..."
            local temp_dir=$(mktemp -d)
            git clone https://aur.archlinux.org/yay.git "$temp_dir"
            cd "$temp_dir"
            makepkg -si --noconfirm
            cd - > /dev/null
            rm -rf "$temp_dir"
            echo "✓ yay installed"
        fi
    elif [ "$ID" = "fedora" ]; then
        sudo dnf update -y
        local fedora_packages=("jq" "curl" "unzip" "@development-tools" "zsh" "tmux" "fastfetch" "htop" "ncdu" "python3" "python3-pip" "gawk")
        sudo dnf install -y "${fedora_packages[@]}"
    fi

    echo "✓ Common packages installed"
}
