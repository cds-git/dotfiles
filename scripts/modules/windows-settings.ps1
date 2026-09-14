# Windows settings that are not tied to any one application

function Set-WindowsSettings {
    Write-Host "`n=== Windows settings ===" -ForegroundColor Cyan

    Disable-InputSwitchHotkey
}

function Disable-InputSwitchHotkey {
    # Alt+Shift is the legacy input-switch hotkey and fires by accident
    # constantly -- it sits under half the Alt+Shift+key chords an editor uses.
    # Turn it off. Win+Space stays the EN/DA switcher: it is built into the
    # shell and is NOT governed by this registry key, so disabling the legacy
    # one costs nothing. Takes effect immediately, no sign-out needed.
    $path = 'HKCU:\Keyboard Layout\Toggle'
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }

    # All three names matter: Windows still consults the legacy "Hotkey"
    # alongside the per-purpose pair, so leaving any of them at 1 keeps
    # Alt+Shift alive. 3 means Not Assigned.
    foreach ($name in 'Hotkey', 'Language Hotkey', 'Layout Hotkey') {
        Set-ItemProperty -Path $path -Name $name -Value '3' -Type String
    }
    Write-Host '  Input-switch hotkey Alt+Shift disabled (Win+Space still switches)' -ForegroundColor Green
}
