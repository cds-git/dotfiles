# Development tools installation module

function Install-Chocolatey {
    Write-Host "`n=== Chocolatey Package Manager ===" -ForegroundColor Cyan
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "✓ Chocolatey already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
        winget install chocolatey.chocolatey --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Chocolatey installed" -ForegroundColor Green
            Write-Host "⚠ You may need to restart your terminal" -ForegroundColor Yellow
        } else {
            Write-Host "✗ Failed to install Chocolatey" -ForegroundColor Red
        }
    }
}

function Install-DotNetSDK {
    Write-Host "`n=== .NET SDK ===" -ForegroundColor Cyan
    
    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        $version = dotnet --version
        Write-Host "✓ .NET SDK already installed (v$version)" -ForegroundColor Green
    } else {
        Write-Host "Installing .NET SDK..." -ForegroundColor Yellow
        winget install Microsoft.DotNet.SDK.10 --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ .NET SDK installed" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to install .NET SDK" -ForegroundColor Red
        }
    }
}

function Install-NodeJS {
    Write-Host "`n=== Node.js (via nvm-windows) ===" -ForegroundColor Cyan
    
    # Ensure chocolatey is installed
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "✗ Chocolatey is required but not installed" -ForegroundColor Red
        Write-Host "  Run Install-Chocolatey first" -ForegroundColor Yellow
        return
    }
    
    # Check if nvm is installed
    if (Get-Command nvm -ErrorAction SilentlyContinue) {
        Write-Host "✓ nvm-windows already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing nvm-windows via Chocolatey..." -ForegroundColor Yellow
        choco install nvm -y
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ nvm-windows installed" -ForegroundColor Green
            Write-Host "⚠ Restart your terminal to use nvm" -ForegroundColor Yellow
        } else {
            Write-Host "✗ Failed to install nvm-windows" -ForegroundColor Red
            return
        }
    }
    
    # Check if Node.js is installed
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $version = node --version
        Write-Host "✓ Node.js already installed ($version)" -ForegroundColor Green
    } else {
        Write-Host "⚠ Install Node.js with: nvm install lts" -ForegroundColor Yellow
        Write-Host "  Then activate with: nvm use lts" -ForegroundColor Yellow
    }
}

