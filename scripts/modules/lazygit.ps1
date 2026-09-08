# Lazygit installation and configuration module

function Install-Lazygit {
    Write-Host "`n=== Lazygit ===" -ForegroundColor Cyan

    if (-not (Install-WingetPackage -Id 'JesseDuffield.lazygit' -Label 'Lazygit')) {
        return
    }

    # delta powers lazygit's diff rendering (see lazygit/config.yml)
    Install-WingetPackage -Id 'dandavison.delta' -Label 'delta' | Out-Null

    # lazygit looks in AppData\Local on Windows
    Ensure-Link "$HOME\dotfiles\lazygit\config.yml" `
        "$HOME\AppData\Local\lazygit\config.yml" 'Lazygit config'
}
