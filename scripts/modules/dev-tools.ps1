# Development environment installation module
# Includes: Chocolatey, .NET SDK, Node.js, Python

function Install-Chocolatey {
    Write-Host "`n=== Chocolatey Package Manager ===" -ForegroundColor Cyan

    if (Test-CommandExists 'choco') {
        Write-Host "[OK] Chocolatey already installed" -ForegroundColor Green
        return
    }

    if (-not (Install-WingetPackage -Id 'Chocolatey.Chocolatey' -Label 'Chocolatey')) {
        return
    }

    if (-not (Wait-ForCommand -Command 'choco')) {
        Write-Host "[WARN] Chocolatey installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
    }
}

function Install-DotNetSDK {
    Write-Host "`n=== .NET SDK ===" -ForegroundColor Cyan

    if (Test-CommandExists 'dotnet') {
        Write-Host "Current .NET SDK version: v$(dotnet --version)" -ForegroundColor Yellow
    }

    if (-not (Install-WingetPackage -Id 'Microsoft.DotNet.SDK.10' -Label '.NET SDK')) {
        return
    }

    if (Wait-ForCommand -Command 'dotnet') {
        Write-Host "[OK] .NET SDK at v$(dotnet --version)" -ForegroundColor Green
    } else {
        Write-Host "[WARN] .NET SDK installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
    }
}

function Install-NodeJS {
    Write-Host "`n=== Node.js (via nvm-windows) ===" -ForegroundColor Cyan

    if (-not (Install-ChocoPackage -Id 'nvm' -Label 'nvm-windows')) {
        return
    }

    if (-not (Wait-ForCommand -Command 'nvm')) {
        Write-Host "[WARN] nvm installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
        return
    }

    if (Test-CommandExists 'node') {
        Write-Host "[OK] Node.js already installed ($(node --version))" -ForegroundColor Green
        return
    }

    Write-Host "Installing Node.js LTS via nvm..." -ForegroundColor Yellow
    try {
        nvm install lts | Out-Host
        nvm use lts | Out-Host
        Refresh-EnvironmentPath

        if (Wait-ForCommand -Command 'node') {
            Write-Host "[OK] Node.js LTS installed and activated ($(node --version))" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Node.js installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[ERROR] Failed to install Node.js: $_" -ForegroundColor Red
    }
}

function Install-Python {
    Write-Host "`n=== Python 3 ===" -ForegroundColor Cyan

    if (-not (Install-WingetPackage -Id 'Python.Python.3.13' -Label 'Python 3')) {
        return
    }

    if (Wait-ForCommand -Command 'python') {
        Write-Host "[OK] Python at $(python --version)" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Python installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
    }
}
