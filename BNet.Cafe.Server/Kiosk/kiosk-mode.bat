@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: One-time: disable edge-swipe (Task View) and Widgets/News.
:: Asks for administrator ONLY if the policies are missing.
:: ============================================================
if /i "%~1"=="regonly" goto APPLY_POLICY

set "NEED_REG=0"
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" /v AllowEdgeSwipe 2>nul | find "0x0" >nul || set "NEED_REG=1"
reg query "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests 2>nul | find "0x0" >nul || set "NEED_REG=1"

if "!NEED_REG!"=="1" (
    echo Edge-swipe policy missing. Requesting administrator permission once...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList 'regonly' -Verb RunAs -Wait" >nul 2>&1
)

:: The policy is only read when explorer.exe STARTS. If it was written while
:: Explorer was already running (first run on a new PC), the swipe still works
:: until a reboot. So restart Explorer ONCE per user to make it apply now.
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" /v AllowEdgeSwipe 2>nul | find "0x0" >nul
if not errorlevel 1 (
    reg query "HKCU\Software\BNetKiosk" /v ExplorerRestarted >nul 2>&1
    if errorlevel 1 (
        tasklist /fi "imagename eq explorer.exe" 2>nul | find /i "explorer.exe" >nul
        if not errorlevel 1 (
            echo Applying edge-swipe policy: restarting Windows Explorer once...
            taskkill /f /im explorer.exe >nul 2>&1
            timeout /t 2 /nobreak >nul
            start "" explorer.exe
            timeout /t 3 /nobreak >nul
        )
        reg add "HKCU\Software\BNetKiosk" /v ExplorerRestarted /t REG_DWORD /d 1 /f >nul
    )
) else (
    echo WARNING: edge-swipe policy was NOT applied - administrator permission was refused.
    timeout /t 5 /nobreak >nul
)
goto POLICY_DONE

:APPLY_POLICY
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" /v AllowEdgeSwipe /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul
exit /b

:POLICY_DONE

:: ============================================================
:: CONFIG - the only lines you need to edit
:: ============================================================
set "URL=http://localhost:2000/BNet.Cafe.Server/BNetVendoMachine.aspx"

:: Force-close every other application before the kiosk starts (1 = yes, 0 = no)
set "CLOSE_APPS=1"

:: Seconds the kiosk waits after the browser closes before relaunching it.
:: During this time you can press X to enter maintenance mode.
set "RELAUNCH_WAIT=10"

:: Process names (no .exe, comma separated, no spaces) that must NEVER be closed.
set "PROTECT_APPS=explorer,cmd,conhost,WindowsTerminal,powershell,pwsh,iisexpress,w3wp,dotnet,BNet.Cafe.Server,BNetBrowser,msedgewebview2"

:: ============================================================
:: Close existing browsers (they use a lot of RAM)
:: ============================================================
echo Closing existing browser background tasks...
taskkill /F /IM chrome.exe /T >nul 2>&1
taskkill /F /IM msedge.exe /T >nul 2>&1
taskkill /F /IM brave.exe /T >nul 2>&1
taskkill /F /IM vivaldi.exe /T >nul 2>&1
taskkill /F /IM firefox.exe /T >nul 2>&1

:: ============================================================
:: Force-close ALL other applications (anything with a visible window)
:: ============================================================
if "%CLOSE_APPS%"=="1" (
    echo Force closing all other applications...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { (New-Object -ComObject Shell.Application).Windows() | ForEach-Object { $_.Quit() } } catch {}" >nul 2>&1
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$keep = $env:PROTECT_APPS -split ','; Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $keep -notcontains $_.ProcessName -and $_.Id -ne $PID } | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1
    taskkill /F /IM ApplicationFrameHost.exe >nul 2>&1
)

timeout /t 1 /nobreak >nul

:: ============================================================
:: Find BNetBrowser.exe (same folder as this .bat, then C:\Kiosk)
:: ============================================================
set "APP="
if exist "%~dp0BNetBrowser.exe" set "APP=%~dp0BNetBrowser.exe"
if not defined APP if exist "C:\Kiosk\BNetBrowser.exe" set "APP=C:\Kiosk\BNetBrowser.exe"

if not defined APP (
    echo BNetBrowser.exe not found. Put it next to this .bat or in C:\Kiosk
    pause
    exit /b
)

:: ============================================================
:: Main loop: helper + browser. Never exits on its own, because
:: when this .bat is the Windows shell, ending it signs the user out.
:: ============================================================
:RUN
if exist "%~dp0kiosk-mode.ps1" (
    echo Starting always-on-top helper...
    start "" /min powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0kiosk-mode.ps1"
)

echo Launching BNetBrowser in kiosk mode...
start "" /wait "!APP!" --kiosk "%URL%"

:: Browser closed (crash, Alt+F4, ...). Relaunch unless X is pressed.
cls
echo Kiosk closed. Restarting in %RELAUNCH_WAIT% seconds...
echo Press X to stop the kiosk and enter maintenance mode.
choice /c RX /t %RELAUNCH_WAIT% /d R /n >nul
if errorlevel 2 goto MAINT
goto RUN

:: ============================================================
:: Maintenance mode: brings back the normal Windows desktop
:: ============================================================
:MAINT
cls
echo MAINTENANCE MODE - Windows Explorer started.
echo Press any key (or close this window) to sign out.
start "" explorer.exe
pause >nul
exit /b