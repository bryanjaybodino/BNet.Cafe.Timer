Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinApi {
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
        int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll", EntryPoint = "GetWindowLong")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
}
"@

$HWND_TOPMOST = [IntPtr](-1)
$GWL_EXSTYLE  = -20
$WS_EX_TOPMOST = 0x00000008

# NOSIZE | NOMOVE | NOACTIVATE
# NOACTIVATE is important: without it every call steals focus, which closes the
# Web Serial port picker and fires window 'blur' in the page.
$flags = 0x0001 -bor 0x0002 -bor 0x0010

# Browsers that will be closed if they are NOT the kiosk instance
$browserNames = @('chrome', 'msedge', 'brave', 'vivaldi', 'firefox', 'opera', 'iexplore')

# The kiosk browser is identified by its profile folder, set in kiosk-mode.bat:
# BNetKiosk, BNetEdgeKiosk, BNetBraveKiosk, BNetVivaldiKiosk, BNetFirefoxKiosk
$kioskPattern = 'BNet\w*Kiosk'

$seen = $false

while ($true) {
    # Every running browser process with its command line
    $all = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
           Where-Object { $browserNames -contains ($_.Name -replace '\.exe$', '').ToLower() }

    $kiosk = @($all | Where-Object { $_.CommandLine -match $kioskPattern })
    $other = @($all | Where-Object { $_.CommandLine -notmatch $kioskPattern })

    # 1. Close any browser that is not the kiosk (e.g. one started by Windows startup)
    if ($kiosk.Count -gt 0) {
        foreach ($p in $other) {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }

    # 2. Keep only the kiosk window on top
    $kioskWindows = @()
    foreach ($k in $kiosk) {
        $proc = Get-Process -Id $k.ProcessId -ErrorAction SilentlyContinue
        if ($proc -and $proc.MainWindowHandle -ne 0) { $kioskWindows += $proc }
    }

    if ($kioskWindows.Count -gt 0) {
        $seen = $true
        foreach ($w in $kioskWindows) {
            $h = $w.MainWindowHandle
            $ex = [WinApi]::GetWindowLong($h, $GWL_EXSTYLE)
            # Only touch the window if it is not already topmost.
            if (($ex -band $WS_EX_TOPMOST) -eq 0) {
                [WinApi]::SetWindowPos($h, $HWND_TOPMOST, 0, 0, 0, 0, $flags) | Out-Null
            }
        }
    }
    elseif ($seen -and $kiosk.Count -eq 0) {
        break   # kiosk was closed, stop the helper
    }

    Start-Sleep -Seconds 1
}