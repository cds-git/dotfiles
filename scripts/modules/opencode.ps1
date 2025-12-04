# OpenCode installation and configuration module

function Install-OpenCode {
    Write-Host "`n=== OpenCode ===" -ForegroundColor Cyan
    
    if (Get-Command opencode -ErrorAction SilentlyContinue) {
        Write-Host "[OK] OpenCode already installed" -ForegroundColor Green
    } else {
        Write-Host "Installing OpenCode..." -ForegroundColor Yellow
        npm install -g @opencode/cli
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] OpenCode installed" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to install OpenCode" -ForegroundColor Red
        }
    }
}

function Install-OpenCodeConfig {
    Write-Host "`n=== OpenCode Configuration ===" -ForegroundColor Cyan
    
    $opencodeConfigDir = "$HOME\.config\opencode"
    $dotfilesAgents = "$HOME\dotfiles\opencode\AGENTS.md"
    $dotfilesOpencode = "$HOME\dotfiles\opencode\opencode.json"
    $opencodeAgents = "$opencodeConfigDir\AGENTS.md"
    $opencodeOpencode = "$opencodeConfigDir\opencode.json"
    
    # Create config directory if it doesn't exist
    if (-not (Test-Path $opencodeConfigDir)) {
        New-Item -ItemType Directory -Force -Path $opencodeConfigDir | Out-Null
    }
    
    # Setup AGENTS.md
    if (Test-Path $opencodeAgents) {
        $item = Get-Item $opencodeAgents
        if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $dotfilesAgents) {
            Write-Host "[OK] OpenCode AGENTS.md already configured" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Backing up existing AGENTS.md" -ForegroundColor Yellow
            Copy-Item $opencodeAgents "$opencodeAgents.backup" -Force
            Remove-Item $opencodeAgents -Force
            # Try symlink, fall back to copy
            try {
                New-Item -ItemType SymbolicLink -Force -Path $opencodeAgents -Target $dotfilesAgents | Out-Null
                Write-Host "[OK] OpenCode AGENTS.md configured (symlink)" -ForegroundColor Green
            } catch {
                Copy-Item $dotfilesAgents $opencodeAgents -Force
                Write-Host "[OK] OpenCode AGENTS.md configured (copy)" -ForegroundColor Green
            }
        }
    } else {
        # Try symlink, fall back to copy
        try {
            New-Item -ItemType SymbolicLink -Force -Path $opencodeAgents -Target $dotfilesAgents | Out-Null
            Write-Host "[OK] OpenCode AGENTS.md configured (symlink)" -ForegroundColor Green
        } catch {
            Copy-Item $dotfilesAgents $opencodeAgents -Force
            Write-Host "[OK] OpenCode AGENTS.md configured (copy)" -ForegroundColor Green
        }
    }
    
    # Setup opencode.json
    if (Test-Path $opencodeOpencode) {
        $item = Get-Item $opencodeOpencode
        if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $dotfilesOpencode) {
            Write-Host "[OK] OpenCode opencode.json already configured" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Backing up existing opencode.json" -ForegroundColor Yellow
            Copy-Item $opencodeOpencode "$opencodeOpencode.backup" -Force
            Remove-Item $opencodeOpencode -Force
            # Try symlink, fall back to copy
            try {
                New-Item -ItemType SymbolicLink -Force -Path $opencodeOpencode -Target $dotfilesOpencode | Out-Null
                Write-Host "[OK] OpenCode opencode.json configured (symlink)" -ForegroundColor Green
            } catch {
                Copy-Item $dotfilesOpencode $opencodeOpencode -Force
                Write-Host "[OK] OpenCode opencode.json configured (copy)" -ForegroundColor Green
            }
        }
    } else {
        # Try symlink, fall back to copy
        try {
            New-Item -ItemType SymbolicLink -Force -Path $opencodeOpencode -Target $dotfilesOpencode | Out-Null
            Write-Host "[OK] OpenCode opencode.json configured (symlink)" -ForegroundColor Green
        } catch {
            Copy-Item $dotfilesOpencode $opencodeOpencode -Force
            Write-Host "[OK] OpenCode opencode.json configured (copy)" -ForegroundColor Green
        }
    }
}
