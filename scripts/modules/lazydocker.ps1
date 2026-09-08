# lazydocker installation module

function Install-Lazydocker {
    Write-Host "`n=== lazydocker (Docker TUI) ===" -ForegroundColor Cyan

    if (-not (Install-ChocoPackage -Id 'lazydocker' -Label 'lazydocker')) {
        return
    }

    if (Wait-ForCommand -Command 'lazydocker') {
        $version = (lazydocker --version 2>&1 | Select-Object -First 1)
        Write-Host "[OK] lazydocker available ($version)" -ForegroundColor Green
    } else {
        Write-Host "[WARN] lazydocker installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
    }
}

function Install-LazydockerConfig {
    Write-Host "`n=== lazydocker Configuration ===" -ForegroundColor Cyan

    Ensure-Link "$HOME\dotfiles\lazydocker\config.yml" `
        "$env:APPDATA\lazydocker\config.yml" 'lazydocker config'
}
