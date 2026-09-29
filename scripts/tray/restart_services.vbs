' Restart Hermes Telegram Gateway and Web Dashboard silently
Option Explicit
Dim sh
Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = "C:\Users\HR-lenovo\AppData\Local\hermes"

' Stop Gateway and Dashboard
sh.Run """C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe"" gateway stop", 0, True
sh.Run """C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe"" dashboard --stop", 0, True

WScript.Sleep 2000

' Start Gateway and Dashboard
sh.Run "powershell.exe -WindowStyle Hidden -Command ""& 'C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe' gateway run""", 0, False
sh.Run "powershell.exe -WindowStyle Hidden -Command ""& 'C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe' dashboard --skip-build --no-open""", 0, False
