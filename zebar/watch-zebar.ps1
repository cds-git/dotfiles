<#
.SYNOPSIS
    Restarts Zebar when it dies.

.DESCRIPTION
    Zebar 3.3.1 crashes whenever Windows reports that there is no default audio
    device: it hands a null device ID to OnDefaultDeviceChanged and the audio
    provider calls wcslen on it, which faults in ucrtbase.dll with 0xc0000005.
    Locking the machine tears the audio endpoint down, so the bar dies on
    virtually every lock, and connecting or disconnecting Bluetooth headphones
    does it too. The upstream fix is open but unmerged (glzr-io/zebar#290) and
    there is no release carrying it, so the bar is restarted rather than losing
    the audio module.

    Remove this once a Zebar release contains that fix -- the whole file, and
    the startup_commands line in the GlazeWM config that launches it.

.NOTES
    Lifetime is tied to GlazeWM rather than to the session: the loop exits once
    GlazeWM is gone, so a restart of the window manager leaves no orphan behind
    quietly resurrecting a bar that nothing is arranging windows around.
#>
[CmdletBinding()]
param(
    [int] $IntervalSeconds = 5
)

# Only one watchdog, however many times GlazeWM restarts and runs this.
$mutex = New-Object System.Threading.Mutex($false, 'Local\dotfiles-zebar-watchdog')
if (-not $mutex.WaitOne(0)) { exit 0 }

$zebar = Join-Path $env:ProgramFiles 'glzr.io\Zebar\zebar.exe'
if (-not (Test-Path $zebar)) { exit 1 }

try {
    while ($true) {
        Start-Sleep -Seconds $IntervalSeconds

        # GlazeWM gone means either a deliberate exit or a crash it will be
        # restarted from; either way this instance's job is over.
        if (-not (Get-Process glazewm -ErrorAction SilentlyContinue)) { break }

        if (Get-Process zebar -ErrorAction SilentlyContinue) { continue }

        # Let whatever tore the audio device down finish first, so the new
        # instance does not walk straight back into the same callback.
        Start-Sleep -Seconds 2
        if (-not (Get-Process zebar -ErrorAction SilentlyContinue)) {
            Start-Process $zebar
        }
    }
}
finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
