# lazysql installation module
# No winget/choco package available — install from GitHub releases

function Install-Lazysql {
    Write-Host "`n=== lazysql (Database TUI) ===" -ForegroundColor Cyan

    if (Test-CommandExists 'lazysql') {
        Write-Host "[OK] lazysql already installed" -ForegroundColor Green
        return
    }

    Write-Host "Installing lazysql from GitHub releases..." -ForegroundColor Yellow

    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/jorgerojas26/lazysql/releases/latest"
        $asset = $release.assets | Where-Object { $_.name -match "Windows_x86_64\.zip$" } | Select-Object -First 1

        if (-not $asset) {
            Write-Host "[ERROR] Could not find Windows release asset" -ForegroundColor Red
            return
        }

        $installDir = "$env:LOCALAPPDATA\lazysql"
        $zipPath = "$env:TEMP\lazysql.zip"

        # Download and extract
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath
        if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
        Remove-Item $zipPath -Force

        # Add to user PATH if not already there
        $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
        if ($userPath -notlike "*$installDir*") {
            [System.Environment]::SetEnvironmentVariable('Path', "$userPath;$installDir", 'User')
        }
        Refresh-EnvironmentPath

        if (Wait-ForCommand -Command 'lazysql') {
            Write-Host "[OK] lazysql installed ($($release.tag_name))" -ForegroundColor Green
        } else {
            Write-Host "[WARN] lazysql installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[ERROR] Failed to install lazysql: $_" -ForegroundColor Red
    }
}
