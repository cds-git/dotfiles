<#
.SYNOPSIS
    Opens the Windows notification centre and calendar flyout.

.DESCRIPTION
    Clicking the taskbar clock on Windows 11 opens the notification centre,
    which is where the calendar lives. There is no public API or shell CLSID
    for that flyout, so the only reliable way to raise it is to synthesise its
    keyboard shortcut, Win+N.

    Called from the Zebar clock's onClick via GlazeWM's shell-exec. Win+N is
    left unbound in the GlazeWM config so its keyboard hook lets this through.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Add-Type -Name Native -Namespace Win32 -MemberDefinition @'
[DllImport("user32.dll")]
public static extern void keybd_event(byte vk, byte scan, uint flags, int extra);
'@

$VK_LWIN = 0x5B
$VK_N = 0x4E
$KEYUP = 0x2

[Win32.Native]::keybd_event($VK_LWIN, 0, 0, 0)
[Win32.Native]::keybd_event($VK_N, 0, 0, 0)
[Win32.Native]::keybd_event($VK_N, 0, $KEYUP, 0)
[Win32.Native]::keybd_event($VK_LWIN, 0, $KEYUP, 0)
