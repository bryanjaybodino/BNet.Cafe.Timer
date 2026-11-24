@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: CONFIG - the only lines you need to edit
:: ============================================================
set "URL=http://localhost:2000/BNet.Cafe.Server/BNetVendoMachine.aspx"

:: Optional explicit folder for BNetBrowser.exe (leave blank to auto-detect)
set "BROWSER_DIR="

:: Set to 1 to use kiosk-loader.html (if present next to this .bat), 0 for direct URL
set "USE_LOADER=0"

:: Force-close every other application before the kiosk starts (1 = yes, 0 = no)
set "CLOSE_APPS=1"

:: Process names (no .exe, comma separated, no spaces) that must NEVER be closed.
set "PROTECT_APPS=explorer,cmd,conhost,WindowsTerminal,powershell,pwsh,iisexpress,w3wp,dotnet,BNet.Cafe.Server,BNetBrowser,msedgewebview2"

:: ============================================================
:: Paths & Task Setup
:: ============================================================
set "TASK_NAME=BNetKiosk"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "LOG_FILE=%SCRIPT_DIR%\kiosk-launch.log"
set "RUNNER_BAT=%SCRIPT_DIR%\run-bnetkiosk.cmd"

if /i "%~1"=="/maint" goto MAINT
if /i "%~1"=="/fromtask" goto TASK_DONE

:: Elevate to Administrator if needed
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Write a dedicated runner script so Task Scheduler /tr needs zero nested quotes
(
    echo @echo off
    echo cd /d "%SCRIPT_DIR%"
    echo call "%~f0" /fromtask
) > "%RUNNER_BAT%"

echo Creating scheduled task "%TASK_NAME%"...
schtasks /create /tn "%TASK_NAME%" /tr "\"%RUNNER_BAT%\"" /sc onlogon /rl highest /f
if errorlevel 1 (
    echo [ERROR] schtasks /create failed.
    pause
    exit /b 1
)

echo Running scheduled task "%TASK_NAME%"...
schtasks /run /tn "%TASK_NAME%"
if errorlevel 1 (
    echo [ERROR] schtasks /run failed. Running directly...
    goto TASK_DONE
)

timeout /t 2 /nobreak >nul
schtasks /query /tn "%TASK_NAME%" /fo LIST /v | findstr /i "Status Last Run Result"
exit /b

:TASK_DONE
cd /d "%SCRIPT_DIR%"
echo [%DATE% %TIME%] TASK_DONE started in "%SCRIPT_DIR%" > "%LOG_FILE%"

:: ============================================================
:: Close existing browsers
:: ============================================================
echo Closing existing browser background tasks... >> "%LOG_FILE%"
taskkill /F /IM chrome.exe /T >nul 2>&1
taskkill /F /IM msedge.exe /T >nul 2>&1
taskkill /F /IM brave.exe /T >nul 2>&1
taskkill /F /IM vivaldi.exe /T >nul 2>&1
taskkill /F /IM firefox.exe /T >nul 2>&1

:: ============================================================
:: Force-close other visible applications
:: ============================================================
if "%CLOSE_APPS%"=="1" (
    echo Force closing other applications... >> "%LOG_FILE%"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { (New-Object -ComObject Shell.Application).Windows() | ForEach-Object { $_.Quit() } } catch {}" >nul 2>&1
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$keep = $env:PROTECT_APPS -split ','; Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $keep -notcontains $_.ProcessName -and $_.Id -ne $PID } | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1
    taskkill /F /IM ApplicationFrameHost.exe >nul 2>&1
)

timeout /t 1 /nobreak >nul

:: ============================================================
:: Dynamically find BNetBrowser.exe
:: ============================================================
set "APP="

if defined BROWSER_DIR (
    set "CLEAN_BDIR=%BROWSER_DIR%"
    if "!CLEAN_BDIR:~-1!"=="\" set "CLEAN_BDIR=!CLEAN_BDIR:~0,-1!"
    if exist "!CLEAN_BDIR!\BNetBrowser.exe" set "APP=!CLEAN_BDIR!\BNetBrowser.exe"
)

if not defined APP if exist "%SCRIPT_DIR%\BNetBrowser.exe" set "APP=%SCRIPT_DIR%\BNetBrowser.exe"
if not defined APP if exist "%SCRIPT_DIR%\BNetBrowser\BNetBrowser.exe" set "APP=%SCRIPT_DIR%\BNetBrowser\BNetBrowser.exe"
if not defined APP if exist "%SCRIPT_DIR%\Browser\BNetBrowser.exe" set "APP=%SCRIPT_DIR%\Browser\BNetBrowser.exe"
if not defined APP if exist "%SCRIPT_DIR%\bin\BNetBrowser.exe" set "APP=%SCRIPT_DIR%\bin\BNetBrowser.exe"
if not defined APP if exist "%SCRIPT_DIR%\..\BNetBrowser\BNetBrowser.exe" set "APP=%SCRIPT_DIR%\..\BNetBrowser\BNetBrowser.exe"
if not defined APP if exist "%SCRIPT_DIR%\..\BNetBrowser.exe" set "APP=%SCRIPT_DIR%\..\BNetBrowser.exe"
if not defined APP if exist "%CD%\BNetBrowser.exe" set "APP=%CD%\BNetBrowser.exe"

if not defined APP (
    for /f "delims=" %%P in ('where BNetBrowser.exe 2^>nul') do (
        if not defined APP set "APP=%%P"
    )
)

if not defined APP if exist "C:\Kiosk\BNetBrowser.exe" set "APP=C:\Kiosk\BNetBrowser.exe"

if not defined APP (
    echo [ERROR] BNetBrowser.exe not found. Checked "%SCRIPT_DIR%" and common subfolders/parent. >> "%LOG_FILE%"
    echo BNetBrowser.exe not found. Check "%LOG_FILE%".
    pause
    exit /b 1
)

for %%F in ("!APP!") do set "APP_DIR=%%~dpF"
if "%APP_DIR:~-1%"=="\" set "APP_DIR=%APP_DIR:~0,-1%"
echo Found BNetBrowser at "!APP!" >> "%LOG_FILE%"

:: ============================================================
:: Determine target URL / loader
:: ============================================================
set "LAUNCH_TARGET=%URL%"
if "%USE_LOADER%"=="1" if exist "%SCRIPT_DIR%\kiosk-loader.html" (
    for %%L in ("%SCRIPT_DIR%\kiosk-loader.html") do set "LOADER_URI=file:///%%~fL"
    set "LOADER_URI=!LOADER_URI:\=/!"
    set "LOADER_URI=!LOADER_URI: =%%20!"
    set "LAUNCH_TARGET=!LOADER_URI!#%URL%"
)

:: ============================================================
:: Start helper + browser
:: ============================================================
:RUN
if exist "%SCRIPT_DIR%\kiosk-mode.ps1" (
    echo Starting kiosk-mode.ps1 helper... >> "%LOG_FILE%"
    start "" /min powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\kiosk-mode.ps1"
)

echo Launching "!APP!" with target "!LAUNCH_TARGET!" >> "%LOG_FILE%"
start "" /d "!APP_DIR!" /wait "!APP!" --kiosk "!LAUNCH_TARGET!"

echo Browser exited. Exiting script. >> "%LOG_FILE%"
exit /b

:: ============================================================
:: Maintenance mode
:: ============================================================
:MAINT
cls
echo MAINTENANCE MODE - Windows Explorer started.
echo Press any key (or close this window) to sign out.
start "" explorer.exe
pause >nul
exit /b