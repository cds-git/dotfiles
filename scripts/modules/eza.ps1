# eza (modern ls) installation module

function Install-Eza {
    Write-Host "`n=== eza (Modern ls) ===" -ForegroundColor Cyan

    Install-WingetPackage -Id 'eza-community.eza' -Label 'eza' | Out-Null
}
