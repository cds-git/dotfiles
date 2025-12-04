# Git configuration setup module

function Install-GitConfig {
    Write-Host "`n=== Git Configuration ===" -ForegroundColor Cyan
    
    $gitconfigPath = "$HOME/.gitconfig"
    $dotfilesGitConfig = "$HOME/dotfiles/git/gitconfig"
    
    # Check if ~/.gitconfig already includes our dotfiles
    if (Test-Path $gitconfigPath) {
        $content = Get-Content $gitconfigPath -Raw
        if ($content -match "dotfiles/git/gitconfig") {
            Write-Host "✓ Git config already set up" -ForegroundColor Green
            return
        } else {
            # Backup existing config
            Write-Host "Backing up existing ~/.gitconfig" -ForegroundColor Yellow
            Copy-Item $gitconfigPath "$gitconfigPath.backup"
        }
    }
    
    # Create ~/.gitconfig
    @"
# Machine-specific git configuration
# This file is NOT tracked in dotfiles

# Include standard settings from dotfiles
[include]
	path = $($dotfilesGitConfig -replace '\\', '/')

# Personal information (REQUIRED)
[user]
	name = your-name
	email = your-email@example.com

"@ | Out-File -Encoding utf8 -FilePath $gitconfigPath
    
    Write-Host "✓ Created ~/.gitconfig" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠ Configure your identity:" -ForegroundColor Yellow
    Write-Host "  git config --global user.name 'Your Name'" -ForegroundColor Cyan
    Write-Host "  git config --global user.email 'your@email.com'" -ForegroundColor Cyan
}

function Install-GitHooks {
    Write-Host "`n=== Git Hooks ===" -ForegroundColor Cyan
    
    $templatesDir = "$HOME/.git-templates/hooks"
    $dotfilesHooksDir = "$HOME/dotfiles/git/hooks"
    
    if (-not (Test-Path $templatesDir)) {
        New-Item -ItemType Directory -Force -Path $templatesDir | Out-Null
    }
    
    $sourceHook = "$dotfilesHooksDir/commit-msg"
    $targetHook = "$templatesDir/commit-msg"
    
    if (-not (Test-Path $sourceHook)) {
        Write-Host "✗ Hook not found: $sourceHook" -ForegroundColor Red
        return
    }
    
    # CHANGED: Use Copy-Item instead of SymbolicLink for Windows compatibility
    if (Test-Path $targetHook) {
        Write-Host "⚠ Updating existing hook" -ForegroundColor Yellow
    }
    
    Copy-Item $sourceHook $targetHook -Force
    Write-Host "✓ Installed commit-msg hook" -ForegroundColor Green
    
    $templatePath = "$HOME/.git-templates" -replace '\\', '/'
    git config --global init.templatedir $templatePath
    
    Write-Host "✓ Configured git template directory" -ForegroundColor Green
    Write-Host "  Example: feature/ABC-123-fix → Commit: 'ABC-123: fix bug'" -ForegroundColor Gray
}

# Export functions
