# Neovim installation and configuration module

function Install-Neovim {
    Write-Host "`n=== Neovim ===" -ForegroundColor Cyan
    
    # Check if already installed
    if (Get-Command nvim -ErrorAction SilentlyContinue) {
        Write-Host "✓ Neovim already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing Neovim..." -ForegroundColor Yellow
        winget install Neovim.Neovim --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Neovim installed" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to install Neovim" -ForegroundColor Red
            return
        }
    }
    
    # Install utilities for Neovim
    Write-Host "Installing Neovim utilities..." -ForegroundColor Yellow
    
    $tools = @(
        @{Name = "ripgrep"; Package = "BurntSushi.ripgrep.MSVC" }
        @{Name = "fzf"; Package = "fzf" }
        @{Name = "fd"; Package = "sharkdp.fd" }
    )
    
    foreach ($tool in $tools) {
        if (Get-Command $tool.Name -ErrorAction SilentlyContinue) {
            Write-Host "  ✓ $($tool.Name) already installed" -ForegroundColor Green
        } else {
            winget install $tool.Package --accept-source-agreements --accept-package-agreements | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Installed $($tool.Name)" -ForegroundColor Green
            }
        }
    }
    
    # Install build tools via choco
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        if (-not (Get-Command make -ErrorAction SilentlyContinue)) {
            choco install make -y | Out-Null
            Write-Host "  ✓ Installed make" -ForegroundColor Green
        }
        if (-not (Get-Command gcc -ErrorAction SilentlyContinue)) {
            choco install mingw -y | Out-Null
            Write-Host "  ✓ Installed mingw" -ForegroundColor Green
        }
    }
    
    # Update nvim submodule
    Write-Host "Updating nvim submodule..." -ForegroundColor Yellow
    Push-Location "$HOME/dotfiles"
    git submodule update --init --recursive 2>&1 | Out-Null
    Pop-Location
    
    # Create symlink
    $nvimConfig = "$HOME/AppData/Local/nvim"
    $dotfilesNvim = "$HOME/dotfiles/nvim"
    
    if (Test-Path $nvimConfig) {
        $item = Get-Item $nvimConfig
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "✓ Neovim config symlink exists" -ForegroundColor Green
        } else {
            Write-Host "⚠ Backing up existing config" -ForegroundColor Yellow
            Move-Item $nvimConfig "$nvimConfig.backup"
            New-Item -ItemType SymbolicLink -Force -Path $nvimConfig -Target $dotfilesNvim | Out-Null
            Write-Host "✓ Created Neovim config symlink" -ForegroundColor Green
        }
    } else {
        New-Item -ItemType SymbolicLink -Force -Path $nvimConfig -Target $dotfilesNvim | Out-Null
        Write-Host "✓ Created Neovim config symlink" -ForegroundColor Green
    }
}

