# PowerShell profile setup module

function Install-PowerShellProfile {
    Write-Host "`n=== PowerShell Profile ===" -ForegroundColor Cyan
    
    $dotfilesProfile = "$HOME/dotfiles/powershell/cds_profile.ps1"
    
    # Ensure main profile exists
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
        Write-Host "✓ Created PowerShell profile" -ForegroundColor Green
    }
    
    $snippet = @"
# Load custom dotfiles profile
if (Test-Path '$dotfilesProfile') {
    . '$dotfilesProfile'
}
"@
    
    # Check if snippet already exists
    $content = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($content -match [regex]::Escape($dotfilesProfile)) {
        Write-Host "✓ Dotfiles profile already loaded" -ForegroundColor Green
    } else {
        # Append snippet
        "`r`n$snippet" | Out-File -Append -Encoding utf8 -FilePath $PROFILE
        Write-Host "✓ Added dotfiles profile to PowerShell profile" -ForegroundColor Green
    }
}

