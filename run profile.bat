powershell -Command "Start-Process -Verb RunAs powershell '-NoExit -ExecutionPolicy Bypass -File %~dp0source\profile.ps1'"
pause