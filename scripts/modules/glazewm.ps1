# GlazeWM installation and configuration module

function Install-GlazeWM {
    Write-Host "`n=== GlazeWM ===" -ForegroundColor Cyan

    # Check if already installed
    if (Get-Command glazewm -ErrorAction SilentlyContinue) {
        Write-Host "[OK] GlazeWM already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing GlazeWM..." -ForegroundColor Yellow
        winget install glzr-io.glazewm --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] GlazeWM installed" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Failed to install GlazeWM" -ForegroundColor Red
        }
    }

    # Create symlink for config (GlazeWM reads ~/.glzr/glazewm/config.yaml)
    $glazeConfig = "$HOME/.glzr/glazewm/config.yaml"
    $dotfilesGlaze = "$HOME/dotfiles/glazewm/config.yaml"
    $glazeConfigDir = Split-Path -Parent $glazeConfig

    if (!(Test-Path $glazeConfigDir)) {
        New-Item -ItemType Directory -Force -Path $glazeConfigDir | Out-Null
    }

    if (Test-Path $glazeConfig) {
        $item = Get-Item $glazeConfig
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "[OK] GlazeWM config symlink exists" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Backing up existing config" -ForegroundColor Yellow
            Move-Item $glazeConfig "$glazeConfig.backup"
            New-Item -ItemType SymbolicLink -Force -Path $glazeConfig -Target $dotfilesGlaze | Out-Null
            Write-Host "[OK] Created GlazeWM config symlink" -ForegroundColor Green
        }
    } else {
        New-Item -ItemType SymbolicLink -Force -Path $glazeConfig -Target $dotfilesGlaze | Out-Null
        Write-Host "[OK] Created GlazeWM config symlink" -ForegroundColor Green
    }

    # Zebar is the companion status bar referenced in startup_commands
    Install-Zebar
}

function Install-Zebar {
    Write-Host "`n=== Zebar ===" -ForegroundColor Cyan

    if (Get-Command zebar -ErrorAction SilentlyContinue) {
        Write-Host "[OK] Zebar already installed" -ForegroundColor Green
        return
    }

    Write-Host "Installing Zebar..." -ForegroundColor Yellow
    winget install glzr-io.zebar --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Zebar installed" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Failed to install Zebar" -ForegroundColor Red
    }
}
