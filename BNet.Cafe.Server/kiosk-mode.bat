@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: CONFIG - the only lines you need to edit
:: ============================================================
set "URL=http://localhost:2000/BNet.Cafe.Server/BNetVendoMachine.aspx"

:: Origin (scheme + host + port) is extracted automatically from URL.
:: Needed so Web Serial works over plain HTTP.
for /f "tokens=1,2 delims=/" %%a in ("%URL%") do set "ORIGIN=%%a//%%b"

:: ============================================================
:: Auto-detect kiosk-loader.html (same folder as this .bat first)
:: ============================================================
set "LOADING_FILE="
if exist "%~dp0kiosk-loader.html" set "LOADING_FILE=%~dp0kiosk-loader.html"
if not defined LOADING_FILE if exist "%cd%\kiosk-loader.html" set "LOADING_FILE=%cd%\kiosk-loader.html"
if not defined LOADING_FILE if exist "C:\Kiosk\kiosk-loader.html" set "LOADING_FILE=C:\Kiosk\kiosk-loader.html"

if defined LOADING_FILE (
    echo Found loading page: !LOADING_FILE!
    :: Convert Windows path to a file:// URL
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
taskkill /F /IM firefox.exe /T >nul 2>&1

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

:: ============================================================
:: Chrome
:: ============================================================
set "CHROME="
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set "CHROME=C:\Program Files\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set "CHROME=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
if defined CHROME (
    start "" "!CHROME!" --app="!START_URL!" --kiosk --user-data-dir="%TEMP%\BNetKiosk" --allow-file-access-from-files --unsafely-treat-insecure-origin-as-secure="%ORIGIN%"
    exit /b
)

:: ============================================================
:: Edge (fallback)
:: ============================================================
set "EDGE="
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" set "EDGE=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if not defined EDGE if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" set "EDGE=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
if defined EDGE (
    start "" "!EDGE!" --app="!START_URL!" --kiosk --user-data-dir="%TEMP%\BNetEdgeKiosk" --allow-file-access-from-files --unsafely-treat-insecure-origin-as-secure="%ORIGIN%"
    exit /b
)

:: ============================================================
:: Firefox (last fallback) - NOTE: Firefox does not support Web Serial
:: ============================================================
set "FIREFOX="
if exist "C:\Program Files\Mozilla Firefox\firefox.exe" set "FIREFOX=C:\Program Files\Mozilla Firefox\firefox.exe"
if not defined FIREFOX if exist "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" set "FIREFOX=C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
if defined FIREFOX (
    start "" "!FIREFOX!" -kiosk "!START_URL!" -no-remote -profile "%TEMP%\BNetFirefoxKiosk"
    exit /b
)

echo No supported browser found.
pause