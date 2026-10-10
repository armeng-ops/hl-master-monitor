@echo off
setlocal enabledelayedexpansion

echo ========================================================================
echo       Building Half-Life ^& GoldSrc MasterServer Monitor [Win32 + Win64]
echo ========================================================================

cd /d "%~dp0"

:: 0. Ensure all source files (.pas, .dfm, .dpr) have UTF-8 BOM so Delphi compiler renders strings properly
echo [INFO] Normalizing UTF-8 BOM encoding for Delphi compiler...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$enc = New-Object System.Text.UTF8Encoding $true; Get-ChildItem -Path . -Include *.pas,*.dfm,*.dpr -Recurse | ForEach-Object { $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8); [System.IO.File]::WriteAllText($_.FullName, $text, $enc) }"

:: 1. Initialize Delphi environment if rsvars.bat exists
if exist "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\rsvars.bat" (
    call "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\rsvars.bat" >nul 2>nul
)

set "DCC32="
set "DCC64="
set "BDS_LIB32="
set "BDS_LIB64="

:: 2. Check Delphi 10.3 Rio (Default installed version 20.0)
if exist "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\dcc32.exe" (
    set "DCC32=C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\dcc32.exe"
    set "DCC64=C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\dcc64.exe"
    set "BDS_LIB32=C:\Program Files (x86)\Embarcadero\Studio\20.0\lib\win32\release"
    set "BDS_LIB64=C:\Program Files (x86)\Embarcadero\Studio\20.0\lib\win64\release"
    goto :FOUND_COMPILER
)

:: 3. Check other Studio versions if present
for %%V in (23.0 22.0 21.0 19.0 18.0) do (
    if exist "C:\Program Files (x86)\Embarcadero\Studio\%%V\bin\dcc32.exe" (
        set "DCC32=C:\Program Files (x86)\Embarcadero\Studio\%%V\bin\dcc32.exe"
        set "DCC64=C:\Program Files (x86)\Embarcadero\Studio\%%V\bin\dcc64.exe"
        set "BDS_LIB32=C:\Program Files (x86)\Embarcadero\Studio\%%V\lib\win32\release"
        set "BDS_LIB64=C:\Program Files (x86)\Embarcadero\Studio\%%V\lib\win64\release"
        goto :FOUND_COMPILER
    )
)

:: 4. Check PATH
where dcc32.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    set "DCC32=dcc32.exe"
    where dcc64.exe >nul 2>nul
    if %ERRORLEVEL% equ 0 set "DCC64=dcc64.exe"
    if defined BDS (
        set "BDS_LIB32=%BDS%\lib\win32\release"
        set "BDS_LIB64=%BDS%\lib\win64\release"
    )
    goto :FOUND_COMPILER
)

echo [ERROR] Delphi compiler dcc32.exe not found!
echo Please ensure Embarcadero RAD Studio / Delphi is installed.
exit /b 1

:FOUND_COMPILER
echo [INFO] Found 32-bit compiler: "%DCC32%"
if exist "%DCC64%" echo [INFO] Found 64-bit compiler: "%DCC64%"

:: Compile resources if brcc32 exists
set "BRCC32=%DCC32:\dcc32.exe=\brcc32.exe%"
if exist "%BRCC32%" (
    echo [INFO] Compiling MSMonitor.rc with brcc32...
    "%BRCC32%" -foMSMonitor.res MSMonitor.rc >nul 2>&1
)

set "NAMESPACES=-NSWinapi;System.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;System;Xml;Data;Datasnap;Web;Soap;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell"

taskkill /f /im msmonitor.exe >nul 2>&1
taskkill /f /im msmonitor32.exe >nul 2>&1
taskkill /f /im msmonitor64.exe >nul 2>&1

:: --- BUILD WIN32 ---
echo.
echo [INFO] --------------------------------------------------------------------
echo [INFO] Compiling Win32 binary: msmonitor32.exe
echo [INFO] --------------------------------------------------------------------
set "FLAGS32=%NAMESPACES%"
if defined BDS_LIB32 set "FLAGS32=!FLAGS32! -U"!BDS_LIB32!""

"%DCC32%" -B -Q -W -H %FLAGS32% msmonitor.dpr
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Win32 compilation failed with exit code %ERRORLEVEL%!
    exit /b %ERRORLEVEL%
)

copy /y msmonitor.exe msmonitor32.exe >nul
echo [SUCCESS] Win32 build finished: msmonitor32.exe

:: --- BUILD WIN64 ---
if not exist "%DCC64%" goto :SKIP_WIN64

echo.
echo [INFO] --------------------------------------------------------------------
echo [INFO] Compiling Win64 binary: msmonitor64.exe
echo [INFO] --------------------------------------------------------------------
set "FLAGS64=%NAMESPACES%"
if defined BDS_LIB64 set "FLAGS64=!FLAGS64! -U"!BDS_LIB64!""

"%DCC64%" -B -Q -W -H %FLAGS64% msmonitor.dpr
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Win64 compilation failed with exit code %ERRORLEVEL%!
    exit /b %ERRORLEVEL%
)
copy /y msmonitor.exe msmonitor64.exe >nul
echo [SUCCESS] Win64 build finished: msmonitor64.exe
goto :BUILD_DONE

:SKIP_WIN64
echo [WARN] dcc64.exe not found, skipping Win64 build.

:BUILD_DONE
echo.
echo ========================================================================
echo                     BUILD COMPLETED SUCCESSFULLY
echo ========================================================================
dir msmonitor*.exe | findstr /i "msmonitor"
exit /b 0
