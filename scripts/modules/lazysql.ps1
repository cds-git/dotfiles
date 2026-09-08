# lazysql installation module
# No winget/choco package available - install from GitHub releases

function Install-Lazysql {
    Write-Host "`n=== lazysql (Database TUI) ===" -ForegroundColor Cyan

    $installDir = "$env:LOCALAPPDATA\lazysql"
    $stampFile = "$installDir\.installed-version"

    try {
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/jorgerojas26/lazysql/releases/latest'
    } catch {
        Write-Host "[WARN] Could not reach the GitHub releases API: $_" -ForegroundColor Yellow
        if (Test-CommandExists 'lazysql') {
            Write-Host "[OK] lazysql already installed (update check skipped)" -ForegroundColor Green
        }
        return
    }

    $latest = $release.tag_name

    # lazysql has no reliable --version flag, so record the installed tag in a
    # stamp file. Without this the module either skipped updates forever or
    # re-downloaded the archive on every run.
    if ((Test-Path $stampFile) -and (Test-CommandExists 'lazysql')) {
        $installed = (Get-Content $stampFile -Raw).Trim()
        if ($installed -eq $latest) {
            Write-Host "[OK] lazysql already up to date ($latest)" -ForegroundColor Green
            return
        }
        Write-Host "Updating lazysql $installed -> $latest..." -ForegroundColor Yellow
    } else {
        Write-Host "Installing lazysql $latest..." -ForegroundColor Yellow
    }

    try {
        $asset = $release.assets | Where-Object { $_.name -match 'Windows_x86_64\.zip$' } | Select-Object -First 1

        if (-not $asset) {
            Write-Host "[ERROR] Could not find Windows release asset" -ForegroundColor Red
            return
        }

        $zipPath = "$env:TEMP\lazysql.zip"

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

        Set-Content -Path $stampFile -Value $latest -Encoding ascii

        if (Wait-ForCommand -Command 'lazysql') {
            Write-Host "[OK] lazysql installed ($latest)" -ForegroundColor Green
        } else {
            Write-Host "[WARN] lazysql installed but not in PATH yet. Restart terminal." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[ERROR] Failed to install lazysql: $_" -ForegroundColor Red
    }
}
