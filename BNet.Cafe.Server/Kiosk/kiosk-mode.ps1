# ============================================================================
# Kiosk helper
#  - closes any browser that is not the kiosk instance
#  - keeps the kiosk window TOPMOST and owning KEYBOARD FOCUS
#  - ALT+TAB is allowed: pressing it pauses topmost/focus enforcement for
#    $PauseSeconds so you can switch to / close other windows
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

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
"@

$HWND_TOPMOST   = [IntPtr](-1)
$HWND_NOTOPMOST = [IntPtr](-2)
$GWL_EXSTYLE    = -20
$WS_EX_TOPMOST  = 0x00000008
$SW_RESTORE     = 9

# NOSIZE | NOMOVE | NOACTIVATE  (these calls must not steal focus)
$flags = 0x0001 -bor 0x0002 -bor 0x0010

# Set to $false if you do NOT want the kiosk to take keyboard focus back.
$KeepKeyboardFocus = $true

# How long enforcement stays paused after an Alt+Tab press
$PauseSeconds = 60

function Test-AltTab {
    # GetAsyncKeyState is negative while the key is physically down
    ([WinApi]::GetAsyncKeyState(0x12) -lt 0) -and ([WinApi]::GetAsyncKeyState(0x09) -lt 0)
}

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

    if ([WinApi]::GetForegroundWindow() -ne $h) {
        [WinApi]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)   # ALT down
        [WinApi]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)   # ALT up
        [WinApi]::SetForegroundWindow($h) | Out-Null
    }
}

$browserNames = @('chrome', 'msedge', 'brave', 'vivaldi', 'firefox', 'opera', 'iexplore', 'bnetbrowser')

# Kiosk is identified by its profile folder, or by BNetBrowser.exe itself
$kioskPattern = 'BNet\w*Kiosk|BNetBrowser'

$seen       = $false
$pauseUntil = [datetime]::MinValue
$tick       = 0

while ($true) {
    # Check the keyboard every 100 ms so a quick Alt+Tab is never missed
    if (Test-AltTab) { $pauseUntil = (Get-Date).AddSeconds($PauseSeconds) }

    $tick++
    if ($tick % 5 -ne 0) { Start-Sleep -Milliseconds 100; continue }

    $paused = (Get-Date) -lt $pauseUntil

    $allProcs = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)

    $all = $allProcs |
           Where-Object { $browserNames -contains ($_.Name -replace '\.exe$', '').ToLower() }

    $kiosk = @($all | Where-Object { $_.CommandLine -match $kioskPattern })
    $other = @($all | Where-Object { $_.CommandLine -notmatch $kioskPattern })

    # Kiosk process TREE: BNetBrowser.exe + every child it started
    # (msedgewebview2.exe, and the popups it owns such as the serial-port
    # chooser, permission prompts, file dialogs). These must never be treated
    # as "foreign" windows, otherwise stealing focus closes the popup.
    $kioskTree = New-Object 'System.Collections.Generic.HashSet[uint32]'
    foreach ($k in $kiosk) { [void]$kioskTree.Add([uint32]$k.ProcessId) }
    foreach ($p in $allProcs) {
        if ($p.Name -like 'msedgewebview2*' -and $p.CommandLine -match $kioskPattern) {
            [void]$kioskTree.Add([uint32]$p.ProcessId)
        }
    }
    do {
        $added = $false
        foreach ($p in $allProcs) {
            if ($kioskTree.Contains([uint32]$p.ParentProcessId) -and
                -not $kioskTree.Contains([uint32]$p.ProcessId)) {
                [void]$kioskTree.Add([uint32]$p.ProcessId)
                $added = $true
            }
        }
    } while ($added)

    # 1. Close any browser that is not the kiosk
    if ($kiosk.Count -gt 0) {
        foreach ($p in $other) {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }

    # 2. Topmost handling
    $kioskWindows = @()
    foreach ($k in $kiosk) {
        $proc = Get-Process -Id $k.ProcessId -ErrorAction SilentlyContinue
        if ($proc -and $proc.MainWindowHandle -ne 0) { $kioskWindows += $proc }
    }

    if ($kioskWindows.Count -gt 0) {
        $seen = $true
        foreach ($w in $kioskWindows) {
            $h  = $w.MainWindowHandle
            $ex = [WinApi]::GetWindowLong($h, $GWL_EXSTYLE)
            $isTop = (($ex -band $WS_EX_TOPMOST) -ne 0)

            if ($paused -and $isTop) {
                # Let other windows appear above the kiosk during Alt+Tab
                [WinApi]::SetWindowPos($h, $HWND_NOTOPMOST, 0, 0, 0, 0, $flags) | Out-Null
            }
            elseif (-not $paused -and -not $isTop) {
                [WinApi]::SetWindowPos($h, $HWND_TOPMOST, 0, 0, 0, 0, $flags) | Out-Null
            }
        }

        # 3. Keyboard focus (skipped while paused)
        if ($KeepKeyboardFocus -and -not $paused) {
            $fg = [WinApi]::GetForegroundWindow()
            if ($fg -ne [IntPtr]::Zero) {
                $fgPid = [uint32]0
                [WinApi]::GetWindowThreadProcessId($fg, [ref]$fgPid) | Out-Null
                if (-not $kioskTree.Contains([uint32]$fgPid)) {
                    Set-KioskForeground $kioskWindows[0].MainWindowHandle
                }
            }
        }
    }
    elseif ($seen -and $kiosk.Count -eq 0) {
        break   # kiosk was closed; the .bat starts a fresh helper on relaunch
    }

    Start-Sleep -Milliseconds 100
}