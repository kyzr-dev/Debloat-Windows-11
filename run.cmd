@echo off
setlocal EnableExtensions

rem --- Self-elevate if not already admin ---
>nul 2>&1 net session
if %errorlevel% neq 0 (
  if "%*"=="" (
    powershell -WindowStyle Hidden -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  ) else (
    powershell -WindowStyle Hidden -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '%*'"
  )
  exit /b
)

rem --- Path to the main runner ---
set "script=%~dp0source/Start-Windows11Debloat.ps1"

rem --- Parse args for 'unattended' (accept: unattended, /unattended, --unattended, unattended=1/true) ---
set "PS_SWITCH="
for %%A in (%*) do (
  for /F "tokens=1,2 delims==" %%I in ("%%~A") do (
    if /I "%%~I"=="unattended"     set "PS_SWITCH=-Unattended"
    if /I "%%~I"=="/unattended"    set "PS_SWITCH=-Unattended"
    if /I "%%~I"=="--unattended"   set "PS_SWITCH=-Unattended"
    if /I "%%~I"=="unattended" if /I "%%~J"=="1"    set "PS_SWITCH=-Unattended"
    if /I "%%~I"=="unattended" if /I "%%~J"=="true" set "PS_SWITCH=-Unattended"
  )
)

rem --- Run the PS script (already elevated) ---
powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "%script%" %PS_SWITCH%

endlocal
