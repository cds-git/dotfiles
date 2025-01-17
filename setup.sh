#!/bin/bash

# List of common packages for both Ubuntu and Arch
COMMON_PACKAGES=("zsh" "tmux" "unzip" "ripgrep" "fzf" "zoxide" "fd-find" "jq")

# Helper functions
install_common_packages_ubuntu() {
  echo "Installing build-essential on Ubuntu..."
  sudo apt update
  sudo apt install -y build-essential

  echo "Installing common packages on Ubuntu/Debian-based distribution."
  sudo apt install -y "${COMMON_PACKAGES[@]}"

  # Install eza (modern ls replacement)
  if ! command_exists eza; then
    echo "Installing eza on Ubuntu..."
    sudo apt install -y cargo
    cargo install eza
  fi

  # Check if running under WSL and install wslu if needed
  if grep -iq Microsoft /proc/version; then
    echo "Detected WSL environment. Installing wslu utilities..."
    sudo add-apt-repository -y ppa:wslutilities/wslu
    sudo apt update
    sudo apt install -y wslu
  fi
}

install_common_packages_arch() {
  echo "Installing common packages on Arch-based distribution."
  sudo pacman -Syu --noconfirm
  sudo pacman -S --noconfirm "${COMMON_PACKAGES[@]}" eza
}

# Check if a command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Install starship
install_starship_ubuntu() {
  if ! command_exists starship; then
    echo "Installing Starship prompt on Ubuntu..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  else
    echo "Starship is already installed."
  fi
}

install_starship_arch() {
  if ! command_exists starship; then
    echo "Installing Starship prompt on Arch..."
    sudo pacman -S --noconfirm starship
  else
    echo "Starship is already installed."
  fi
}

# Install Neovim Nightly
install_neovim_ubuntu() {
  if ! command_exists nvim; then
    echo "Installing Neovim Nightly on Ubuntu..."
    sudo apt remove -y neovim  # Remove stable version if exists
    sudo apt install -y software-properties-common
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt update
    sudo apt install -y neovim
  else
    echo "Neovim is already installed."
  fi
}

install_neovim_arch() {
  if ! command_exists nvim; then
    echo "Installing Neovim Nightly on Arch..."
    sudo pacman -S --noconfirm neovim
  else
    echo "Neovim is already installed."
  fi
}

# Install lazygit on Ubuntu using GitHub releases
install_lazygit_ubuntu() {
  if ! command_exists lazygit; then
    echo "Installing LazyGit on Ubuntu using GitHub releases..."

    # Create a temporary directory for the download
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR" || exit

    # Get the latest version of lazygit
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')

    # Download and extract the correct tar.gz file
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    
    # Extract the tarball
    tar -xzf lazygit.tar.gz
    
    # Install lazygit
    sudo install lazygit /usr/local/bin

    # Clean up temporary files
    cd - || exit
    rm -rf "$TMP_DIR"
    
    echo "LazyGit version $LAZYGIT_VERSION installed successfully."
  else
    echo "LazyGit is already installed."
  fi
}


# Install lazygit on Arch
install_lazygit_arch() {
  if ! command_exists lazygit; then
    echo "Installing LazyGit on Arch..."
    sudo pacman -S --noconfirm lazygit
  else
    echo "LazyGit is already installed."
  fi
}

# create the .config directory
mkdir ~/.config

# Detect the Linux distribution
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    ubuntu|debian)
      install_common_packages_ubuntu
      install_starship_ubuntu
      install_neovim_ubuntu
      install_lazygit_ubuntu
      ;;
    arch)
      install_common_packages_arch
      install_starship_arch
      install_neovim_arch
      install_lazygit_arch
      ;;
    *)
      echo "Unsupported distribution: $ID"
      exit 1
      ;;
  esac
else
  echo "Cannot detect the OS."
  exit 1
fi

# Setup ZSH as the default shell if not already set
if [ "$SHELL" != "$(command -v zsh)" ]; then
  echo "Setting Zsh as the default shell..."
  chsh -s "$(command -v zsh)"
fi

# Create symlinks for dotfiles
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/tmux/tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/nvim ~/.config/nvim
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# Get nvim submodule
git submodule update --init --recursive

echo "Setup completed successfully."

