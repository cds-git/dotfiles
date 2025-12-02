# Development tools installation module

function Install-Chocolatey {
    Write-Host "`n=== Chocolatey Package Manager ===" -ForegroundColor Cyan
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "[OK] Chocolatey already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
        winget install chocolatey.chocolatey --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Chocolatey installed" -ForegroundColor Green
            Write-Host "[WARN] You may need to restart your terminal" -ForegroundColor Yellow
        } else {
            Write-Host "[ERROR] Failed to install Chocolatey" -ForegroundColor Red
        }
    }
}

function Install-DotNetSDK {
    Write-Host "`n=== .NET SDK ===" -ForegroundColor Cyan
    
    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        $version = dotnet --version
        Write-Host "[OK] .NET SDK already installed (v$version)" -ForegroundColor Green
    } else {
        Write-Host "Installing .NET SDK..." -ForegroundColor Yellow
        winget install Microsoft.DotNet.SDK.10 --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] .NET SDK installed" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to install .NET SDK" -ForegroundColor Red
        }
    }
}

function Install-NodeJS {
    Write-Host "`n=== Node.js (via nvm-windows) ===" -ForegroundColor Cyan
    
    # Ensure chocolatey is installed
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] Chocolatey is required but not installed" -ForegroundColor Red
        Write-Host "  Run Install-Chocolatey first" -ForegroundColor Yellow
        return
    }
    
    # Check if nvm is installed
    if (Get-Command nvm -ErrorAction SilentlyContinue) {
        Write-Host "[OK] nvm-windows already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing nvm-windows via Chocolatey..." -ForegroundColor Yellow
        choco install nvm -y
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] nvm-windows installed" -ForegroundColor Green
            Write-Host "[WARN] Restart your terminal to use nvm" -ForegroundColor Yellow
        } else {
            Write-Host "[ERROR] Failed to install nvm-windows" -ForegroundColor Red
            return
        }
    }
    
    # Check if Node.js is installed
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $version = node --version
        Write-Host "[OK] Node.js already installed ($version)" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Install Node.js with: nvm install lts" -ForegroundColor Yellow
        Write-Host "  Then activate with: nvm use lts" -ForegroundColor Yellow
    }
}

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
        # Need to find bat in PATH or use full path after installation
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

function Install-Eza {
    Write-Host "`n=== eza (Modern ls) ===" -ForegroundColor Cyan
    
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        $version = eza --version | Select-Object -First 1
        Write-Host "[OK] eza already installed ($version)" -ForegroundColor Green
    } else {
        Write-Host "Installing eza..." -ForegroundColor Yellow
        winget install eza-community.eza --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] eza installed" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to install eza" -ForegroundColor Red
        }
    }
}

function Install-Yazi {
    Write-Host "`n=== yazi (Terminal File Manager) ===" -ForegroundColor Cyan
    
    if (Get-Command yazi -ErrorAction SilentlyContinue) {
        $version = yazi --version
        Write-Host "[OK] yazi already installed ($version)" -ForegroundColor Green
    } else {
        Write-Host "Installing yazi..." -ForegroundColor Yellow
        winget install sxyazi.yazi --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] yazi installed" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to install yazi" -ForegroundColor Red
        }
    }
}

function Install-OpenCode {
    Write-Host "`n=== OpenCode ===" -ForegroundColor Cyan
    
    if (Get-Command opencode -ErrorAction SilentlyContinue) {
        Write-Host "[OK] OpenCode already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing OpenCode..." -ForegroundColor Yellow
        npm install -g @opencode/cli
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] OpenCode installed" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to install OpenCode" -ForegroundColor Red
        }
    }
}
