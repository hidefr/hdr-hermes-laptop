' Start Hermes Telegram Gateway and Web Dashboard silently
Option Explicit
Dim sh
Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = "C:\Users\HR-lenovo\AppData\Local\hermes"

' Start Gateway
sh.Run "powershell.exe -WindowStyle Hidden -Command ""& 'C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe' gateway run""", 0, False

' Start Dashboard
sh.Run "powershell.exe -WindowStyle Hidden -Command ""& 'C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe' dashboard --skip-build --no-open""", 0, False
