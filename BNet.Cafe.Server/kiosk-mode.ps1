# ============================================================================
# Kiosk helper
#  - closes any browser that is not the kiosk instance
#  - keeps the kiosk window TOPMOST
#  - makes sure the kiosk window really owns KEYBOARD FOCUS (the fix for
#    "keyboard does nothing until I click with the mouse")
# ============================================================================
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinApi {
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
        int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll", EntryPoint = "GetWindowLong")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
"@

$HWND_TOPMOST  = [IntPtr](-1)
$GWL_EXSTYLE   = -20
$WS_EX_TOPMOST = 0x00000008
$SW_RESTORE    = 9

# NOSIZE | NOMOVE | NOACTIVATE  (topmost call itself must not steal focus)
$flags = 0x0001 -bor 0x0002 -bor 0x0010

# Set to $false if you do NOT want the kiosk to take keyboard focus back.
$KeepKeyboardFocus = $true

# Give the foreground to the kiosk window. Windows blocks plain
# SetForegroundWindow() from background processes, so we attach to the
# current foreground thread (and fall back to an ALT key tap) to be allowed.
function Set-KioskForeground([IntPtr]$h) {
    if ([WinApi]::IsIconic($h)) { [WinApi]::ShowWindow($h, $SW_RESTORE) | Out-Null }

    $fg = [WinApi]::GetForegroundWindow()
    $fgPid = [uint32]0
    $fgThread = [WinApi]::GetWindowThreadProcessId($fg, [ref]$fgPid)
    $myThread = [WinApi]::GetCurrentThreadId()

    $attached = $false
    if ($fgThread -ne 0 -and $fgThread -ne $myThread) {
        $attached = [WinApi]::AttachThreadInput($myThread, $fgThread, $true)
    }
    [WinApi]::BringWindowToTop($h) | Out-Null
    [WinApi]::SetForegroundWindow($h) | Out-Null
    if ($attached) { [WinApi]::AttachThreadInput($myThread, $fgThread, $false) | Out-Null }

    # Fallback: a synthetic ALT tap unlocks SetForegroundWindow
    if ([WinApi]::GetForegroundWindow() -ne $h) {
        [WinApi]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)   # ALT down
        [WinApi]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)   # ALT up
        [WinApi]::SetForegroundWindow($h) | Out-Null
    }
}

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

        # 3. Make sure the kiosk owns keyboard focus.
        # Only act when the foreground window belongs to some OTHER program
        # (cmd window, Explorer, a leftover app...). If the foreground window is
        # any kiosk-browser process (including the Web Serial port picker),
        # leave it alone so we never steal focus from it.
        if ($KeepKeyboardFocus) {
            $fg = [WinApi]::GetForegroundWindow()
            if ($fg -ne [IntPtr]::Zero) {            # 0 = secure desktop / transition
                $fgPid = [uint32]0
                [WinApi]::GetWindowThreadProcessId($fg, [ref]$fgPid) | Out-Null
                $kioskPids = @($kiosk | ForEach-Object { [uint32]$_.ProcessId })
                if ($kioskPids -notcontains $fgPid) {
                    Set-KioskForeground $kioskWindows[0].MainWindowHandle
                }
            }
        }
    }
    elseif ($seen -and $kiosk.Count -eq 0) {
        break   # kiosk was closed, stop the helper
    }

    Start-Sleep -Milliseconds 500
}