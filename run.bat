@echo off
for /f "delims=" %%i in ('powershell -Command "Get-ExecutionPolicy"') do set policy=%%i

if /i not "%policy%"=="Unrestricted" (
    powershell -Command "Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force"
) 

powershell -Command "Start-Process -Verb RunAs powershell '-NoExit -ExecutionPolicy Bypass -File %~dp0source\Win11-Debloat.ps1 -ExPol %policy%'"