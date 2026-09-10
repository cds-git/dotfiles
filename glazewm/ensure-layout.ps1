<#
.SYNOPSIS
    Ensures one instance of each pinned application exists on its workspace.

.DESCRIPTION
    Replaces per-process window_rules. A rule matches *every* window of an
    application forever, so a scratch terminal or a second browser window gets
    yanked to the home workspace, and a Teams meeting window gets banished to
    the chat workspace mid-call.

    This runs once instead. For each application it either leaves a window
    already sitting on the right workspace alone, moves one existing window
    home, or launches the application and places its window once it appears.
    It only ever touches a single window per application, so anything extra
    you opened stays exactly where you put it.

    Idempotent: safe to run repeatedly. Bound to Win+Shift+H and run from
    GlazeWM's startup_commands.
#>
[CmdletBinding()]
param(
    # Slow starters (Teams, Outlook) can take a while to show a window.
    [int]$TimeoutSeconds = 90,
    # Give GlazeWM a moment to come up when run from startup_commands.
    [int]$InitialDelaySeconds = 0
)

$ErrorActionPreference = 'Stop'

$glazewm = Join-Path $env:ProgramFiles 'glzr.io\GlazeWM\cli\glazewm.exe'
if (-not (Test-Path $glazewm)) { throw "GlazeWM CLI not found at $glazewm" }

# Process name as GlazeWM reports it, the command to launch it, and its home.
$apps = @(
    @{ Process = 'firefox';         Launch = 'firefox';  Workspace = '1' }
    @{ Process = 'WindowsTerminal'; Launch = 'wt';       Workspace = '2' }
    @{ Process = 'OUTLOOK';         Launch = 'outlook';  Workspace = '8' }
    @{ Process = 'msedge';          Launch = 'msedge';   Workspace = '9' }
    @{ Process = 'ms-teams';        Launch = 'ms-teams'; Workspace = '10' }
)

if ($InitialDelaySeconds -gt 0) { Start-Sleep -Seconds $InitialDelaySeconds }

# Returns every managed window as { Process, Id, Workspace }. Workspace
# children nest inside split containers, so the walk has to recurse.
function Get-ManagedWindows {
    $json = & $glazewm query workspaces 2>$null | ConvertFrom-Json
    if (-not $json.success) { return @() }

    $found = [System.Collections.Generic.List[object]]::new()
    foreach ($ws in $json.data.workspaces) {
        $stack = [System.Collections.Generic.Stack[object]]::new()
        foreach ($c in $ws.children) { $stack.Push($c) }
        while ($stack.Count -gt 0) {
            $node = $stack.Pop()
            if ($node.processName) {
                $found.Add([pscustomobject]@{
                    Process   = $node.processName
                    Id        = $node.id
                    Workspace = $ws.name
                })
            }
            foreach ($c in $node.children) { $stack.Push($c) }
        }
    }
    return $found
}

function Get-FocusedWorkspace {
    $json = & $glazewm query workspaces 2>$null | ConvertFrom-Json
    if (-not $json.success) { return $null }
    ($json.data.workspaces | Where-Object hasFocus | Select-Object -First 1).name
}

$startingWorkspace = Get-FocusedWorkspace

# Pass 1 -- launch whatever is missing, from inside its own workspace.
#
# New windows open on the focused workspace, so focusing first means a slow
# starter lands correctly even if we stop waiting for it. Moving the window
# afterwards instead would make placement a race, and Outlook cold-starting on
# a large mailbox loses that race.
foreach ($app in $apps) {
    if (@(Get-ManagedWindows | Where-Object Process -eq $app.Process).Count -gt 0) { continue }

    & $glazewm command focus --workspace $app.Workspace | Out-Null

    try { Start-Process $app.Launch -ErrorAction Stop }
    catch {
        Write-Host "[FAIL] Could not launch $($app.Launch): $($_.Exception.Message)"
        continue
    }

    # Wait before launching the next one, so its window cannot appear here.
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        if (@(Get-ManagedWindows | Where-Object Process -eq $app.Process).Count -gt 0) { break }
    }
}

# Pass 2 -- sweep. Anything running but astray gets moved home. This also
# corrects a slow starter whose window appeared after pass 1 gave up on it.
foreach ($app in $apps) {
    $windows = @(Get-ManagedWindows | Where-Object Process -eq $app.Process)

    if ($windows.Count -eq 0) {
        Write-Host "[MISSING] $($app.Process) never opened a window"
    }
    elseif ($windows | Where-Object Workspace -eq $app.Workspace) {
        Write-Host "[OK] $($app.Process) on workspace $($app.Workspace)"
    }
    else {
        & $glazewm command --id $windows[0].Id move --workspace $app.Workspace | Out-Null
        Write-Host "[MOVED] $($app.Process) -> workspace $($app.Workspace)"
    }
}

if ($startingWorkspace) {
    & $glazewm command focus --workspace $startingWorkspace | Out-Null
}
