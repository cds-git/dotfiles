# Master installation script for dotfiles
# Run as Administrator

#Requires -RunAsAdministrator

Write-Host '╔═══════════════════════════════════════╗' -ForegroundColor Cyan
Write-Host '║   Dotfiles Installation Script        ║' -ForegroundColor Cyan
Write-Host '║   Greatest config known to mankind    ║' -ForegroundColor Cyan
Write-Host '╚═══════════════════════════════════════╝' -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir 'modules'

# Utility functions
function Refresh-EnvironmentPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = $machinePath + ';' + $userPath
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Wait-ForCommand {
    param(
        [string]$Command,
        [int]$MaxAttempts = 5,
        [int]$DelaySeconds = 1
    )
    
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        Refresh-EnvironmentPath
        if (Test-CommandExists $Command) {
            return $true
        }
        if ($i -lt $MaxAttempts) {
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    
    return $false
}

Write-Host ''
Write-Host 'Loading modules...' -ForegroundColor Yellow
$modules = @(
    'dev-tools.ps1'
    'bat.ps1'
    'eza.ps1'
    'git.ps1'
    'wezterm.ps1'
    'neovim.ps1'
    'starship.ps1'
    'lazygit.ps1'
    'lazydocker.ps1'
    'yazi.ps1'
    'lazysql.ps1'
    'powershell.ps1'
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
Install-Python
Install-Bat
Install-Eza
Install-Lazydocker
Install-Lazysql
Install-Yazi

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
Install-LazydockerConfig
Install-YaziConfig
Install-PowerShellProfile

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host 'Installation Complete!' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host ''

$existingName = git config --global user.name 2>$null
$existingEmail = git config --global user.email 2>$null

if (-not $existingName) {
    $gitName = Read-Host 'Enter your git user.name'
    if ($gitName) {
        git config --global user.name $gitName
        Write-Host "[OK] Set git user.name to: $gitName" -ForegroundColor Green
    }
} else {
    Write-Host "[OK] Git user.name already set: $existingName" -ForegroundColor Green
}

if (-not $existingEmail) {
    $gitEmail = Read-Host 'Enter your git user.email'
    if ($gitEmail) {
        git config --global user.email $gitEmail
        Write-Host "[OK] Set git user.email to: $gitEmail" -ForegroundColor Green
    }
} else {
    Write-Host "[OK] Git user.email already set: $existingEmail" -ForegroundColor Green
}

Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Yellow
Write-Host '  1. Reload PowerShell profile' -ForegroundColor Cyan
Write-Host '  2. Run git init in repos to install hooks' -ForegroundColor Cyan
