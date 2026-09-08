# GlazeWM installation and configuration module

function Install-GlazeWM {
    Write-Host "`n=== GlazeWM ===" -ForegroundColor Cyan

    Install-WingetPackage -Id 'glzr-io.glazewm' -Label 'GlazeWM' | Out-Null

    # GlazeWM reads ~/.glzr/glazewm/config.yaml
    Ensure-Link "$HOME\dotfiles\glazewm\config.yaml" `
        "$HOME\.glzr\glazewm\config.yaml" 'GlazeWM config'

    # Zebar is the companion status bar referenced in startup_commands
    Install-Zebar
}

function Install-Zebar {
    Write-Host "`n=== Zebar ===" -ForegroundColor Cyan

    Install-WingetPackage -Id 'glzr-io.zebar' -Label 'Zebar' | Out-Null
}
