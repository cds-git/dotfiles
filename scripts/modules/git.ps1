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

# Machine-specific settings
# Examples:
#   [safe]
#       directory = C:/repos/admin-repo
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
    
    # Create templates directory
    if (-not (Test-Path $templatesDir)) {
        New-Item -ItemType Directory -Force -Path $templatesDir | Out-Null
    }
    
    # Symlink commit-msg hook from dotfiles
    $sourceHook = "$dotfilesHooksDir/commit-msg"
    $targetHook = "$templatesDir/commit-msg"
    
    if (-not (Test-Path $sourceHook)) {
        Write-Host "✗ Hook not found: $sourceHook" -ForegroundColor Red
        return
    }
    
    if (Test-Path $targetHook) {
        $item = Get-Item $targetHook
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "✓ Commit-msg hook symlink exists" -ForegroundColor Green
        } else {
            Write-Host "⚠ Backing up existing hook" -ForegroundColor Yellow
            Move-Item $targetHook "$targetHook.backup"
            New-Item -ItemType SymbolicLink -Force -Path $targetHook -Target $sourceHook | Out-Null
            Write-Host "✓ Created commit-msg hook symlink" -ForegroundColor Green
        }
    } else {
        New-Item -ItemType SymbolicLink -Force -Path $targetHook -Target $sourceHook | Out-Null
        Write-Host "✓ Created commit-msg hook symlink" -ForegroundColor Green
    }
    
    # Configure git to use templates
    $templatePath = "$HOME/.git-templates" -replace '\\', '/'
    git config --global init.templatedir $templatePath
    
    Write-Host "✓ Configured git template directory" -ForegroundColor Green
    Write-Host "  Example: feature/ABC-123-fix → Commit: 'ABC-123: fix bug'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠ For existing repos, run: git init (to install hooks)" -ForegroundColor Yellow
}

# Export functions
