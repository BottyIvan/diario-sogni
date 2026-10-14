@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\apri-pc.ps1"
if errorlevel 1 pause
