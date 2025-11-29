# WezTerm installation and configuration module

function Install-Wezterm {
    Write-Host "`n=== WezTerm ===" -ForegroundColor Cyan
    
    # Check if already installed
    if (Get-Command wezterm -ErrorAction SilentlyContinue) {
        Write-Host "✓ WezTerm already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing WezTerm..." -ForegroundColor Yellow
        winget install wez.wezterm --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ WezTerm installed" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to install WezTerm" -ForegroundColor Red
        }
    }
    
    # Create symlink (user file needs dot prefix)
    $weztermConfig = "$HOME/.wezterm.lua"
    $dotfilesWezterm = "$HOME/dotfiles/wezterm/wezterm.lua"
    
    if (Test-Path $weztermConfig) {
        $item = Get-Item $weztermConfig
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "✓ WezTerm config symlink exists" -ForegroundColor Green
        } else {
            Write-Host "⚠ Backing up existing config" -ForegroundColor Yellow
            Move-Item $weztermConfig "$weztermConfig.backup"
            New-Item -ItemType SymbolicLink -Force -Path $weztermConfig -Target $dotfilesWezterm | Out-Null
            Write-Host "✓ Created WezTerm config symlink" -ForegroundColor Green
        }
    } else {
        New-Item -ItemType SymbolicLink -Force -Path $weztermConfig -Target $dotfilesWezterm | Out-Null
        Write-Host "✓ Created WezTerm config symlink" -ForegroundColor Green
    }
}

