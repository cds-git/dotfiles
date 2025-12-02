# PowerShell Profile

# Editor aliases
Set-Alias vim nvim
Set-Alias vi nvim
Set-Alias v nvim

# Git aliases
Set-Alias lg lazygit

# Kubernetes alias
Set-Alias k kubectl

# Modern CLI tool aliases (remove built-in aliases and create functions)
Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
function cat { bat $args }
function ls { eza --icons $args }

# Initialize Starship prompt
Invoke-Expression (&starship init powershell)
