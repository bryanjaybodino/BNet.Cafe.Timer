@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: CONFIG - the only lines you need to edit
:: ============================================================
set "URL=http://localhost:2000/BNet.Cafe.Server/BNetVendoMachine.aspx"

:: Force-close every other application before the kiosk starts (1 = yes, 0 = no)
set "CLOSE_APPS=1"

:: Process names (no .exe, comma separated, no spaces) that must NEVER be closed.
set "PROTECT_APPS=explorer,cmd,conhost,WindowsTerminal,powershell,pwsh,iisexpress,w3wp,dotnet,BNet.Cafe.Server,BNetBrowser,msedgewebview2"

:: ============================================================
:: Register this .bat in Task Scheduler as "BNetKiosk"
:: (runs at logon with highest privileges)
:: ============================================================
set "TASK_NAME=BNetKiosk"

:: When started by the scheduled task, skip registration and run the kiosk
if /i "%~1"=="/fromtask" goto TASK_DONE

:: Not admin? Relaunch this .bat elevated (UAC prompt)
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Saving task "%TASK_NAME%" to Task Scheduler...
schtasks /create /tn "%TASK_NAME%" /tr "powershell -NoProfile -WindowStyle Hidden -Command \"Start-Process -WindowStyle Hidden -FilePath '%~f0' -ArgumentList '/fromtask'\"" /sc onlogon /rl highest /f >nul 2>&1
if errorlevel 1 (
    echo Failed to create the scheduled task.
    pause
    exit /b 1
)
echo Task created. Starting it with highest privileges...
schtasks /run /tn "%TASK_NAME%" >nul 2>&1
exit /b

:TASK_DONE

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

:: Browser closed: do NOT relaunch, just close this window.
exit /b

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