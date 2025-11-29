#!/bin/bash

COMMON_PACKAGES=("zsh" "tmux" "unzip" "ripgrep" "fzf" "zoxide" "fd-find" "jq")

command_exists() {
    command -v "$1" &>/dev/null
}

install_common_packages() {
    echo "Installing common packages..."
    if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
        sudo apt update
        sudo apt install -y build-essential "${COMMON_PACKAGES[@]}"
        if ! command_exists eza; then
            echo "Installing eza on Ubuntu..."
            sudo apt install -y cargo
            cargo install eza
        fi
        if grep -iq Microsoft /proc/version; then
            echo "Detected WSL environment. Installing wslu utilities..."
            sudo add-apt-repository -y ppa:wslutilities/wslu
            sudo apt update
            sudo apt install -y wslu
        fi
    elif [ "$ID" = "arch" ]; then
        sudo pacman -Syu --noconfirm
        sudo pacman -S --noconfirm "${COMMON_PACKAGES[@]}" eza
    else
        echo "Unsupported distribution: $ID"
        exit 1
    fi
}

install_starship() {
    if ! command_exists starship; then
        echo "Installing Starship prompt..."
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            curl -sS https://starship.rs/install.sh | sh -s -- --yes
        elif [ "$ID" = "arch" ]; then
            sudo pacman -S --noconfirm starship
        fi
    else
        echo "Starship is already installed."
    fi
}

install_neovim() {
    if ! command_exists nvim; then
        echo "Installing Neovim Nightly..."
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            sudo apt remove -y neovim
            sudo apt install -y software-properties-common
            sudo add-apt-repository -y ppa:neovim-ppa/unstable
            sudo apt update
            sudo apt install -y neovim
        elif [ "$ID" = "arch" ]; then
            sudo pacman -S --noconfirm neovim
        fi
    else
        echo "Neovim is already installed."
    fi
}

install_lazygit() {
    if ! command_exists lazygit; then
        echo "Installing LazyGit..."
        TMP_DIR=$(mktemp -d)
        cd "$TMP_DIR" || exit
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar -xzf lazygit.tar.gz
        sudo install lazygit /usr/local/bin
        cd - || exit
        rm -rf "$TMP_DIR"
        echo "LazyGit version $LAZYGIT_VERSION installed successfully."
    else
        echo "LazyGit is already installed."
    fi
}

install_dotnet() {
    if ! command_exists dotnet; then
        echo "Installing .NET 9 SDK..."
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            sudo add-apt-repository ppa:dotnet/backports
            sudo apt update
            sudo apt install -y dotnet-sdk-9.0
        elif [ "$ID" = "arch" ]; then
            sudo pacman -S --noconfirm dotnet-sdk
        fi
    else
        echo ".NET SDK is already installed."
    fi
}

install_nodejs_fnm() {
    if ! command_exists fnm; then
        echo "Installing FNM (Fast Node Manager)..."
        curl -fsSL https://fnm.vercel.app/install | bash
        source ~/.zshrc
        echo "Installing Node.js LTS using FNM..."
        fnm install --lts
    else
        echo "FNM is already installed."
    fi
}

install_lazydocker() {
    if ! command_exists lazydocker; then
        echo "Installing LazyDocker..."
        TMP_DIR=$(mktemp -d)
        cd "$TMP_DIR" || exit
        LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
        tar -xzf lazydocker.tar.gz
        sudo install lazydocker /usr/local/bin
        cd - || exit
        rm -rf "$TMP_DIR"
        echo "LazyDocker version $LAZYDOCKER_VERSION installed successfully."
    else
        echo "LazyDocker is already installed."
    fi
}

install_lazysql() {
    if ! command_exists lazysql; then
        echo "Installing LazySQL..."
        TMP_DIR=$(mktemp -d)
        cd "$TMP_DIR" || exit
        LAZYSQL_VERSION=$(curl -s "https://api.github.com/repos/lazysql/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazysql.tar.gz "https://github.com/lazysql/releases/download/v${LAZYSQL_VERSION}/lazysql_${LAZYSQL_VERSION}_Linux_x86_64.tar.gz"
        tar -xzf lazysql.tar.gz
        sudo install lazysql /usr/local/bin
        cd - || exit
        rm -rf "$TMP_DIR"
        echo "LazySQL version $LAZYSQL_VERSION installed successfully."
    else
        echo "LazySQL is already installed."
    fi
}

install_fastfetch() {
    if ! command_exists fastfetch; then
        echo "Installing Fastfetch..."
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            sudo add-apt-repository ppa:fastfetch/ppa -y
            sudo apt update
            sudo apt install -y fastfetch
        elif [ "$ID" = "arch" ]; then
            sudo pacman -S --noconfirm fastfetch
        fi
    else
        echo "Fastfetch is already installed."
    fi
}

install_delta() {
    if ! command_exists delta; then
        echo "Installing git-delta..."
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            TMP_DIR=$(mktemp -d)
            cd "$TMP_DIR" || exit
            DELTA_VERSION=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
            curl -Lo delta.deb "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"
            sudo dpkg -i delta.deb
            cd - || exit
            rm -rf "$TMP_DIR"
            echo "Delta ${DELTA_VERSION} installed successfully."
        elif [ "$ID" = "arch" ]; then
            sudo pacman -S --noconfirm git-delta
        fi
    else
        echo "Delta is already installed."
    fi
}

# Install all applications
install_all_applications() {
    echo "Installing all applications..."
    install_common_packages
    install_starship
    install_neovim
    install_lazygit
    install_dotnet
    install_nodejs_fnm
    install_lazydocker
    install_lazysql
    install_fastfetch
    install_delta
}

# Detect the Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    install_all_applications
else
    echo "Cannot detect the OS."
    exit 1
fi

# Setup ZSH as the default shell if not already set
if [ "$SHELL" != "$(command -v zsh)" ]; then
    echo "Setting Zsh as the default shell..."
    chsh -s "$(command -v zsh)"
fi

# Get nvim submodule
git submodule update --init --recursive

# Create symlinks for dotfiles
ln -sf ~/dotfiles/zsh/zshrc ~/.zshrc
ln -sf ~/dotfiles/tmux/tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/nvim ~/.config/nvim
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# Git config setup
gitconfig_path="$HOME/.gitconfig"
dotfiles_git_config="$HOME/dotfiles/git/gitconfig"
skip_gitconfig=false

# Check if ~/.gitconfig already includes our dotfiles
if [ -f "$gitconfig_path" ]; then
    if grep -q "dotfiles/git/gitconfig" "$gitconfig_path"; then
        echo "~/.gitconfig already includes dotfiles config"
        skip_gitconfig=true
    else
        # Backup existing config
        echo "Backing up existing ~/.gitconfig to ~/.gitconfig.backup"
        cp "$gitconfig_path" "$gitconfig_path.backup"
    fi
fi

# Create ~/.gitconfig if it doesn't exist
if [ "$skip_gitconfig" = false ]; then
    cat > "$gitconfig_path" << EOF
# Machine-specific git configuration
# This file is NOT tracked in dotfiles - it's unique per machine

# Include standard settings from dotfiles
[include]
	path = $dotfiles_git_config

# Personal information (REQUIRED - update with your info)
[user]
	name = your-name
	email = your-email@example.com

# Machine-specific settings go below this line
# Examples:
#   [safe]
#       directory = /home/user/admin-repo
#   [core]
#       sshCommand = ssh -i ~/.ssh/work_key
EOF
    
    echo ""
    echo "======================================"
    echo "IMPORTANT: Configure your git identity"
    echo "======================================"
    echo "Edit: ~/.gitconfig"
    echo "Or run: git config --global user.name 'Your Name'"
    echo "     and: git config --global user.email 'your@email.com'"
    echo ""
    echo "You can now safely use 'git config --global' commands!"
    echo "Your dotfiles settings are loaded via [include]"
    echo ""
fi

# Lazygit config symlink
mkdir -p ~/.config/lazygit
ln -sf ~/dotfiles/lazygit/config.yml ~/.config/lazygit/config.yml

source ~/.zshrc
echo "Setup completed successfully."
