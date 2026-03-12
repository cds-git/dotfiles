# Windows Terminal installation and configuration module

function Install-WindowsTerminal {
    Write-Host "`n=== Windows Terminal ===" -ForegroundColor Cyan
    
    # Check if already installed
    $wtPackage = Get-AppxPackage -Name Microsoft.WindowsTerminal -ErrorAction SilentlyContinue
    if ($wtPackage) {
        Write-Host "✓ Windows Terminal already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing Windows Terminal..." -ForegroundColor Yellow
        winget install Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Windows Terminal installed" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to install Windows Terminal" -ForegroundColor Red
            return
        }
    }
    
    Install-WindowsTerminalConfig
}

function Install-WindowsTerminalConfig {
    Write-Host "`n=== Windows Terminal Config ===" -ForegroundColor Cyan
    
    $dotfilesSettings = "$HOME\dotfiles\windows-terminal\settings.json"
    
    # Windows Terminal stores settings in LocalAppData
    $wtSettingsDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    $wtSettings = "$wtSettingsDir\settings.json"
    
    # Check if Windows Terminal is installed
    if (-not (Test-Path $wtSettingsDir)) {
        Write-Host "⊘ Windows Terminal settings directory not found" -ForegroundColor Yellow
        Write-Host "  Launch Windows Terminal once to generate it, then re-run this script" -ForegroundColor Yellow
        return
    }
    
    if (Test-Path $wtSettings) {
        $item = Get-Item $wtSettings
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "✓ Windows Terminal config symlink exists" -ForegroundColor Green
        } else {
            Write-Host "⚠ Backing up existing config" -ForegroundColor Yellow
            Move-Item $wtSettings "$wtSettings.backup"
            New-Item -ItemType SymbolicLink -Force -Path $wtSettings -Target $dotfilesSettings | Out-Null
            Write-Host "✓ Created Windows Terminal config symlink" -ForegroundColor Green
        }
    } else {
        New-Item -ItemType SymbolicLink -Force -Path $wtSettings -Target $dotfilesSettings | Out-Null
        Write-Host "✓ Created Windows Terminal config symlink" -ForegroundColor Green
    }
}
