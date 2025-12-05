# Development environment installation module
# Includes: Chocolatey, .NET SDK, Node.js

function Install-Chocolatey {
    Write-Host "`n=== Chocolatey Package Manager ===" -ForegroundColor Cyan
    
    if (Test-CommandExists 'choco') {
        Write-Host "[OK] Chocolatey already installed" -ForegroundColor Green
        return
    }
    
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    winget install chocolatey.chocolatey --accept-source-agreements --accept-package-agreements
    
    if ($LASTEXITCODE -eq 0) {
        Refresh-EnvironmentPath
        if (Wait-ForCommand -Command 'choco') {
            Write-Host "[OK] Chocolatey installed" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Chocolatey installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[ERROR] Failed to install Chocolatey" -ForegroundColor Red
    }
}

function Install-DotNetSDK {
    Write-Host "`n=== .NET SDK ===" -ForegroundColor Cyan
    
    if (Test-CommandExists 'dotnet') {
        $currentVersion = dotnet --version
        Write-Host "Current .NET SDK version: v$currentVersion" -ForegroundColor Yellow
        Write-Host "Upgrading to latest .NET SDK..." -ForegroundColor Yellow
    } else {
        Write-Host "Installing latest .NET SDK..." -ForegroundColor Yellow
    }
    
    winget install Microsoft.DotNet.SDK.10 --accept-source-agreements --accept-package-agreements
    
    if ($LASTEXITCODE -eq 0) {
        Refresh-EnvironmentPath
        if (Wait-ForCommand -Command 'dotnet') {
            $version = dotnet --version
            Write-Host "[OK] .NET SDK installed (v$version)" -ForegroundColor Green
        } else {
            Write-Host "[WARN] .NET SDK installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[ERROR] Failed to install .NET SDK" -ForegroundColor Red
    }
}

function Install-NodeJS {
    Write-Host "`n=== Node.js (via nvm-windows) ===" -ForegroundColor Cyan
    
    # Ensure chocolatey is installed
    if (-not (Test-CommandExists 'choco')) {
        Write-Host "[ERROR] Chocolatey is required but not installed" -ForegroundColor Red
        Write-Host "  Run Install-Chocolatey first" -ForegroundColor Yellow
        return
    }
    
    # Check if nvm is installed
    if (Test-CommandExists 'nvm') {
        Write-Host "[OK] nvm-windows already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing nvm-windows via Chocolatey..." -ForegroundColor Yellow
        choco install nvm -y
        
        if ($LASTEXITCODE -eq 0) {
            Refresh-EnvironmentPath
            if (Wait-ForCommand -Command 'nvm') {
                Write-Host "[OK] nvm-windows installed" -ForegroundColor Green
            } else {
                Write-Host "[WARN] nvm installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
                return
            }
        } else {
            Write-Host "[ERROR] Failed to install nvm-windows" -ForegroundColor Red
            return
        }
    }
    
    # Check if Node.js is installed
    if (Test-CommandExists 'node') {
        $version = node --version
        Write-Host "[OK] Node.js already installed ($version)" -ForegroundColor Green
    } else {
        Write-Host "Installing Node.js LTS via nvm..." -ForegroundColor Yellow
        
        try {
            # Install LTS version
            nvm install lts
            # Activate LTS version
            nvm use lts
            
            Refresh-EnvironmentPath
            
            if (Wait-ForCommand -Command 'node') {
                $version = node --version
                Write-Host "[OK] Node.js LTS installed and activated ($version)" -ForegroundColor Green
            } else {
                Write-Host "[WARN] Node.js installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "[ERROR] Failed to install Node.js: $_" -ForegroundColor Red
        }
    }
}

function Install-Python {
    Write-Host "`n=== Python 3 ===" -ForegroundColor Cyan
    
    if (Test-CommandExists 'python') {
        $version = python --version
        Write-Host "[OK] Python already installed ($version)" -ForegroundColor Green
    } else {
        Write-Host "Installing Python 3..." -ForegroundColor Yellow
        winget install Python.Python.3.13 --accept-source-agreements --accept-package-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Refresh-EnvironmentPath
            if (Wait-ForCommand -Command 'python') {
                $version = python --version
                Write-Host "[OK] Python installed ($version)" -ForegroundColor Green
            } else {
                Write-Host "[WARN] Python installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
            }
        } else {
            Write-Host "[ERROR] Failed to install Python" -ForegroundColor Red
        }
    }
}
