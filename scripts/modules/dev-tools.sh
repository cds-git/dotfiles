#!/bin/bash
# Development environment installation module
# Includes: .NET SDK, Node.js, common packages

install_common_packages() {
    echo ""
    echo "=== Common Packages ==="
    
    local packages=("ripgrep" "fzf" "fd-find" "jq" "curl" "wget" "unzip" "build-essential" "zsh" "tmux" "fastfetch" "htop" "ncdu" "python3" "python3-pip")
    
    if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
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
        # Adjust package names for Arch (python is python3 by default, pip is python-pip)
        local arch_packages=("ripgrep" "fzf" "fd" "jq" "curl" "wget" "unzip" "base-devel" "zsh" "tmux" "fastfetch" "htop" "ncdu" "python" "python-pip")
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
        # Package names for Fedora
        local fedora_packages=("ripgrep" "fzf" "fd-find" "jq" "curl" "wget" "unzip" "@development-tools" "zsh" "tmux" "fastfetch" "htop" "ncdu" "python3" "python3-pip")
        sudo dnf install -y "${fedora_packages[@]}"
    fi
    
    echo "✓ Common packages installed"
}

install_dotnet() {
    echo ""
    echo "=== .NET SDK ==="
    
    if command_exists dotnet; then
        local current_version=$(dotnet --version)
        echo "Current .NET SDK version: v$current_version"
        echo "Upgrading to latest .NET SDK..."
    else
        echo "Installing latest .NET SDK..."
    fi
    
    if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
        # Add Microsoft package repository
        wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
        sudo dpkg -i /tmp/packages-microsoft-prod.deb
        rm /tmp/packages-microsoft-prod.deb
        
        sudo apt update
        sudo apt install -y dotnet-sdk-10.0
    elif [ "$ID" = "arch" ]; then
        sudo pacman -S --noconfirm dotnet-sdk
    elif [ "$ID" = "fedora" ]; then
        sudo dnf install -y dotnet-sdk-10.0
    fi
    
    local new_version=$(dotnet --version)
    echo "✓ .NET SDK installed (v$new_version)"
}

install_nodejs() {
    echo ""
    echo "=== Node.js (via fnm) ==="
    
    if command_exists fnm; then
        echo "✓ fnm already installed"
    else
        echo "Installing fnm (Fast Node Manager)..."
        curl -fsSL https://fnm.vercel.app/install | bash
        
        # Add fnm to PATH for current session
        export PATH="$HOME/.local/share/fnm:$PATH"
        eval "$(fnm env --use-on-cd)" 2>/dev/null || true
        
        refresh_path
        if wait_for_command fnm; then
            echo "✓ fnm installed"
        else
            echo "✗ fnm installed but not in PATH yet. Restart shell."
            return 1
        fi
    fi
    
    if command_exists node; then
        local version=$(node --version)
        echo "✓ Node.js already installed ($version)"
    else
        echo "Installing Node.js LTS using fnm..."
        
        # Ensure fnm is available
        export PATH="$HOME/.local/share/fnm:$PATH"
        eval "$(fnm env --use-on-cd)" 2>/dev/null || true
        
        fnm install --lts
        fnm use lts-latest
        fnm default lts-latest
        
        refresh_path
        if wait_for_command node; then
            local version=$(node --version)
            echo "✓ Node.js LTS installed and activated ($version)"
        else
            echo "✗ Node.js installed but not in PATH yet. Restart shell."
        fi
    fi
}
