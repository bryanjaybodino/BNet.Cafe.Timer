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

:: Origin (scheme + host + port) is extracted automatically from URL.
:: Needed so Web Serial works over plain HTTP.
for /f "tokens=1,2 delims=/" %%a in ("%URL%") do set "ORIGIN=%%a//%%b"

:: Force-close every other application before the kiosk starts (1 = yes, 0 = no)
set "CLOSE_APPS=1"

:: Seconds the kiosk waits after the browser closes before relaunching it.
:: During this time you can press X to enter maintenance mode.
set "RELAUNCH_WAIT=10"

:: Process names (no .exe, comma separated, no spaces) that must NEVER be closed.
set "PROTECT_APPS=explorer,cmd,conhost,WindowsTerminal,powershell,pwsh,iisexpress,w3wp,dotnet,BNet.Cafe.Server"

:: Fresh-PC friendly flags
set "KIOSK_FLAGS=--no-first-run --no-default-browser-check --disable-session-crashed-bubble --disable-infobars --autoplay-policy=no-user-gesture-required --overscroll-history-navigation=0 --disable-pinch"

set "PERF_FLAGS=--disable-extensions --disable-background-networking --disable-sync --disable-translate --disable-features=Translate,OptimizationHints --renderer-process-limit=1 --disk-cache-size=52428800 --js-flags=--max-old-space-size=256"

:: ============================================================
:: Auto-detect kiosk-loader.html (same folder as this .bat first)
:: ============================================================
set "LOADING_FILE="
if exist "%~dp0kiosk-loader.html" set "LOADING_FILE=%~dp0kiosk-loader.html"
if not defined LOADING_FILE if exist "%cd%\kiosk-loader.html" set "LOADING_FILE=%cd%\kiosk-loader.html"
if not defined LOADING_FILE if exist "C:\Kiosk\kiosk-loader.html" set "LOADING_FILE=C:\Kiosk\kiosk-loader.html"

if defined LOADING_FILE (
    echo Found loading page: !LOADING_FILE!
    set "LP=!LOADING_FILE:\=/!"
    set "LP=!LP: =%%20!"
    set "START_URL=file:///!LP!#%URL%"
) else (
    echo WARNING: kiosk-loader.html not found. Opening the server URL directly.
    set "START_URL=%URL%"
)

:: ============================================================
:: Close existing browsers
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
:: Pick a browser
:: NOTE: Profiles live in %LOCALAPPDATA% so the Web Serial COM port
:: permission survives reboots. Folder names must keep the BNet...Kiosk
:: pattern used by kiosk-mode.ps1.
:: ============================================================
set "BROWSER="
set "FIREFOX="

if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    set "BROWSER=C:\Program Files\Google\Chrome\Application\chrome.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetKiosk"
    goto RUN
)
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    set "BROWSER=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetKiosk"
    goto RUN
)
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    set "BROWSER=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetEdgeKiosk"
    goto RUN
)
if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
    set "BROWSER=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetEdgeKiosk"
    goto RUN
)
if exist "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" (
    set "BROWSER=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetBraveKiosk"
    goto RUN
)
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe" (
    set "BROWSER=%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetBraveKiosk"
    goto RUN
)
if exist "%LOCALAPPDATA%\Vivaldi\Application\vivaldi.exe" (
    set "BROWSER=%LOCALAPPDATA%\Vivaldi\Application\vivaldi.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetVivaldiKiosk"
    goto RUN
)

:: Firefox = last fallback (Web Serial NOT supported)
if exist "C:\Program Files\Mozilla Firefox\firefox.exe" set "FIREFOX=C:\Program Files\Mozilla Firefox\firefox.exe"
if not defined FIREFOX if exist "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" set "FIREFOX=C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
if defined FIREFOX goto RUN

echo No supported browser found.
pause
exit /b

:: ============================================================
:: Main loop: helper + browser. Never exits on its own, because
:: when this .bat is the Windows shell, ending it signs the user out.
:: ============================================================
:RUN
if exist "%~dp0kiosk-mode.ps1" (
    echo Starting always-on-top helper...
    start "" /min powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0kiosk-mode.ps1"
)

echo Launching True Full Screen Mode...
if defined FIREFOX (
    start "" /wait "!FIREFOX!" -kiosk "!START_URL!" -no-remote -profile "%LOCALAPPDATA%\BNetFirefoxKiosk"
) else (
    start "" /wait "!BROWSER!" --app="!START_URL!" --kiosk --user-data-dir="!PROFILE_DIR!" --allow-file-access-from-files --unsafely-treat-insecure-origin-as-secure="%ORIGIN%" !PERF_FLAGS! !KIOSK_FLAGS!
)

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