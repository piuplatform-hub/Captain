@echo off
REM =====================================================================
REM File chạy nhanh không cần cấp quyền PowerShell Execution Policy
REM =====================================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
