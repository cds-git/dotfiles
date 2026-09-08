# bat (syntax highlighter) installation module

function Install-Bat {
    Write-Host "`n=== bat (Syntax Highlighter) ===" -ForegroundColor Cyan

    if (-not (Install-WingetPackage -Id 'sharkdp.bat' -Label 'bat')) {
        return
    }

    # Catppuccin Mocha theme - also referenced by delta's syntax-theme and
    # yazi's syntect_theme, so it has to be registered in bat's cache.
    $batConfigDir = "$env:APPDATA\bat\themes"
    $themeFile = "$batConfigDir\Catppuccin Mocha.tmTheme"

    if (Test-Path $themeFile) {
        Write-Host "[OK] Catppuccin Mocha theme already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing Catppuccin Mocha theme..." -ForegroundColor Yellow
        if (-not (Test-Path $batConfigDir)) {
            New-Item -ItemType Directory -Force -Path $batConfigDir | Out-Null
        }

        $themeUrl = 'https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme'
        try {
            Invoke-WebRequest -Uri $themeUrl -OutFile $themeFile
            Write-Host "[OK] Catppuccin Mocha theme installed" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to download theme: $_" -ForegroundColor Red
            return
        }
    }

    Write-Host "Building bat cache..." -ForegroundColor Yellow
    try {
        if (Test-CommandExists 'bat') {
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

    Ensure-Link "$HOME\dotfiles\bat\config" "$env:APPDATA\bat\config" 'bat config'
}
