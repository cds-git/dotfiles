# Install .NET SDK
winget install Microsoft.DotNet.SDK.9 --accept-source-agreements --accept-package-agreements

# Install Fast Node Manager (fnm)
winget install Schniz.fnm --accept-source-agreements --accept-package-agreements
fnm install
# Ensure fnm is initialized in PowerShell
$fnmInitSnippet = @"
# Initialize fnm
fnm env --use-on-cd | Out-String | Invoke-Expression
"@
if (-not (Select-String -Path $PROFILE -Pattern "fnm env --use-on-cd" -Quiet)) {
    Add-Content -Path $PROFILE -Value $fnmInitSnippet
    Write-Host "Added fnm initialization to PowerShell profile."
    # Reload profile
    . $PROFILE
}

# Install roslyn LSP
$toolsScript = "$PSScriptRoot/install_roslyn_lsp.ps1"
if (Test-Path $toolsScript) {
    Write-Host "Installing roslyn LSP..."
    & $toolsScript
} else {
    Write-Host "install_roslyn_lsp.ps1 not found! Skipping installation."
}


