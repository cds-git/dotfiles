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
    
    # Install FiraCode Nerd Font
    Install-WeztermFont
}

function Install-WeztermFont {
    Write-Host "`n=== FiraCode Nerd Font ===" -ForegroundColor Cyan
    
    # Check if font is already installed
    $weztermCheck = wezterm ls-fonts --list-system 2>$null | Select-String -Pattern "FiraCode Nerd Font" -Quiet
    if ($weztermCheck) {
        Write-Host "✓ FiraCode Nerd Font already installed" -ForegroundColor Green
        return
    }
    
    Write-Host "Installing FiraCode Nerd Font..." -ForegroundColor Yellow
    
    $downloadUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    $tempZip = "$env:TEMP\FiraCode.zip"
    $tempExtract = "$env:TEMP\FiraCode"
    
    try {
        # Download
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing | Out-Null
        
        # Extract
        Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
        
        # Install to user fonts directory (no admin required)
        $userFontsPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
        if (!(Test-Path $userFontsPath)) {
            New-Item -Path $userFontsPath -ItemType Directory -Force | Out-Null
        }
        
        $fonts = Get-ChildItem "$tempExtract\*.ttf" | Where-Object { $_.Name -notlike "*Windows Compatible*" }
        foreach ($font in $fonts) {
            Copy-Item $font.FullName $userFontsPath -Force
        }
        
        Write-Host "✓ FiraCode Nerd Font installed ($($fonts.Count) fonts)" -ForegroundColor Green
        
        # Cleanup
        Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
        Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "✗ Failed to install font: $($_.Exception.Message)" -ForegroundColor Red
    }
}

