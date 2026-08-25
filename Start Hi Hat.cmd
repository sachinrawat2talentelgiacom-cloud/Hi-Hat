@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-hi-hat.ps1"
if errorlevel 1 (
  echo.
  echo Hi Hat could not be started. See the message above.
  pause
)

