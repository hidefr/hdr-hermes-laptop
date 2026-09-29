' Hermes Agent Gateway - Messaging Platform Integration
Option Explicit
Dim sh
Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = "C:\Users\HR-lenovo\AppData\Local\hermes"
sh.Run """C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe"" gateway start", 0, False
