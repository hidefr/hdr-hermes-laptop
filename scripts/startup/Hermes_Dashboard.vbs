' Hermes Agent Web Dashboard (Port 9119)
Option Explicit
Dim sh
Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = "C:\Users\HR-lenovo\AppData\Local\hermes"
sh.Run """C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe"" dashboard --skip-build --no-open", 0, False
