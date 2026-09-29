@echo off
title Stopping Hermes Agent Appliance...
echo Stopping Hermes Gateway and Web Dashboard...
set "Path=C:\Users\HR-lenovo\AppData\Local\hermes\bin;%Path%"
hermes gateway stop
hermes dashboard --stop
echo.
echo Hermes services stopped.
timeout /t 3 >nul
