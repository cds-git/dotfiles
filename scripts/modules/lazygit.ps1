# Lazygit installation and configuration module

function Install-Lazygit {
    Write-Host "`n=== Lazygit ===" -ForegroundColor Cyan
    
    # Check if already installed
    if (Get-Command lazygit -ErrorAction SilentlyContinue) {
        Write-Host "✓ Lazygit already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing Lazygit..." -ForegroundColor Yellow
        winget install JesseDuffield.lazygit --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Lazygit installed" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to install Lazygit" -ForegroundColor Red
            return
        }
    }
    
    # Install delta (for better diffs)
    if (-not (Get-Command delta -ErrorAction SilentlyContinue)) {
        Write-Host "Installing delta..." -ForegroundColor Yellow
        winget install dandavison.delta --accept-source-agreements --accept-package-agreements | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Installed delta" -ForegroundColor Green
        }
    } else {
        Write-Host "✓ Delta already installed" -ForegroundColor Green
    }
    
    # Use AppData\Local (where lazygit actually looks on Windows)
    $lazygitConfigDir = "$HOME/AppData/Local/lazygit"
    if (-not (Test-Path $lazygitConfigDir)) {
        New-Item -ItemType Directory -Force -Path $lazygitConfigDir | Out-Null
    }
    
    # Create symlink
    $lazygitConfig = "$lazygitConfigDir/config.yml"
    $dotfilesLazygit = "$HOME/dotfiles/lazygit/config.yml"
    
    if (Test-Path $lazygitConfig) {
        $item = Get-Item $lazygitConfig
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "✓ Lazygit config symlink exists" -ForegroundColor Green
        } else {
            Write-Host "⚠ Backing up existing config" -ForegroundColor Yellow
            Move-Item $lazygitConfig "$lazygitConfig.backup"
            New-Item -ItemType SymbolicLink -Force -Path $lazygitConfig -Target $dotfilesLazygit | Out-Null
            Write-Host "✓ Created Lazygit config symlink" -ForegroundColor Green
        }
    } else {
        New-Item -ItemType SymbolicLink -Force -Path $lazygitConfig -Target $dotfilesLazygit | Out-Null
        Write-Host "✓ Created Lazygit config symlink" -ForegroundColor Green
    }
}

