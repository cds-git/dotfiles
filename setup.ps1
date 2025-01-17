# Ensure the script is run as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator!"
    pause
    exit 1
}

# Install wezterm
winget install wez.wezterm

# Install starship prompt
winget install Starship.Starship

# Install chocolatey
winget install chocolatey.chocolatey

# Install Neovim
winget install Neovim.Neovim

# Ultity for Neovim
winget install BurntSushi.ripgrep.MSVC
winget install fzf
winget install sharkdp.fd
choco install make
choco install mingw

# Zig as a C compiler
winget install zig.zig

# Create Symlinks
New-Item -ItemType Directory -Force ~/.config
New-Item -ItemType SymbolicLink -Path "~/.config/starship.toml" -Target "~/dotfiles/starship/starship.toml"
New-Item -ItemType SymbolicLink -Path "~/.wezterm.lua" -Target "~/dotfiles/wezterm/wezterm.lua"
New-Item -ItemType SymbolicLink -Path "~/AppData/Local/nvim" -Target "~/dotfiles/nvim"

# Get nvim submodule
git submodule update --init --recursive
