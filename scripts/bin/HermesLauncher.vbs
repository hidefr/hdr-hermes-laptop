' =============================================================================
' Hermes Unified Desktop & Services Launcher
' Starts the Hermes Desktop App and ensures the System Tray Monitor and
' background 24/7 services (Telegram Gateway + Web Dashboard) are running.
' =============================================================================
Option Explicit
Dim sh, fso
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

sh.CurrentDirectory = "C:\Users\HR-lenovo\AppData\Local\hermes"

Dim wmi, colProcesses
Set wmi = GetObject("winmgmts:\\.\root\cimv2")

' 1. Ensure System Tray Monitor is running
Set colProcesses = wmi.ExecQuery("Select ProcessId from Win32_Process Where CommandLine Like '%HermesTray.ps1%'")
If colProcesses.Count = 0 Then
    sh.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""C:\Users\HR-lenovo\AppData\Local\hermes\tray\HermesTray.ps1""", 0, False
End If

' 2. Ensure Telegram Gateway is running
Set colProcesses = wmi.ExecQuery("Select ProcessId from Win32_Process Where CommandLine Like '%gateway%' And CommandLine Like '%run%'")
If colProcesses.Count = 0 Then
    sh.Run "powershell.exe -WindowStyle Hidden -Command ""& 'C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe' gateway run""", 0, False
End If

' 3. Ensure Web Dashboard is running
Set colProcesses = wmi.ExecQuery("Select ProcessId from Win32_Process Where CommandLine Like '%dashboard%' And CommandLine Like '%skip-build%'")
If colProcesses.Count = 0 Then
    sh.Run "powershell.exe -WindowStyle Hidden -Command ""& 'C:\Users\HR-lenovo\AppData\Local\hermes\bin\hermes.exe' dashboard --skip-build --no-open""", 0, False
End If

' 4. Launch the Hermes Desktop App Window
Dim desktopExe
desktopExe = "C:\Users\HR-lenovo\AppData\Local\hermes\hermes-agent\apps\desktop\release\win-unpacked\Hermes.exe"
If fso.FileExists(desktopExe) Then
    sh.Run """" & desktopExe & """", 1, False
End If
