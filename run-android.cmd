@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run-android.ps1" %*
exit /b %ERRORLEVEL%
