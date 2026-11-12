@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: CONFIG - the only lines you need to edit
:: ============================================================
set "URL=http://localhost:2000/BNet.Cafe.Server/BNetVendoMachine.aspx"

:: Origin (scheme + host + port) is extracted automatically from URL.
:: Needed so Web Serial works over plain HTTP.
for /f "tokens=1,2 delims=/" %%a in ("%URL%") do set "ORIGIN=%%a//%%b"

:: Force-close every other application before the kiosk starts (1 = yes, 0 = no)
set "CLOSE_APPS=1"

:: Process names (no .exe, comma separated, no spaces) that must NEVER be closed.
:: Add your server / helper apps here if they have a visible window.
set "PROTECT_APPS=explorer,cmd,conhost,WindowsTerminal,powershell,pwsh,iisexpress,w3wp,dotnet,BNet.Cafe.Server"

:: Lightweight / low-resource flags (Chromium browsers only).
:: None of these affect WebSocket or Server-Sent Events (SSE).
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

    :: Close File Explorer windows without killing the taskbar/desktop
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { (New-Object -ComObject Shell.Application).Windows() | ForEach-Object { $_.Quit() } } catch {}" >nul 2>&1

    :: Kill every process that owns a visible window, except protected ones
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$keep = $env:PROTECT_APPS -split ','; Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $keep -notcontains $_.ProcessName -and $_.Id -ne $PID } | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1

    :: Close Microsoft Store / UWP app windows (Settings, Calculator, etc.)
    taskkill /F /IM ApplicationFrameHost.exe >nul 2>&1
)

timeout /t 1 /nobreak >nul

:: ============================================================
:: Always-on-top helper (only if the script exists)
:: ============================================================
if exist "%~dp0kiosk-mode.ps1" (
    echo Starting always-on-top helper...
    start "" /min powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0kiosk-mode.ps1"
) else (
    echo kiosk-mode.ps1 not found, skipping always-on-top helper.
)

echo Launching True Full Screen Mode...

:: NOTE: Browser profiles are stored in %LOCALAPPDATA% (NOT %TEMP%) so the
:: Web Serial COM port permission survives reboots and temp cleanups.
:: The folder names must keep the BNet...Kiosk pattern used by kiosk-mode.ps1.

:: ============================================================
:: 1. Google Chrome
:: ============================================================
set "BROWSER="
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    set "BROWSER=C:\Program Files\Google\Chrome\Application\chrome.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetKiosk"
    goto LAUNCH
)
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    set "BROWSER=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetKiosk"
    goto LAUNCH
)

:: ============================================================
:: 2. Microsoft Edge
:: ============================================================
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    set "BROWSER=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetEdgeKiosk"
    goto LAUNCH
)
if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
    set "BROWSER=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetEdgeKiosk"
    goto LAUNCH
)

:: ============================================================
:: 3. Brave Browser (Lightweight / Privacy Chromium option)
:: ============================================================
if exist "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" (
    set "BROWSER=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetBraveKiosk"
    goto LAUNCH
)
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe" (
    set "BROWSER=%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetBraveKiosk"
    goto LAUNCH
)

:: ============================================================
:: 4. Vivaldi Browser
:: ============================================================
if exist "%LOCALAPPDATA%\Vivaldi\Application\vivaldi.exe" (
    set "BROWSER=%LOCALAPPDATA%\Vivaldi\Application\vivaldi.exe"
    set "PROFILE_DIR=%LOCALAPPDATA%\BNetVivaldiKiosk"
    goto LAUNCH
)

:: ============================================================
:: 5. Firefox (Last Fallback - Note: Web Serial not supported)
:: ============================================================
set "FIREFOX="
if exist "C:\Program Files\Mozilla Firefox\firefox.exe" set "FIREFOX=C:\Program Files\Mozilla Firefox\firefox.exe"
if not defined FIREFOX if exist "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" set "FIREFOX=C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
if defined FIREFOX (
    start "" "!FIREFOX!" -kiosk "!START_URL!" -no-remote -profile "%LOCALAPPDATA%\BNetFirefoxKiosk"
    exit /b
)

echo No supported browser found.
pause
exit /b

:: ============================================================
:: Universal Chromium Launch Routine
:: ============================================================
:LAUNCH
start "" "!BROWSER!" --app="!START_URL!" --kiosk --user-data-dir="!PROFILE_DIR!" --allow-file-access-from-files --unsafely-treat-insecure-origin-as-secure="%ORIGIN%" !PERF_FLAGS!
exit /b