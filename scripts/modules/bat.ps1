# bat (syntax highlighter) installation module

function Install-Bat {
    Write-Host "`n=== bat (Syntax Highlighter) ===" -ForegroundColor Cyan
    
    if (Get-Command bat -ErrorAction SilentlyContinue) {
        $version = bat --version
        Write-Host "[OK] bat already installed ($version)" -ForegroundColor Green
    } else {
        Write-Host "Installing bat..." -ForegroundColor Yellow
        winget install sharkdp.bat --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] bat installed" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to install bat" -ForegroundColor Red
            return
        }
    }
    
    # Install Catppuccin theme
    $batConfigDir = "$env:APPDATA\bat\themes"
    $themeFile = "$batConfigDir\Catppuccin Mocha.tmTheme"
    
    if (Test-Path $themeFile) {
        Write-Host "[OK] Catppuccin Mocha theme already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing Catppuccin Mocha theme..." -ForegroundColor Yellow
        if (-not (Test-Path $batConfigDir)) {
            New-Item -ItemType Directory -Force -Path $batConfigDir | Out-Null
        }
        
        $themeUrl = "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme"
        try {
            Invoke-WebRequest -Uri $themeUrl -OutFile $themeFile
            Write-Host "[OK] Catppuccin Mocha theme installed" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to download theme: $_" -ForegroundColor Red
            return
        }
    }
    
    # Build bat cache to register themes
    Write-Host "Building bat cache..." -ForegroundColor Yellow
    try {
        $batExe = Get-Command bat -ErrorAction SilentlyContinue
        if ($batExe) {
            & bat cache --build | Out-Null
            Write-Host "[OK] bat cache built successfully" -ForegroundColor Green
        } else {
            Write-Host "[WARN] bat not in PATH yet. Run 'bat cache --build' after restarting terminal" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARN] Could not build bat cache. Run 'bat cache --build' after restarting terminal" -ForegroundColor Yellow
    }
}

function Install-BatConfig {
    Write-Host "`n=== bat Configuration ===" -ForegroundColor Cyan
    
    $dotfilesRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    $source = Join-Path $dotfilesRoot 'bat\config'
    $target = "$env:APPDATA\bat\config"
    $targetDir = Split-Path $target -Parent
    
    if (-not (Test-Path $targetDir)) {
        Write-Host "Creating bat config directory..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }
    
    if (Test-Path $target) {
        if ((Get-Item $target).LinkType -eq 'SymbolicLink') {
            Write-Host "[OK] bat config already symlinked" -ForegroundColor Green
        } else {
            Write-Host "[WARN] bat config exists but is not a symlink" -ForegroundColor Yellow
            Write-Host "  Backing up existing config..." -ForegroundColor Yellow
            Move-Item $target "$target.backup" -Force
            New-Item -ItemType SymbolicLink -Path $target -Target $source -Force | Out-Null
            Write-Host "[OK] bat config symlinked (old config backed up)" -ForegroundColor Green
        }
    } else {
        Write-Host "Creating symlink for bat config..." -ForegroundColor Yellow
        New-Item -ItemType SymbolicLink -Path $target -Target $source -Force | Out-Null
        Write-Host "[OK] bat config symlinked" -ForegroundColor Green
    }
}
