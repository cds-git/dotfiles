# WSL setup module
#
# This is the default install path. The Linux side of this repo does the real
# work inside the distro, so all Windows needs is a working WSL and a distro
# to run it in.

function Install-WslSetup {
    Write-Host "`n=== WSL ===" -ForegroundColor Cyan

    if (-not (Test-CommandExists 'wsl')) {
        Write-Host "[WARN] wsl.exe not found" -ForegroundColor Yellow
        Write-Host "       WSL needs Windows 10 2004+ or Windows 11" -ForegroundColor Yellow
        return
    }

    # `wsl -l -q` emits UTF-16, which reaches PowerShell with embedded NULs.
    $distros = @(
        wsl.exe -l -q 2>$null |
            ForEach-Object { ($_ -replace "`0", '').Trim() } |
            Where-Object { $_ }
    )

    if ($distros.Count -eq 0) {
        Write-Host "No WSL distribution is installed." -ForegroundColor Yellow
        $answer = Read-Host 'Install Ubuntu now? (y/N)'
        if ($answer -match '^(y|yes)$') {
            Write-Host "Installing WSL with Ubuntu (a reboot may be required)..." -ForegroundColor Yellow
            wsl.exe --install -d Ubuntu | Out-Host
        } else {
            Write-Host "  Skipped. To do it later: wsl --install -d Ubuntu" -ForegroundColor Yellow
        }
        return
    }

    Write-Host "[OK] WSL distributions installed:" -ForegroundColor Green
    foreach ($distro in $distros) {
        Write-Host ("     - " + $distro) -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "Next step - set up the dotfiles inside WSL:" -ForegroundColor Yellow
    Write-Host "  wsl" -ForegroundColor Cyan
    Write-Host "  git clone https://github.com/cds-git/dotfiles.git ~/dotfiles" -ForegroundColor Cyan
    Write-Host "  ~/dotfiles/scripts/install.sh" -ForegroundColor Cyan
}
