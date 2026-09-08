# Starship prompt installation and configuration module

function Install-Starship {
    Write-Host "`n=== Starship ===" -ForegroundColor Cyan

    if (-not (Install-WingetPackage -Id 'Starship.Starship' -Label 'Starship')) {
        return
    }

    Ensure-Link "$HOME\dotfiles\starship\starship.toml" `
        "$HOME\.config\starship.toml" 'Starship config'
}
