# Windows Terminal installation and configuration module

function Install-WindowsTerminal {
    Write-Host "`n=== Windows Terminal ===" -ForegroundColor Cyan

    if (-not (Install-WingetPackage -Id 'Microsoft.WindowsTerminal' -Label 'Windows Terminal')) {
        return
    }

    Install-WindowsTerminalConfig
}

function Install-WindowsTerminalConfig {
    Write-Host "`n=== Windows Terminal Config ===" -ForegroundColor Cyan

    # Windows Terminal stores settings under its packaged LocalState
    $wtSettingsDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"

    if (-not (Test-Path $wtSettingsDir)) {
        Write-Host "[SKIP] Windows Terminal settings directory not found" -ForegroundColor Yellow
        Write-Host "       Launch Windows Terminal once to generate it, then re-run this script" -ForegroundColor Yellow
        return
    }

    Ensure-Link "$HOME\dotfiles\windows-terminal\settings.json" `
        "$wtSettingsDir\settings.json" 'Windows Terminal settings'
}
