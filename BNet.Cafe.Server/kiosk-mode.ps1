Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinApi {
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
        int X, int Y, int cx, int cy, uint uFlags);
}
"@

$HWND_TOPMOST = [IntPtr](-1)
$flags = 0x0001 -bor 0x0002 -bor 0x0040   # NOSIZE | NOMOVE | SHOWWINDOW
$seen = $false

while ($true) {
    $procs = Get-Process chrome, msedge, firefox -ErrorAction SilentlyContinue |
             Where-Object { $_.MainWindowHandle -ne 0 }

    if ($procs) {
        $seen = $true
        foreach ($p in $procs) {
            [WinApi]::SetWindowPos($p.MainWindowHandle, $HWND_TOPMOST, 0, 0, 0, 0, $flags) | Out-Null
        }
    }
    elseif ($seen) {
        break   # browser was closed, stop the helper
    }

    Start-Sleep -Seconds 2
}
