# Install .NET SDK
winget install Microsoft.DotNet.SDK.9 --accept-source-agreements --accept-package-agreements

# Install roslyn LSP
$toolsScript = "$PSScriptRoot/install_roslyn_lsp.ps1"
if (Test-Path $toolsScript) {
    Write-Host "Installing roslyn LSP..."
    & $toolsScript
} else {
    Write-Host "install_roslyn_lsp.ps1 not found! Skipping installation."
}

# Install Fast Node Manager (fnm)
winget install Schniz.fnm --accept-source-agreements --accept-package-agreements
fnm install 22
# Ensure the main profile exists
if (!(Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}
# Snippet to be added
$fnmSnippet = @"
# Initialize fnm 
fnm env --use-on-cd | Out-String | Invoke-Expression
"@
# Check if the snippet is already present
if (-not (Select-String -Path $PROFILE -Pattern ([regex]::Escape("fnm env --use-on-cd")) -Quiet)) {
    # Append with a newline above for readability
    "`r`n$fnmSnippet" | Out-File -Append -Encoding utf8 -FilePath $PROFILE
    Write-Host "fnm environment setup has been added to $PROFILE"
    # Immediately reload profile
    . $PROFILE
} else {
    Write-Host "fnm environment setup is already present in $PROFILE"
}
