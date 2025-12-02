# Yazi configuration setup module

function Install-YaziConfig {
    Write-Host "`n=== Yazi Configuration ===" -ForegroundColor Cyan
    
    $yaziConfigDir = "$env:APPDATA\yazi\config"
    $dotfilesYaziTheme = "$HOME\dotfiles\yazi\theme.toml"
    $yaziTheme = "$yaziConfigDir\theme.toml"
    
    # Create config directory if it doesn't exist
    if (-not (Test-Path $yaziConfigDir)) {
        New-Item -ItemType Directory -Force -Path $yaziConfigDir | Out-Null
    }
    
    # Check if theme.toml is already a symlink to our dotfiles
    if (Test-Path $yaziTheme) {
        $item = Get-Item $yaziTheme
        if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $dotfilesYaziTheme) {
            Write-Host "[OK] Yazi theme already configured" -ForegroundColor Green
            return
        } else {
            Write-Host "[WARN] Backing up existing theme.toml" -ForegroundColor Yellow
            Copy-Item $yaziTheme "$yaziTheme.backup" -Force
            Remove-Item $yaziTheme -Force
        }
    }
    
    # Create symlink
    try {
        New-Item -ItemType SymbolicLink -Force -Path $yaziTheme -Target $dotfilesYaziTheme | Out-Null
        Write-Host "[OK] Yazi theme configured (Catppuccin Mocha)" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to create symlink, copying instead" -ForegroundColor Yellow
        Copy-Item $dotfilesYaziTheme $yaziTheme -Force
        Write-Host "[OK] Yazi theme copied" -ForegroundColor Green
    }
}
