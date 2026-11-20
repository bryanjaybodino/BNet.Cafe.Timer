@echo off
setlocal EnableExtensions
title Full Reset - Processes, Browsers, Downloads

echo [1/4] Closing browsers...
taskkill /F /IM chrome.exe /T >nul 2>&1
taskkill /F /IM msedge.exe /T >nul 2>&1
taskkill /F /IM brave.exe /T >nul 2>&1
taskkill /F /IM vivaldi.exe /T >nul 2>&1
taskkill /F /IM firefox.exe /T >nul 2>&1

echo [2/4] Closing all other apps owned by you...
rem Only your own processes are touched (no admin needed).
rem Explorer and this script's window are skipped so Windows stays usable.
taskkill /F /FI "USERNAME eq %USERDOMAIN%\%USERNAME%" ^
  /FI "IMAGENAME ne explorer.exe" ^
  /FI "IMAGENAME ne cmd.exe" ^
  /FI "IMAGENAME ne conhost.exe" ^
  /FI "IMAGENAME ne taskkill.exe" ^
  /FI "IMAGENAME ne tasklist.exe" ^
  /FI "IMAGENAME ne powershell.exe" ^
  /FI "IMAGENAME ne WindowsTerminal.exe" ^
  /FI "IMAGENAME ne sihost.exe" ^
  /FI "IMAGENAME ne ctfmon.exe" ^
  /FI "IMAGENAME ne dwm.exe" ^
  /FI "IMAGENAME ne StartMenuExperienceHost.exe" ^
  /FI "IMAGENAME ne ShellExperienceHost.exe" ^
  /FI "IMAGENAME ne SearchHost.exe" ^
  /FI "IMAGENAME ne TextInputHost.exe" ^
  /FI "IMAGENAME ne RuntimeBroker.exe" ^
  /FI "IMAGENAME ne taskhostw.exe" ^
  /FI "IMAGENAME ne BNet*" >nul 2>&1

rem Give processes a moment to release file locks
timeout /t 3 /nobreak >nul

echo [3/4] Wiping browser data...
call :wipe "%LOCALAPPDATA%\Google\Chrome\User Data"
call :wipe "%LOCALAPPDATA%\Microsoft\Edge\User Data"
call :wipe "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"
call :wipe "%LOCALAPPDATA%\Vivaldi\User Data"
call :wipe "%APPDATA%\Mozilla\Firefox\Profiles"
call :wipe "%LOCALAPPDATA%\Mozilla\Firefox\Profiles"
del /f /q "%APPDATA%\Mozilla\Firefox\profiles.ini" >nul 2>&1
del /f /q "%APPDATA%\Mozilla\Firefox\installs.ini" >nul 2>&1

echo [4/4] Emptying Downloads folder...
set "DL=%USERPROFILE%\Downloads"
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "(New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path" 2^>nul`) do set "DL=%%D"

if exist "%DL%\" (
    del /f /s /q "%DL%\*" >nul 2>&1
    for /d %%I in ("%DL%\*") do rd /s /q "%%I" >nul 2>&1
)

echo.
echo ============================================================
echo  Done. Browsers are reset and Downloads is empty.
echo  Tip: restart your PC if you want a completely clean state.
echo ============================================================
timeout /t 5 >nul
exit /b

:wipe
if exist "%~1\" (
    rd /s /q "%~1" >nul 2>&1
)
exit /b