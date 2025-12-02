# Master installation script for dotfiles
# Run as Administrator

#Requires -RunAsAdministrator

Write-Host '╔═══════════════════════════════════════╗' -ForegroundColor Cyan
Write-Host '║   Dotfiles Installation Script        ║' -ForegroundColor Cyan
Write-Host '║   Greatest config known to mankind    ║' -ForegroundColor Cyan
Write-Host '╚═══════════════════════════════════════╝' -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir 'modules'

Write-Host ''
Write-Host 'Loading modules...' -ForegroundColor Yellow
$modules = @(
    'git.ps1'
    'wezterm.ps1'
    'neovim.ps1'
    'starship.ps1'
    'lazygit.ps1'
    'yazi.ps1'
    'opencode.ps1'
    'powershell.ps1'
    'dev-tools.ps1'
)

foreach ($module in $modules) {
    $modulePath = Join-Path $ModulesDir $module
    if (Test-Path $modulePath) {
        . $modulePath
        Write-Host ('  Loaded ' + $module) -ForegroundColor Green
    } else {
        Write-Host ('  Missing ' + $module) -ForegroundColor Red
    }
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'Starting installation...' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan

Write-Host ''
Write-Host '--- Development Tools ---' -ForegroundColor Magenta
Install-Chocolatey
Install-DotNetSDK
Install-NodeJS
Install-Bat
Install-Eza
Install-Yazi
Install-OpenCode

Write-Host ''
Write-Host '--- Terminal and Utilities ---' -ForegroundColor Magenta
Install-Wezterm
Install-Starship
Install-Lazygit
Install-Neovim

Write-Host ''
Write-Host '--- Configurations ---' -ForegroundColor Magenta
Install-GitConfig
Install-GitHooks
Install-BatConfig
Install-YaziConfig
Install-OpenCodeConfig
Install-PowerShellProfile

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host 'Installation Complete!' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Yellow
Write-Host '  1. Configure git identity' -ForegroundColor Cyan
Write-Host '  2. Reload PowerShell profile' -ForegroundColor Cyan
Write-Host '  3. Run git init in repos to install hooks' -ForegroundColor Cyan
