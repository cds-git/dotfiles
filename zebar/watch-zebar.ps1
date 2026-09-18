<#
.SYNOPSIS
    Restarts Zebar when it dies.

.DESCRIPTION
    Zebar 3.3.1 crashes whenever Windows reports that there is no default audio
    device: it hands a null device ID to OnDefaultDeviceChanged and the audio
    provider calls wcslen on it, which faults in ucrtbase.dll with 0xc0000005.
    Locking the machine tears the audio endpoint down, and so does a Bluetooth
    headset connecting or a call changing device -- in practice several times a
    day. The upstream fix is open but unmerged (glzr-io/zebar#290) and no
    release carries it, so the bar is restarted rather than losing the audio
    module.

    Remove this once a Zebar release contains that fix: this file, and the
    scheduled task that Install-ZebarWatchdog registers.

.NOTES
    Deliberately independent of GlazeWM. An earlier version was launched from
    GlazeWM's startup_commands and exited once GlazeWM was gone, which lost the
    watchdog entirely every time GlazeWM itself crashed: the restarted GlazeWM
    launched a second watchdog, that one exited on the single-instance mutex
    still held by the first, and the first then exited on its next poll because
    GlazeWM had been missing when it looked. Both gone, nothing to notice.

    So this never exits on its own, and a scheduled task owns its lifetime. A
    missing GlazeWM just means "do nothing for now" -- that way a deliberate
    GlazeWM exit does not get its bar resurrected, without a crash costing the
    watchdog its life.
#>
[CmdletBinding()]
param(
    [int] $IntervalSeconds = 5
)

# One watchdog per session, however many ways this gets started.
$mutex = New-Object System.Threading.Mutex($false, 'Local\dotfiles-zebar-watchdog')
try { if (-not $mutex.WaitOne(0)) { exit 0 } }
catch [System.Threading.AbandonedMutexException] { } # previous holder was killed

$zebar = Join-Path $env:ProgramFiles 'glzr.io\Zebar\zebar.exe'
if (-not (Test-Path $zebar)) { exit 1 }

while ($true) {
    Start-Sleep -Seconds $IntervalSeconds

    # Nothing to do while the window manager is away: without it the bar has no
    # workspaces to show, and GlazeWM starts its own Zebar when it comes back.
    if (-not (Get-Process glazewm -ErrorAction SilentlyContinue)) { continue }
    if (Get-Process zebar -ErrorAction SilentlyContinue) { continue }

    # Let whatever tore the audio device down finish, so the new instance does
    # not walk straight back into the same callback.
    Start-Sleep -Seconds 2
    if (-not (Get-Process zebar -ErrorAction SilentlyContinue)) {
        Start-Process $zebar
    }
}
