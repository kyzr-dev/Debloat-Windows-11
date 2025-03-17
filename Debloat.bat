@echo off
powershell -Command "Start-Process -Verb RunAs powershell '-NoExit -ExecutionPolicy Bypass -File %~dp0source\Run-Debloat.ps1'"