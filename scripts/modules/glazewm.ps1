# GlazeWM installation and configuration module

function Install-GlazeWM {
    Write-Host "`n=== GlazeWM ===" -ForegroundColor Cyan

    Install-WingetPackage -Id 'glzr-io.glazewm' -Label 'GlazeWM' | Out-Null

    # GlazeWM reads ~/.glzr/glazewm/config.yaml
    Ensure-Link "$HOME\dotfiles\glazewm\config.yaml" `
        "$HOME\.glzr\glazewm\config.yaml" 'GlazeWM config'

    # Zebar is the companion status bar referenced in startup_commands
    Install-Zebar
}

function Install-Zebar {
    Write-Host "`n=== Zebar ===" -ForegroundColor Cyan

    Install-WingetPackage -Id 'glzr-io.zebar' -Label 'Zebar' | Out-Null

    # Zebar discovers packs as directories under ~/.glzr/zebar. Linking ours in
    # as its own pack keeps it out of the way of the bundled 'starter' pack,
    # which Zebar rewrites on update.
    Ensure-Link "$HOME\dotfiles\zebar" `
        "$HOME\.glzr\zebar\dotfiles" 'Zebar pack'

    # Ensure-Link leaves a .backup beside whatever it replaced. Zebar keys packs
    # on the "name" in zpack.json rather than the folder, so a backup sitting in
    # the packs directory declares the same name and shadows the real pack --
    # silently serving stale HTML, CSS and bar height. Move it out of scope.
    $staleBackup = "$HOME\.glzr\zebar\dotfiles.backup"
    if (Test-Path $staleBackup) {
        $movedTo = "$HOME\.glzr\zebar-dotfiles.backup"
        if (Test-Path $movedTo) { Remove-Item $movedTo -Recurse -Force }
        Move-Item $staleBackup $movedTo -Force
        Write-Host '  Moved shadowing dotfiles.backup out of the packs directory' -ForegroundColor Yellow
    }

    Install-ZebarWatchdog

    # Point the startup widget at our pack rather than 'starter'.
    $settingsPath = "$HOME\.glzr\zebar\settings.json"
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $changed = $false
        foreach ($config in $settings.startupConfigs) {
            if ($config.pack -ne 'dotfiles') { $config.pack = 'dotfiles'; $changed = $true }
        }
        if ($changed) {
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
            Write-Host '  Zebar startup pack -> dotfiles' -ForegroundColor Green
        }
    }
}

function Install-ZebarWatchdog {
    # Zebar 3.3.1 crashes whenever Windows reports no default audio device --
    # locking the machine, a Bluetooth headset connecting, a call switching
    # device. See the header of zebar\watch-zebar.ps1. The upstream fix
    # (glzr-io/zebar#290) is merged as of 2026-09-20 but no release carries it
    # yet; delete this function and the script once one does.
    #
    # A scheduled task rather than a GlazeWM startup_command on purpose: GlazeWM
    # crashes too, and anything it owns dies with it exactly when it is needed.
    $name   = 'dotfiles-zebar-watchdog'
    $script = Join-Path $env:USERPROFILE 'dotfiles\zebar\watch-zebar.ps1'

    Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction SilentlyContinue

    # Launched through a headless conhost rather than powershell.exe directly.
    # With Windows Terminal set as the default console, -WindowStyle Hidden is
    # not honoured: the task pops a terminal window at logon, the user closes
    # it, and the watchdog dies with STATUS_CONTROL_C_EXIT (0xC000013A) -- which
    # is exactly how the first version of this task went missing. A headless
    # conhost has no window to close and bypasses the terminal delegation.
    $action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\conhost.exe" `
        -Argument ('--headless powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}"' -f $script)

    # Two triggers: start at logon, and re-fire every five minutes for the rest
    # of the session. The watchdog's mutex makes the repeats no-ops while it is
    # alive, so all they do is revive it if something kills it. RestartCount
    # below does not cover that case: the task only restarts on a failure
    # result, and a killed process is not one.
    $atLogon = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $repeat  = New-ScheduledTaskTrigger -Once -At (Get-Date).Date `
        -RepetitionInterval (New-TimeSpan -Minutes 5)

    # ExecutionTimeLimit zero means no limit: this runs for the whole session,
    # and the default three days would silently kill it.
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit ([TimeSpan]::Zero) `
        -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) `
        -MultipleInstances IgnoreNew -StartWhenAvailable
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
        -LogonType Interactive -RunLevel Limited

    Register-ScheduledTask -TaskName $name -Action $action -Trigger @($atLogon, $repeat) `
        -Settings $settings -Principal $principal `
        -Description 'Restarts Zebar after it crashes (glzr-io/zebar#290).' | Out-Null

    Start-ScheduledTask -TaskName $name
    Write-Host '  Zebar watchdog scheduled task registered' -ForegroundColor Green
}
