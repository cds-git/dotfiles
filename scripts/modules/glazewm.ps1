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

    # Zebar discovers packs as directories under ~/.glzr/zebar. Linking ours in
    # as its own pack keeps it out of the way of the bundled 'starter' pack,
    # which Zebar rewrites on update.
    Ensure-Link "$HOME\dotfiles\zebar" `
        "$HOME\.glzr\zebar\dotfiles" 'Zebar pack'

    # Point the startup widget at our pack rather than 'starter'.
    $settingsPath = "$HOME\.glzr\zebar\settings.json"
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $changed = $false
        foreach ($config in $settings.startupConfigs) {
            if ($config.pack -ne 'dotfiles') { $config.pack = 'dotfiles'; $changed = $true }
        }
        if ($changed) {
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
            Write-Host '  Zebar startup pack -> dotfiles' -ForegroundColor Green
        }
    }
}
