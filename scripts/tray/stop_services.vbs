' Stop Hermes Telegram Gateway and Web Dashboard silently
Option Explicit
Dim sh
Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = "C:\Users\HR-lenovo\AppData\Local\hermes"

' Stop Gateway
sh.Run """C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe"" gateway stop", 0, True

' Stop Dashboard
sh.Run """C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe"" dashboard --stop", 0, True
