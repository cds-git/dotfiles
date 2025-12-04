# lazydocker installation module

function Install-Lazydocker {
    Write-Host "`n=== lazydocker (Docker TUI) ===" -ForegroundColor Cyan
    
    if (Test-CommandExists 'lazydocker') {
        try {
            $version = lazydocker --version 2>&1 | Select-Object -First 1
            Write-Host "[OK] lazydocker already installed ($version)" -ForegroundColor Green
        } catch {
            Write-Host "[OK] lazydocker already installed" -ForegroundColor Green
        }
    } else {
        Write-Host "Installing lazydocker..." -ForegroundColor Yellow
        
        # Ensure chocolatey is installed
        if (-not (Test-CommandExists 'choco')) {
            Write-Host "[ERROR] Chocolatey is required but not installed" -ForegroundColor Red
            Write-Host "  Run Install-Chocolatey first" -ForegroundColor Yellow
            return
        }
        
        choco install lazydocker -y
        
        if ($LASTEXITCODE -eq 0) {
            Refresh-EnvironmentPath
            if (Wait-ForCommand -Command 'lazydocker') {
                try {
                    $version = lazydocker --version 2>&1 | Select-Object -First 1
                    Write-Host "[OK] lazydocker installed ($version)" -ForegroundColor Green
                } catch {
                    Write-Host "[OK] lazydocker installed" -ForegroundColor Green
                }
            } else {
                Write-Host "[WARN] lazydocker installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
            }
        } else {
            Write-Host "[ERROR] Failed to install lazydocker" -ForegroundColor Red
        }
    }
}

function Install-LazydockerConfig {
    Write-Host "`n=== lazydocker Configuration ===" -ForegroundColor Cyan
    
    $configDir = "$env:APPDATA\lazydocker"
    $configFile = "$configDir\config.yml"
    $sourceConfig = "$env:USERPROFILE\dotfiles\lazydocker\config.yml"
    
    # Create config directory if it doesn't exist
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    # Create symlink or copy
    if (Test-Path $configFile) {
        $item = Get-Item $configFile
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "[OK] lazydocker config symlink exists" -ForegroundColor Green
            return
        } else {
            Write-Host "Backing up existing config..." -ForegroundColor Yellow
            Move-Item $configFile "$configFile.backup" -Force
        }
    }
    
    try {
        New-Item -ItemType SymbolicLink -Path $configFile -Target $sourceConfig -Force | Out-Null
        Write-Host "[OK] Created lazydocker config symlink" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Could not create symlink, copying instead..." -ForegroundColor Yellow
        Copy-Item $sourceConfig $configFile -Force
        Write-Host "[OK] Copied lazydocker config" -ForegroundColor Green
    }
}
