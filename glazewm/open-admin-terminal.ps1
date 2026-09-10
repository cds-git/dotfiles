<#
.SYNOPSIS
    Opens an elevated PowerShell in a floating, centred Windows Terminal window.

.DESCRIPTION
    Windows' UIPI stops a process from moving, resizing or focusing a window
    owned by a more privileged one. GlazeWM runs unelevated, so it cannot
    manage this terminal at all -- the window_rules entry matching its title
    only takes effect if GlazeWM itself is running elevated.

    In practice that means the admin terminal already behaves like a floating
    window, since GlazeWM leaves it out of the tiling layout entirely. What it
    does not get is placement, so the geometry is set here instead using
    Windows Terminal's own --pos and --size arguments.

    Triggers a UAC prompt, by design. Bound to Win+Ctrl+Enter.
#>
[CmdletBinding()]
param(
    [int]$Columns = 120,
    [int]$Rows = 32
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
$area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

# Windows Terminal sizes in character cells, so the pixel footprint is an
# estimate: roughly 9px per column and 19px per row at the default font, plus
# the tab bar. Close enough to land the window centred.
$width = $Columns * 9
$height = ($Rows * 19) + 40
$x = $area.X + [int](($area.Width - $width) / 2)
$y = $area.Y + [int](($area.Height - $height) / 2)

# Globals (--pos/--size) must precede the subcommand; --title and -p belong to
# new-tab, so spell the subcommand out rather than relying on the implicit one.
$argList = @(
    '--pos', "$x,$y"
    '--size', "$Columns,$Rows"
    'new-tab'
    '--title', 'AdminTerminal'
    '-p', 'PowerShell'
)

Start-Process -FilePath 'wt.exe' -Verb RunAs -ArgumentList $argList
