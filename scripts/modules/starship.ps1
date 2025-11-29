# Starship prompt installation and configuration module

function Install-Starship {
    Write-Host "`n=== Starship ===" -ForegroundColor Cyan
    
    # Check if already installed
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Write-Host "✓ Starship already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing Starship..." -ForegroundColor Yellow
        winget install Starship.Starship --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Starship installed" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to install Starship" -ForegroundColor Red
            return
        }
    }
    
    # Create .config directory if it doesn't exist
    $configDir = "$HOME/.config"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Force -Path $configDir | Out-Null
    }
    
    # Create symlink (no dot prefix needed for .config/)
    $starshipConfig = "$configDir/starship.toml"
    $dotfilesStarship = "$HOME/dotfiles/starship/starship.toml"
    
    if (Test-Path $starshipConfig) {
        $item = Get-Item $starshipConfig
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "✓ Starship config symlink exists" -ForegroundColor Green
        } else {
            Write-Host "⚠ Backing up existing config" -ForegroundColor Yellow
            Move-Item $starshipConfig "$starshipConfig.backup"
            New-Item -ItemType SymbolicLink -Force -Path $starshipConfig -Target $dotfilesStarship | Out-Null
            Write-Host "✓ Created Starship config symlink" -ForegroundColor Green
        }
    } else {
        New-Item -ItemType SymbolicLink -Force -Path $starshipConfig -Target $dotfilesStarship | Out-Null
        Write-Host "✓ Created Starship config symlink" -ForegroundColor Green
    }
}

