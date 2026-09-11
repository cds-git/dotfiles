<#
.SYNOPSIS
    Opens the Windows quick settings flyout.

.DESCRIPTION
    Quick settings is where the volume slider and the output-device picker
    live. As with the notification centre there is no public API or shell
    CLSID for the flyout, so the only reliable way to raise it is to
    synthesise its keyboard shortcut, Win+A.

    Note this opens the flyout for the session the bar is running in. Over
    RDP that session sees a single "Remote Audio" endpoint rather than the
    machine's own hardware, so this controls the stream going to the client.

    Called from the Zebar audio module via GlazeWM's shell-exec. Win+A is left
    unbound in the GlazeWM config so its keyboard hook lets this through.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Add-Type -Name Native -Namespace Win32 -MemberDefinition @'
[DllImport("user32.dll")]
public static extern void keybd_event(byte vk, byte scan, uint flags, int extra);
'@

$VK_LWIN = 0x5B
$VK_A = 0x41
$KEYUP = 0x2

[Win32.Native]::keybd_event($VK_LWIN, 0, 0, 0)
[Win32.Native]::keybd_event($VK_A, 0, 0, 0)
[Win32.Native]::keybd_event($VK_A, 0, $KEYUP, 0)
[Win32.Native]::keybd_event($VK_LWIN, 0, $KEYUP, 0)
