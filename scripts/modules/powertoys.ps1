# PowerToys installation and configuration module

function Install-PowerToys {
    Write-Host "`n=== PowerToys ===" -ForegroundColor Cyan

    if (-not (Install-WingetPackage -Id 'Microsoft.PowerToys' -Label 'PowerToys')) {
        return
    }

    Install-PowerToysConfig
}

function Install-PowerToysConfig {
    Write-Host "`n=== PowerToys Config ===" -ForegroundColor Cyan

    $sourceDir = "$HOME\dotfiles\powertoys"
    $targetDir = "$env:LOCALAPPDATA\Microsoft\PowerToys"

    if (-not (Test-Path $sourceDir)) {
        Write-Host "[FAIL] PowerToys settings missing in dotfiles ($sourceDir)" -ForegroundColor Red
        return
    }

    if (-not (Test-Path $targetDir)) {
        Write-Host '[SKIP] PowerToys settings directory not found' -ForegroundColor Yellow
        Write-Host '       Launch PowerToys once to generate it, then re-run this script' -ForegroundColor Yellow
        return
    }

    # Only the files that carry a decision are tracked. The rest of the
    # PowerToys directory is stock defaults, runtime history (FancyZones alone
    # keeps 20KB of window placements) and logs -- none of it worth versioning.
    $tracked = @(
        'settings.json'                 # which modules are enabled
        'PowerToys Run\settings.json'   # launcher shortcut (Alt+Space)
        'AlwaysOnTop\settings.json'     # pin shortcut (Win+Ctrl+T)
    )

    # These are COPIES, not symlinks, for the same reason as the Windows
    # Terminal config: PowerToys rewrites its settings in place whenever a
    # module changes, which would churn the tracked files and can replace a
    # symlink with a regular file outright.
    $running = Get-Process 'PowerToys' -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host '[WARN] PowerToys is running; it rewrites settings on exit' -ForegroundColor Yellow
        Write-Host '       Restart PowerToys after this to load the copied settings' -ForegroundColor Yellow
    }

    foreach ($rel in $tracked) {
        $source = Join-Path $sourceDir $rel
        $target = Join-Path $targetDir $rel

        if (-not (Test-Path $source)) {
            Write-Host "[SKIP] Not in dotfiles: $rel" -ForegroundColor Yellow
            continue
        }

        $parent = Split-Path $target -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

        if (Test-Path $target) {
            $item = Get-Item $target -Force
            if ($item.LinkType -eq 'SymbolicLink') {
                Write-Host "[WARN] Replacing symlink with a copy: $rel" -ForegroundColor Yellow
                $item.Delete()
            }
            elseif ((Get-FileHash $target -Algorithm SHA256).Hash -eq
                    (Get-FileHash $source -Algorithm SHA256).Hash) {
                Write-Host "[OK] Already matches dotfiles: $rel" -ForegroundColor Green
                continue
            }
            else {
                Copy-Item $target "$target.backup" -Force
            }
        }

        Copy-Item $source $target -Force
        Write-Host "[OK] Installed $rel" -ForegroundColor Green
    }
}
