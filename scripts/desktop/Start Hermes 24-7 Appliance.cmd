@echo off
title Starting Hermes Agent Appliance...
echo ========================================================
echo   Starting Hermes 24/7 Agent Appliance...
echo ========================================================
echo.

set "Path=C:\Users\HR-lenovo\AppData\Local\hermes\bin;%Path%"

echo [1/2] Starting Hermes Telegram Gateway...
hermes gateway start

echo [2/2] Starting Hermes Web Dashboard...
start "" "C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe" dashboard --skip-build --no-open

timeout /t 3 /nobreak >nul
echo.
echo ========================================================
echo   Hermes is RUNNING in the background!
echo   - Telegram Bot: Connected to your phone
echo   - Web Dashboard: http://localhost:9119
echo ========================================================
echo.
echo Opening Web Dashboard in your browser...
start http://localhost:9119
timeout /t 3 >nul
