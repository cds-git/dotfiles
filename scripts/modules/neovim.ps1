# Neovim installation and configuration module

function Install-Neovim {
    Write-Host "`n=== Neovim ===" -ForegroundColor Cyan

    if (Test-CommandExists 'nvim') {
        $current = (nvim --version 2>$null | Select-Object -First 1)
        Write-Host "Current Neovim version: $current" -ForegroundColor Yellow
    }

    if (-not (Install-WingetPackage -Id 'Neovim.Neovim' -Label 'Neovim')) {
        return
    }

    $version = (nvim --version 2>$null | Select-Object -First 1)
    if ($version) {
        Write-Host "[OK] Neovim at $version" -ForegroundColor Green
    }

    # Utilities Neovim expects on PATH
    Write-Host "Installing Neovim utilities..." -ForegroundColor Yellow

    $tools = @(
        @{ Id = 'BurntSushi.ripgrep.MSVC'; Label = 'ripgrep' }
        # NOTE: the winget id is junegunn.fzf - a bare "fzf" matches nothing
        # when queried with --id --exact.
        @{ Id = 'junegunn.fzf'; Label = 'fzf' }
        @{ Id = 'sharkdp.fd'; Label = 'fd' }
    )

    foreach ($tool in $tools) {
        Install-WingetPackage -Id $tool.Id -Label $tool.Label | Out-Null
    }

    # Build tools for compiling treesitter parsers
    if (Test-CommandExists 'choco') {
        Install-ChocoPackage -Id 'make' -Label 'make' | Out-Null
        Install-ChocoPackage -Id 'mingw' -Label 'mingw' | Out-Null
    } else {
        Write-Host "[SKIP] Chocolatey not installed - skipping make/mingw" -ForegroundColor Yellow
    }

    Ensure-Link "$HOME\dotfiles\nvim" "$HOME\AppData\Local\nvim" 'Neovim config'
}
