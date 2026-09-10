# Master installation script for dotfiles
# Run as Administrator
#
# Usage:
#   .\scripts\install.ps1                Windows Terminal config + WSL setup
#   .\scripts\install.ps1 --tools        ...plus the full CLI/dev toolchain
#   .\scripts\install.ps1 --twm          ...plus GlazeWM + Zebar
#   .\scripts\install.ps1 --tools --twm  both
#   .\scripts\install.ps1 --all          everything
#
# The default is deliberately small: if the actual work happens in WSL, all
# Windows needs is a themed terminal and a working distro. Everything else is
# opt-in.

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [switch]$Tools,
    [switch]$Twm,
    [switch]$All,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

# PowerShell binds -Tools natively; accept GNU-style --tools too, since that
# is how these are documented and how they get typed in practice.
foreach ($arg in $ExtraArgs) {
    switch ($arg.ToLowerInvariant()) {
        '--tools' { $Tools = $true }
        '--twm' { $Twm = $true }
        '--all' { $All = $true }
        '--help' { $Help = $true }
        '-h' { $Help = $true }
        default {
            Write-Host "Unknown option: $arg" -ForegroundColor Red
            $Help = $true
        }
    }
}

if ($All) { $Tools = $true; $Twm = $true }

if ($Help) {
    Write-Host ''
    Write-Host 'Usage: .\scripts\install.ps1 [--tools] [--twm] [--all]' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  (no flags)  Windows Terminal + its Catppuccin config, and WSL setup' -ForegroundColor Gray
    Write-Host '  --tools     .NET/Node/Python, bat, eza, yazi, neovim, starship,' -ForegroundColor Gray
    Write-Host '              lazygit, lazydocker, lazysql, git config, PS profile' -ForegroundColor Gray
    Write-Host '  --twm       GlazeWM + Zebar tiling window manager' -ForegroundColor Gray
    Write-Host '  --all       everything above' -ForegroundColor Gray
    Write-Host ''
    exit 0
}

Write-Host '=========================================' -ForegroundColor Cyan
Write-Host '   Dotfiles Installation Script' -ForegroundColor Cyan
Write-Host '   Greatest config known to mankind' -ForegroundColor Cyan
Write-Host '=========================================' -ForegroundColor Cyan

$selected = @('windows terminal + wsl')
if ($Tools) { $selected += 'tools' }
if ($Twm) { $selected += 'twm' }
Write-Host ''
Write-Host ('Selected: ' + ($selected -join ', ')) -ForegroundColor Yellow
if (-not $Tools -and -not $Twm) {
    Write-Host 'Add --tools and/or --twm for more (--help to see what they cover)' -ForegroundColor Gray
}

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

function Test-Elevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Point a config path at a file/dir in the dotfiles repo.
#
# Unlike a bare LinkType check, this verifies where an existing symlink
# actually points and re-links it if it has drifted, so re-running the
# installer repairs the link instead of reporting "already exists".
function Ensure-Link {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$Label
    )

    if (-not (Test-Path $Source)) {
        Write-Host "[FAIL] $Label : missing in dotfiles ($Source)" -ForegroundColor Red
        return
    }

    $resolvedSource = (Resolve-Path $Source).Path

    if (Test-Path $Target) {
        $item = Get-Item $Target -Force
        if ($item.LinkType -eq 'SymbolicLink') {
            $current = [string]($item.Target | Select-Object -First 1)
            if ($current) {
                $a = $current.TrimEnd('\', '/')
                $b = $resolvedSource.TrimEnd('\', '/')
                if ($a -ieq $b) {
                    Write-Host "[OK] $Label already linked" -ForegroundColor Green
                    return
                }
            }
            Write-Host "[WARN] $Label pointed at $current - re-linking" -ForegroundColor Yellow
        }
    }

    # Creating a symlink needs elevation (or Developer Mode). Check BEFORE
    # touching what is already there: New-Item -Force deletes the target
    # first, so a failed privilege check would leave nothing behind.
    if (-not (Test-Elevated)) {
        Write-Host "[SKIP] $Label needs an elevated shell to create the symlink" -ForegroundColor Yellow
        Write-Host "       Re-run this script as Administrator" -ForegroundColor Yellow
        return
    }

    $parent = Split-Path -Parent $Target
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    if (Test-Path $Target) {
        $item = Get-Item $Target -Force
        if ($item.LinkType -eq 'SymbolicLink') {
            # .Delete() removes the link itself; Remove-Item on a directory
            # symlink can recurse into the target's contents.
            $item.Delete()
        } else {
            Write-Host "[WARN] $Label exists as a real file - backing up to $Target.backup" -ForegroundColor Yellow
            Move-Item -Force $Target "$Target.backup"
        }
    }

    New-Item -ItemType SymbolicLink -Force -Path $Target -Target $resolvedSource | Out-Null
    Write-Host "[OK] $Label linked" -ForegroundColor Green
}

# Install a winget package, or upgrade it when it is already present.
#
# `winget install` on an already-installed package reports "already installed"
# and does nothing, so modules that only called it on the not-installed branch
# could never move a version forward.
function Install-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Label
    )

    $listed = winget list --id $Id --exact 2>$null | Select-String -SimpleMatch $Id

    if ($listed) {
        Write-Host "$Label already installed - checking for a newer version..." -ForegroundColor Yellow
        # Exits non-zero when no update is available, which is not an error.
        winget upgrade --id $Id --exact --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        Refresh-EnvironmentPath
        Write-Host "[OK] $Label up to date" -ForegroundColor Green
        return $true
    }

    Write-Host "Installing $Label..." -ForegroundColor Yellow
    # Out-Host, not bare: an external command's stdout would otherwise be
    # added to this function's output and corrupt the boolean return value.
    winget install --id $Id --exact --accept-source-agreements --accept-package-agreements | Out-Host
    if ($LASTEXITCODE -eq 0) {
        Refresh-EnvironmentPath
        Write-Host "[OK] $Label installed" -ForegroundColor Green
        return $true
    }

    Write-Host "[FAIL] Failed to install $Label" -ForegroundColor Red
    return $false
}

# Install or upgrade a Chocolatey package.
#
# `choco upgrade` installs a missing package and upgrades an installed one,
# so it is the idempotent-and-updating form of `choco install`.
function Install-ChocoPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Label
    )

    if (-not (Test-CommandExists 'choco')) {
        Write-Host "[FAIL] Chocolatey is required for $Label but is not installed" -ForegroundColor Red
        Write-Host "       Run Install-Chocolatey first" -ForegroundColor Yellow
        return $false
    }

    Write-Host "Installing/upgrading $Label via Chocolatey..." -ForegroundColor Yellow
    choco upgrade $Id -y | Out-Host
    if ($LASTEXITCODE -eq 0) {
        Refresh-EnvironmentPath
        Write-Host "[OK] $Label installed and up to date" -ForegroundColor Green
        return $true
    }

    Write-Host "[FAIL] Failed to install $Label" -ForegroundColor Red
    return $false
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

# Load only the modules the selected groups need.
$modules = @('windows-terminal.ps1', 'wsl.ps1')

if ($Tools) {
    $modules += @(
        'dev-tools.ps1'
        'bat.ps1'
        'eza.ps1'
        'git.ps1'
        'neovim.ps1'
        'starship.ps1'
        'lazygit.ps1'
        'lazydocker.ps1'
        'yazi.ps1'
        'lazysql.ps1'
        'powershell.ps1'
    )
}

if ($Twm) {
    $modules += 'glazewm.ps1'
    $modules += 'powertoys.ps1'
}

Write-Host ''
Write-Host 'Loading modules...' -ForegroundColor Yellow
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

# --- Always: the terminal and a working WSL ---
Write-Host ''
Write-Host '--- Terminal ---' -ForegroundColor Magenta
Install-WindowsTerminal

Write-Host ''
Write-Host '--- WSL ---' -ForegroundColor Magenta
Install-WslSetup

# --- Optional: the full Windows-side toolchain ---
if ($Tools) {
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
    # The PS profile initializes starship and aliases eza/nvim/lazygit, so it
    # is only safe to install once --tools has provided them.
    Install-PowerShellProfile
}

# --- Optional: tiling window manager ---
if ($Twm) {
    Write-Host ''
    Write-Host '--- Tiling Window Manager ---' -ForegroundColor Magenta
    Install-GlazeWM
    # PowerToys rides along with the WM: AlwaysOnTop covers GlazeWM's broken
    # shown_on_top, and PowerToys Run is the application launcher.
    Install-PowerToys
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host 'Installation Complete!' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green

# Git identity only matters if git is being used on the Windows side.
if ($Tools) {
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
}

Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Yellow
Write-Host '  1. Restart Windows Terminal to pick up the config' -ForegroundColor Cyan
if ($Tools) {
    Write-Host '  2. Reload PowerShell profile' -ForegroundColor Cyan
    Write-Host '  3. Run git init in repos to install hooks' -ForegroundColor Cyan
}
