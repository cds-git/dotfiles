# Windows Terminal installation and configuration module

function Install-WindowsTerminal {
    Write-Host "`n=== Windows Terminal ===" -ForegroundColor Cyan

    if (-not (Install-WingetPackage -Id 'Microsoft.WindowsTerminal' -Label 'Windows Terminal')) {
        return
    }

    Install-WindowsTerminalConfig
}

function Install-WindowsTerminalConfig {
    Write-Host "`n=== Windows Terminal Config ===" -ForegroundColor Cyan

    $source = "$HOME\dotfiles\windows-terminal\settings.json"

    # Windows Terminal stores settings under its packaged LocalState
    $wtSettingsDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    $target = "$wtSettingsDir\settings.json"

    # Records the hash of the repo file at the last deploy, so a re-run only
    # overwrites when the repo copy has actually changed.
    $stampFile = "$wtSettingsDir\.dotfiles-settings-hash"

    if (-not (Test-Path $source)) {
        Write-Host "[FAIL] Windows Terminal settings missing in dotfiles ($source)" -ForegroundColor Red
        return
    }

    if (-not (Test-Path $wtSettingsDir)) {
        Write-Host "[SKIP] Windows Terminal settings directory not found" -ForegroundColor Yellow
        Write-Host "       Launch Windows Terminal once to generate it, then re-run this script" -ForegroundColor Yellow
        return
    }

    # This is a COPY, not a symlink. Windows Terminal rewrites settings.json in
    # place - reordering every key, injecting its own defaults and stripping
    # comments - so a symlink pointed at the repo means WT churns the tracked
    # file and destroys the annotations that make it reviewable.
    if (Test-Path $target) {
        $item = Get-Item $target -Force
        if ($item.LinkType -eq 'SymbolicLink') {
            Write-Host "[WARN] Replacing the old settings symlink with a copy" -ForegroundColor Yellow
            # Removing a symlink needs no elevation; .Delete() removes the link
            # itself rather than following it.
            $item.Delete()
        }
    }

    $sourceHash = (Get-FileHash -Path $source -Algorithm SHA256).Hash

    if (Test-Path $target) {
        $liveHash = (Get-FileHash -Path $target -Algorithm SHA256).Hash
        $stamped = if (Test-Path $stampFile) { (Get-Content $stampFile -Raw).Trim() } else { $null }

        if ($liveHash -eq $sourceHash) {
            Write-Host "[OK] Windows Terminal settings already match dotfiles" -ForegroundColor Green
            Set-Content -Path $stampFile -Value $sourceHash -Encoding ascii
            return
        }

        if ($stamped -eq $sourceHash) {
            # The repo copy has not changed since the last deploy, so the live
            # file differs because Windows Terminal (or the user) edited it.
            # Leave those edits alone rather than silently discarding them.
            Write-Host "[SKIP] Live settings differ, but the dotfiles copy is unchanged since the last install" -ForegroundColor Yellow
            Write-Host "       Windows Terminal likely rewrote them. To keep those changes:" -ForegroundColor Yellow
            Write-Host "         copy `"$target`" `"$source`"" -ForegroundColor Cyan
            Write-Host "       To discard them and redeploy the dotfiles copy:" -ForegroundColor Yellow
            Write-Host "         Remove-Item `"$stampFile`"; then re-run this script" -ForegroundColor Cyan
            return
        }

        Write-Host "[WARN] Backing up existing settings to settings.json.backup" -ForegroundColor Yellow
        Copy-Item -Path $target -Destination "$target.backup" -Force
    }

    Copy-Item -Path $source -Destination $target -Force
    Set-Content -Path $stampFile -Value $sourceHash -Encoding ascii
    Write-Host "[OK] Windows Terminal settings deployed from dotfiles" -ForegroundColor Green
}
