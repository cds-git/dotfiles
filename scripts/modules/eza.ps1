# eza (modern ls) installation module

function Install-Eza {
    Write-Host "`n=== eza (Modern ls) ===" -ForegroundColor Cyan
    
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        $version = eza --version | Select-Object -First 1
        Write-Host "[OK] eza already installed ($version)" -ForegroundColor Green
    } else {
        Write-Host "Installing eza..." -ForegroundColor Yellow
        winget install eza-community.eza --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] eza installed" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to install eza" -ForegroundColor Red
        }
    }
}
