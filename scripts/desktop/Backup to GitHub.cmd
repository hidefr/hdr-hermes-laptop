@echo off
title Backup Hermes Appliance to GitHub
set "Path=C:\Users\HR-lenovo\AppData\Local\hermes\tools\git-2.53.0+3-win32-x64\cmd;%Path%"
cd /d C:\HermesAgent
echo =====================================================================
echo  HDR Hermes Laptop Appliance - Automated Backup to GitHub
echo  Repository: https://github.com/hidefr/hdr-hermes-laptop.git
echo =====================================================================
echo.
powershell.exe -ExecutionPolicy Bypass -File "C:\HermesAgent\scripts\backup_to_github.ps1"
echo.
pause
