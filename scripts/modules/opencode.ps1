# OpenCode configuration setup module

function Install-OpenCodeConfig {
    Write-Host "`n=== OpenCode Configuration ===" -ForegroundColor Cyan
    
    $opencodeConfigDir = "$HOME\.config\opencode"
    $dotfilesAgents = "$HOME\dotfiles\opencode\AGENTS.md"
    $dotfilesConfig = "$HOME\dotfiles\opencode\config.json"
    $opencodeAgents = "$opencodeConfigDir\AGENTS.md"
    $opencodeConfig = "$opencodeConfigDir\config.json"
    
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
    
    # Setup config.json
    if (Test-Path $opencodeConfig) {
        $item = Get-Item $opencodeConfig
        if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $dotfilesConfig) {
            Write-Host "[OK] OpenCode config.json already configured" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Backing up existing config.json" -ForegroundColor Yellow
            Copy-Item $opencodeConfig "$opencodeConfig.backup" -Force
            Remove-Item $opencodeConfig -Force
            # Try symlink, fall back to copy
            try {
                New-Item -ItemType SymbolicLink -Force -Path $opencodeConfig -Target $dotfilesConfig | Out-Null
                Write-Host "[OK] OpenCode config.json configured (symlink)" -ForegroundColor Green
            } catch {
                Copy-Item $dotfilesConfig $opencodeConfig -Force
                Write-Host "[OK] OpenCode config.json configured (copy)" -ForegroundColor Green
            }
        }
    } else {
        # Try symlink, fall back to copy
        try {
            New-Item -ItemType SymbolicLink -Force -Path $opencodeConfig -Target $dotfilesConfig | Out-Null
            Write-Host "[OK] OpenCode config.json configured (symlink)" -ForegroundColor Green
        } catch {
            Copy-Item $dotfilesConfig $opencodeConfig -Force
            Write-Host "[OK] OpenCode config.json configured (copy)" -ForegroundColor Green
        }
    }
}
