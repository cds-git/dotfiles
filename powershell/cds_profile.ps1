# PowerShell Profile
#
# Every section is guarded: `install.ps1` without --tools installs none of
# these, and an unguarded `starship init` would throw on every shell launch.

# Editor aliases
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias vim nvim
    Set-Alias vi nvim
    Set-Alias v nvim
}

# Git
if (Get-Command lazygit -ErrorAction SilentlyContinue) {
    Set-Alias lg lazygit
}

# Kubernetes
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    Set-Alias k kubectl
}

# Modern CLI tools (replace the built-in ls alias with eza)
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function ls { eza --icons $args }
    function ll { eza --icons -lha $args }
}

# Prompt
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
