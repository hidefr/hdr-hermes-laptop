@echo off
title Push to GitHub - hdr-hermes-laptop
set "Path=C:\Users\HR-lenovo\AppData\Local\hermes\tools\git-2.53.0+3-win32-x64\cmd;%Path%"
cd /d C:\HermesAgent
echo =====================================================================
echo Pushing HDR Hermes Laptop Appliance to GitHub
echo Repository: https://github.com/hidefr/hdr-hermes-laptop.git
echo =====================================================================
echo.
git push -u origin main
echo.
pause
