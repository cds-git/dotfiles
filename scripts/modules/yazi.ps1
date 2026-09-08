# Yazi installation and configuration module

function Install-Yazi {
    Write-Host "`n=== yazi (Terminal File Manager) ===" -ForegroundColor Cyan

    Install-WingetPackage -Id 'sxyazi.yazi' -Label 'yazi' | Out-Null
}

function Install-YaziConfig {
    Write-Host "`n=== Yazi Configuration ===" -ForegroundColor Cyan

    $yaziConfigDir = "$env:APPDATA\yazi\config"

    Ensure-Link "$HOME\dotfiles\yazi\theme.toml" `
        "$yaziConfigDir\theme.toml" 'Yazi theme (Catppuccin Mocha)'
    Ensure-Link "$HOME\dotfiles\yazi\yazi.toml" `
        "$yaziConfigDir\yazi.toml" 'Yazi config'
}
