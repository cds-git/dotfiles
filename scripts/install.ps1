# Ensure the script is run as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator!"
    pause
    exit 1
}

# Update nvim submodule
git submodule update --init --recursive

# Install wezterm
winget install wez.wezterm --accept-source-agreements --accept-package-agreements

# Install starship prompt
winget install Starship.Starship --accept-source-agreements --accept-package-agreements

# Install lazygit
winget install JesseDuffield.lazygit --accept-source-agreements --accept-package-agreements

# Install chocolatey
winget install chocolatey.chocolatey --accept-source-agreements --accept-package-agreements

# Install Neovim
winget install Neovim.Neovim.Nightly --accept-source-agreements --accept-package-agreements

# Ultity for Neovim
winget install BurntSushi.ripgrep.MSVC --accept-source-agreements --accept-package-agreements
winget install fzf --accept-source-agreements --accept-package-agreements
winget install sharkdp.fd --accept-source-agreements --accept-package-agreements
choco install make -y
choco install mingw -y

# Create Symlinks
New-Item -ItemType Directory -Force "$HOME/.config"
New-Item -ItemType SymbolicLink -Force -Path "$HOME/.config/starship.toml" -Target "$HOME/dotfiles/starship/starship.toml"
New-Item -ItemType SymbolicLink -Force -Path "$HOME/.wezterm.lua" -Target "$HOME/dotfiles/wezterm/wezterm.lua"
New-Item -ItemType SymbolicLink -Force -Path "$HOME/AppData/Local/nvim" -Target "$HOME/dotfiles/nvim"

# Add custom profile to the main profile
$dotfilesProfile = "$HOME/dotfiles/powershell/cds_profile.ps1"
# Ensure that the main profile exists.
if (!(Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}
$snippet = @"
# Load custom dotfiles profile
if (Test-Path '$dotfilesProfile') {
    . '$dotfilesProfile'
}
"@
# Check if the custom profile is already in $PROFILE.
if (-not (Select-String -Path $PROFILE -Pattern ([regex]::Escape($dotfilesProfile)) -Quiet)) {
    # Append a new line followed by the snippet
    "`r`n$snippet" | Out-File -Append -Encoding utf8 -FilePath $PROFILE
    Write-Host "Dotfiles profile has been appended to $PROFILE"
    # Reload profile
    . $PROFILE
} else {
    Write-Host "Dotfiles profile already present in $PROFILE"
}

