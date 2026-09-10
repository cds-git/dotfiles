<#
.SYNOPSIS
    Renders the active GlazeWM keybindings as a readable cheatsheet.

.DESCRIPTION
    Parses the live config.yaml rather than keeping a second copy of the
    bindings, so this can never drift from what GlazeWM actually loaded.
    The `# --- Name ---` comments in the config become the section headings,
    and runs of bindings that differ only by a number (the workspace keys)
    are collapsed into a single row.

    Bound to Win+? in config.yaml. Run with -NoWait to print and exit.
#>
[CmdletBinding()]
param(
    [string]$ConfigPath = "$env:USERPROFILE\.glzr\glazewm\config.yaml",
    [switch]$NoWait
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    Write-Host "Config not found: $ConfigPath" -ForegroundColor Red
    if (-not $NoWait) { [void][Console]::ReadKey($true) }
    exit 1
}

$keyNames = @{
    'lwin' = 'Win'; 'rwin' = 'Win'; 'shift' = 'Shift'; 'alt' = 'Alt'
    'ctrl' = 'Ctrl'; 'control' = 'Ctrl'; 'lctrl' = 'Ctrl'; 'rctrl' = 'Ctrl'
    'oem_minus' = '-'; 'oem_plus' = '='; 'oem_question' = '/'; 'oem_tilde' = '`'
    'oem_comma' = ','; 'oem_period' = '.'; 'oem_semi' = ';'; 'oem_quotes' = "'"
    'oem_pipe' = '\'; 'oem_open_brackets' = '['; 'oem_close_brackets' = ']'
    'enter' = 'Enter'; 'return' = 'Enter'; 'escape' = 'Esc'; 'tab' = 'Tab'
    'space' = 'Space'; 'back' = 'Backspace'; 'delete' = 'Del'; 'insert' = 'Ins'
    'left' = 'Left'; 'right' = 'Right'; 'up' = 'Up'; 'down' = 'Down'
    'page_up' = 'PgUp'; 'page_down' = 'PgDn'; 'home' = 'Home'
}

function Format-Binding {
    param([string]$Binding)
    $parts = $Binding -split '\+' | ForEach-Object {
        $k = $_.ToLower()
        if ($keyNames.ContainsKey($k)) { $keyNames[$k] } else { $_.ToUpper() }
    }
    # Win+Shift+/ is how you actually type Win+?
    ($parts -join '+') -replace 'Shift\+/', '?'
}

function Get-Description {
    param([string[]]$Commands)

    # Paired move+focus: the window is moved and focus follows it. Capture the
    # workspace up front -- the second -match below overwrites $Matches.
    if ($Commands.Count -eq 2 -and $Commands[0] -match '^move --workspace (\S+)$') {
        $ws = $Matches[1]
        if ($Commands[1] -match '^focus --workspace') {
            return "Move window to workspace $ws, and follow"
        }
    }

    $c = $Commands[0]
    switch -Regex ($c) {
        '^close$'                            { return 'Close window' }
        '^toggle-tiling-direction$'          { return 'Toggle split direction' }
        '^toggle-floating'                   { return 'Toggle floating' }
        '^toggle-fullscreen$'                { return 'Toggle fullscreen' }
        '^toggle-minimized$'                 { return 'Minimize window' }
        '^set-floating .*shown-on-top'       { return 'Pin: small window, top-right, on top' }
        '^set-tiling$'                       { return 'Put window back in the layout' }
        '^wm-cycle-focus$'                   { return 'Cycle focus: tiling / floating / fullscreen' }
        '^focus --direction (\w+)$'          { return "Focus $($Matches[1])" }
        '^move --direction (\w+)$'           { return "Swap window $($Matches[1])" }
        '^move-workspace --direction (\w+)$' { return "Move workspace to $($Matches[1]) monitor" }
        '^focus --workspace (\S+)$'          { return "Switch to workspace $($Matches[1])" }
        '^move --workspace (\S+)$'           { return "Move window to workspace $($Matches[1]), stay put" }
        '^focus --next-active-workspace$'    { return 'Next workspace in use' }
        '^focus --prev-active-workspace$'    { return 'Previous workspace in use' }
        '^focus --recent-workspace$'         { return 'Last workspace' }
        '^resize --width -'                  { return 'Shrink width' }
        '^resize --width \+'                 { return 'Grow width' }
        '^resize --height -'                 { return 'Shrink height' }
        '^resize --height \+'                { return 'Grow height' }
        '^wm-enable-binding-mode --name (\S+)$'  { return "Enter $($Matches[1]) mode" }
        '^wm-disable-binding-mode --name (\S+)$' { return "Leave $($Matches[1]) mode" }
        '^wm-reload-config$'                 { return 'Reload config' }
        '^wm-exit$'                          { return 'Exit GlazeWM' }
        '^wm-redraw$'                        { return 'Redraw all windows' }
        '^wm-toggle-pause$'                  { return 'Pause window management' }
        'show-keybindings'                   { return 'Show this list' }
        '^shell-exec wt -p WSL nvim$'        { return 'Editor (nvim)' }
        '^shell-exec (msedge|chrome|firefox)$' { return 'Browser' }
        '^shell-exec wt$'                    { return 'Terminal' }
        '^shell-exec explorer$'              { return 'File manager' }
        '^shell-exec (\S+)'                  { return "Launch $($Matches[1])" }
    }
    return $c
}

# --- Parse ------------------------------------------------------------------

$rows = [System.Collections.Generic.List[object]]::new()
$section = ''
$group = ''

foreach ($line in (Get-Content -LiteralPath $ConfigPath)) {

    if ($line -match '^([A-Za-z_]+):') { $section = $Matches[1]; $group = ''; continue }
    if ($section -notin @('keybindings', 'binding_modes')) { continue }

    # `# --- Heading ---` comments become section headings.
    if ($line -match '^\s*#\s*-{2,}\s*(.+?)\s*-{2,}\s*$') { $group = $Matches[1]; continue }

    if ($section -eq 'binding_modes' -and $line -match "^\s*-\s*name:\s*'([^']+)'") {
        $group = "$([char]::ToUpper($Matches[1][0]))$($Matches[1].Substring(1)) mode"
        continue
    }

    if ($line -match "commands:\s*\[(?<cmds>[^\]]*)\]\s*,\s*bindings:\s*\[(?<binds>[^\]]*)\]") {
        $cmds  = [regex]::Matches($Matches['cmds'],  "'([^']*)'") | ForEach-Object { $_.Groups[1].Value }
        $binds = [regex]::Matches($Matches['binds'], "'([^']*)'") | ForEach-Object { $_.Groups[1].Value }
        if (-not $cmds -or -not $binds) { continue }

        $rows.Add([pscustomobject]@{
            Group = if ($group) { $group } else { 'Other' }
            Keys  = ($binds | ForEach-Object { Format-Binding $_ }) -join ' / '
            Desc  = Get-Description $cmds
        })
    }
}

# --- Collapse numbered runs (the workspace keys) ----------------------------

$collapsed = [System.Collections.Generic.List[object]]::new()
$i = 0
while ($i -lt $rows.Count) {
    $row = $rows[$i]
    $template = $row.Desc -replace '\d+', '#'
    $j = $i
    while ($j + 1 -lt $rows.Count -and
           $rows[$j + 1].Group -eq $row.Group -and
           ($rows[$j + 1].Desc -replace '\d+', '#') -eq $template -and
           $template -ne $row.Desc) { $j++ }

    if ($j -gt $i) {
        $firstNum = ([regex]::Match($row.Desc, '\d+')).Value
        $lastNum  = ([regex]::Match($rows[$j].Desc, '\d+')).Value
        $collapsed.Add([pscustomobject]@{
            Group = $row.Group
            Keys  = "$($row.Keys) .. $($rows[$j].Keys)"
            Desc  = ($template -replace '#', "$firstNum-$lastNum")
        })
    }
    else { $collapsed.Add($row) }
    $i = $j + 1
}

# --- Render -----------------------------------------------------------------

$width = ($collapsed | ForEach-Object { $_.Keys.Length } | Measure-Object -Maximum).Maximum

Write-Host ''
Write-Host '  GlazeWM keybindings' -ForegroundColor Cyan
Write-Host "  $ConfigPath" -ForegroundColor DarkGray

$groupOrder = [System.Collections.Generic.List[string]]::new()
foreach ($r in $collapsed) { if (-not $groupOrder.Contains($r.Group)) { $groupOrder.Add($r.Group) } }

foreach ($name in $groupOrder) {
    Write-Host ''
    Write-Host "  $name" -ForegroundColor Yellow
    foreach ($r in ($collapsed | Where-Object Group -eq $name)) {
        Write-Host '    ' -NoNewline
        Write-Host $r.Keys.PadRight($width) -ForegroundColor White -NoNewline
        Write-Host "  $($r.Desc)" -ForegroundColor Gray
    }
}

Write-Host ''
if (-not $NoWait) {
    Write-Host '  Press any key to close' -ForegroundColor DarkGray
    [void][Console]::ReadKey($true)
}
