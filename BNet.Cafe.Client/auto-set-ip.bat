@echo off
setlocal EnableDelayedExpansion
title Static IP Setter - Auto Detect LAN Ethernet
color 0B

:: ------------------------------------------------------------
:: 1. Administrator check
:: ------------------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [ERROR] Right-click this file and choose "Run as administrator".
    echo.
    pause
    exit /b 1
)

:: ------------------------------------------------------------
:: 2. Fixed (automatic) values + fallback defaults
:: ------------------------------------------------------------
set "MASK=255.255.255.0"
set "DNS1=8.8.8.8"
set "DNS2=8.8.4.4"
set "IP=192.168.1.100"
set "GW=192.168.1.1"

set "IDX="
set "ADAPTER="
set "STATUS="
set "CURIP="
set "CURGW="

echo ============================================================
echo            STATIC IP SETUP - LAN ETHERNET (AUTO)
echo ============================================================
echo.
echo  Detecting LAN Ethernet adapter...

:: ------------------------------------------------------------
:: 3. Auto-detect the wired Ethernet adapter (not Wi-Fi)
:: ------------------------------------------------------------
for /f "usebackq tokens=1-3 delims=|" %%a in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$n = Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -eq '802.3' }; $a = $n | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1; if(-not $a){ $a = $n | Select-Object -First 1 }; if(-not $a){ $a = Get-NetAdapter | Where-Object { $_.Name -match 'Ethernet|LAN' -and $_.Name -notmatch 'vEthernet' } | Select-Object -First 1 }; if($a){ '{0}|{1}|{2}' -f $a.ifIndex, $a.Name, $a.Status }"`) do (
    set "IDX=%%a"
    set "ADAPTER=%%b"
    set "STATUS=%%c"
)

if not defined IDX (
    echo.
    echo  [ERROR] No LAN Ethernet adapter was found.
    echo  Adapters on this PC:
    echo.
    powershell -NoProfile -Command "Get-NetAdapter | Format-Table Name, InterfaceDescription, Status -AutoSize"
    pause
    exit /b 1
)

echo  Found       : !ADAPTER!   (Status: !STATUS!)
if /i not "!STATUS!"=="Up" (
    echo.
    echo  [WARNING] This adapter is not connected. Plug in the LAN cable
    echo            or enable the adapter, otherwise you won't see the change.
)

:: ------------------------------------------------------------
:: 4. Auto-detect the CURRENT IP address
:: ------------------------------------------------------------
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "$ip = Get-NetIPAddress -InterfaceIndex !IDX! -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '169.254*' } | Select-Object -First 1; if($ip){ $ip.IPAddress }"`) do set "CURIP=%%i"

:: ------------------------------------------------------------
:: 5. Auto-detect the CURRENT gateway (3 methods, first hit wins)
::    a) default route of this adapter
::    b) adapter configuration (WMI/CIM)
::    c) the system default route
:: ------------------------------------------------------------
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "$i = !IDX!; $g = $null; $r = Get-NetRoute -InterfaceIndex $i -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Where-Object { $_.NextHop -ne '0.0.0.0' } | Sort-Object RouteMetric | Select-Object -First 1; if($r){ $g = $r.NextHop }; if(-not $g){ $c = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter ('InterfaceIndex=' + $i) -ErrorAction SilentlyContinue; if($c -and $c.DefaultIPGateway){ $g = $c.DefaultIPGateway | Where-Object { $_ -notmatch ':' } | Select-Object -First 1 } }; if(-not $g){ $r = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Where-Object { $_.NextHop -ne '0.0.0.0' } | Sort-Object RouteMetric | Select-Object -First 1; if($r){ $g = $r.NextHop } }; if($g){ $g }"`) do set "CURGW=%%i"

if defined CURIP set "IP=!CURIP!"
if defined CURGW set "GW=!CURGW!"

echo.
echo  Subnet Mask : %MASK%   (automatic)
echo  DNS 1       : %DNS1%   (automatic)
echo  DNS 2       : %DNS2%   (automatic)
echo.
echo  Press ENTER to keep the current value.
echo ------------------------------------------------------------
echo.

:: ------------------------------------------------------------
:: 6. IP address: show current, ask for new
:: ------------------------------------------------------------
if defined CURIP (
    echo  Your Current IP Address : !CURIP!
) else (
    echo  Your Current IP Address : not detected
)

:ask_ip
set "INPUT="
set /p "INPUT= Enter New IP Address : "
if defined INPUT set "IP=!INPUT!"
set "CHK=!IP!"
call :validate
if !errorlevel! neq 0 (
    echo   Invalid IP address. Example: 192.168.1.100
    if defined CURIP (set "IP=!CURIP!") else (set "IP=192.168.1.100")
    goto ask_ip
)

:: Gateway default: current gateway if it is on the same network as the
:: new IP, otherwise suggest x.x.x.1
for /f "tokens=1-3 delims=." %%a in ("!IP!") do set "NETP=%%a.%%b.%%c"
set "GW=!NETP!.1"
if defined CURGW (
    for /f "tokens=1-3 delims=." %%a in ("!CURGW!") do (
        if "%%a.%%b.%%c"=="!NETP!" set "GW=!CURGW!"
    )
)

:: ------------------------------------------------------------
:: 7. Gateway: show current, ask for new
:: ------------------------------------------------------------
echo.
if defined CURGW (
    echo  Your Current Gateway    : !CURGW!
) else (
    echo  Your Current Gateway    : not detected
)

:ask_gw
set "INPUT="
set /p "INPUT= Enter New Gateway : "
if defined INPUT set "GW=!INPUT!"
set "CHK=!GW!"
call :validate
if !errorlevel! neq 0 (
    echo   Invalid gateway. Example: 192.168.1.1
    set "GW=!NETP!.1"
    goto ask_gw
)

:: ------------------------------------------------------------
:: 8. Confirm - a single key press, no ENTER needed
:: ------------------------------------------------------------
echo.
echo ------------------------------------------------------------
echo  Adapter     : !ADAPTER!
echo  IP Address  : !IP!
echo  Subnet Mask : %MASK%
echo  Gateway     : !GW!
echo  DNS 1       : %DNS1%
echo  DNS 2       : %DNS2%
echo ------------------------------------------------------------
choice /c YN /n /m "Apply these settings? Press Y = Yes, N = No: "
if errorlevel 2 (
    echo.
    echo Cancelled.
    timeout /t 2 >nul
    exit /b 0
)

:: ------------------------------------------------------------
:: 9. Apply (using the adapter INDEX)
:: ------------------------------------------------------------
echo.
echo Applying settings...
netsh interface ipv4 set address name=!IDX! source=static address=!IP! mask=%MASK% gateway=!GW! >nul
netsh interface ipv4 set dnsservers name=!IDX! source=static address=%DNS1% validate=no >nul
netsh interface ipv4 add dnsservers name=!IDX! address=%DNS2% index=2 validate=no >nul

timeout /t 3 /nobreak >nul

:: ------------------------------------------------------------
:: 10. Verify, then close automatically on success
:: ------------------------------------------------------------
set "WANT=!IP!"
set "APPLIED=False"
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "[bool](Get-NetIPAddress -InterfaceIndex !IDX! -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -eq $env:WANT })"`) do set "APPLIED=%%i"

if /i "!APPLIED!"=="True" (
    color 0A
    echo.
    echo  [OK] SUCCESS - !ADAPTER! now uses !IP!
    echo  This window will close automatically...
    timeout /t 3 >nul
    exit /b 0
)

:: Failure: stay open so the message can be read
color 0C
echo.
echo  [FAILED] The IP address was NOT applied to !ADAPTER!.
echo  Check that:
echo    - you ran this file as Administrator
echo    - the LAN cable is plugged in
echo    - the IP is not used by another device
echo.
netsh interface ipv4 show addresses name=!IDX!
echo.
pause
exit /b 1

:: ------------------------------------------------------------
:: Subroutine: validate IPv4 held in %CHK%
:: ------------------------------------------------------------
:validate
powershell -NoProfile -Command "if($env:CHK -match '^((25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])$'){exit 0}else{exit 1}"
exit /b %errorlevel%
