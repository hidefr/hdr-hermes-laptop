' Hermes Agent - System Tray Monitor Auto-Start
Option Explicit
Dim sh, cmd
Set sh = CreateObject("WScript.Shell")
cmd = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""C:\Users\HR-lenovo\AppData\Local\hermes\tray\HermesTray.ps1"""
sh.Run cmd, 0, False
