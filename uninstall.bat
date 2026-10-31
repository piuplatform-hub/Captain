@echo off
REM =====================================================================
REM File chạy nhanh gỡ cài đặt (không lo bị hỏi Execution Policy)
REM =====================================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
