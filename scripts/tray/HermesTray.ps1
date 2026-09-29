# =============================================================================
# Hermes Agent - Windows System Tray Appliance Monitor
# =============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. Single-Instance Mutex
$mutexName = "Local\HermesAgentTrayMonitor"
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) {
    [System.Windows.Forms.MessageBox]::Show(
        "Hermes Tray is already active in your taskbar notification area.",
        "Hermes Agent",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    exit
}

# 2. Environment Setup
$HermesHome = if ($env:HERMES_HOME) { $env:HERMES_HOME } else { "$env:LOCALAPPDATA\hermes" }
$HermesBin  = Join-Path $HermesHome "bin"
$HermesExe  = Join-Path $HermesBin "hermes.exe"
$TrayDir    = Join-Path $HermesHome "tray"
$LogsDir    = Join-Path $HermesHome "logs"

if ($env:Path -notlike "*$HermesBin*") {
    $env:Path = "$HermesBin;$env:Path"
}

# 3. Dynamic Icon Creation & Caching (Prevents GDI Object Leaks)
function Create-StateIcon([string]$state) {
    # state: 'online' (green), 'busy' (amber), 'offline' (red)
    $bmp = New-Object System.Drawing.Bitmap 32, 32
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $color = switch ($state) {
        'online'  { [System.Drawing.Color]::FromArgb(46, 204, 113) }  # Emerald Green
        'busy'    { [System.Drawing.Color]::FromArgb(243, 156, 18) }  # Amber
        default   { [System.Drawing.Color]::FromArgb(231, 76, 60) }   # Crimson Red
    }

    # Outer disc
    $brush = New-Object System.Drawing.SolidBrush $color
    $g.FillEllipse($brush, 2, 2, 28, 28)

    # Clean border
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 255, 255)), 2.5
    $g.DrawEllipse($pen, 3, 3, 26, 26)

    # Central Glyph ("H" or "~")
    $font = New-Object System.Drawing.Font ("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $whiteBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    $char = if ($state -eq 'busy') { "~" } else { "H" }
    $g.DrawString($char, $font, $whiteBrush, (New-Object System.Drawing.RectangleF 0, 1, 32, 32), $sf)

    $hIcon = $bmp.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($hIcon)

    $brush.Dispose()
    $pen.Dispose()
    $whiteBrush.Dispose()
    $font.Dispose()
    $g.Dispose()
    $bmp.Dispose()
    return $icon
}

# Pre-cache the three status icons
$script:iconCache = @{
    'online'  = Create-StateIcon 'online'
    'busy'    = Create-StateIcon 'busy'
    'offline' = Create-StateIcon 'offline'
}
$script:currentState = ""

# 4. Ultra-Fast Non-Blocking Service Probing
function Get-ServicesStatus {
    $dashRunning = $false
    $gwRunning   = $false

    # A. Quick Socket Probe on Web Dashboard port 9119 (<200ms)
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $ar = $tcp.BeginConnect([System.Net.IPAddress]::Loopback, 9119, $null, $null)
        if ($ar.AsyncWaitHandle.WaitOne(250, $false) -and $tcp.Connected) {
            $dashRunning = $true
            $tcp.EndConnect($ar)
        }
        $tcp.Close()
    } catch {}

    # B. If Dashboard is reachable, check API for live gateway state
    if ($dashRunning) {
        try {
            $api = Invoke-RestMethod -Uri "http://127.0.0.1:9119/api/status" -TimeoutSec 1 -ErrorAction SilentlyContinue
            if ($api -and $api.gateway_running) {
                $gwRunning = [bool]$api.gateway_running
            }
        } catch {}
    }

    # C. File-based PID check for Telegram Gateway
    if (-not $gwRunning) {
        $pidFile = Join-Path $HermesHome "gateway.pid"
        if (Test-Path $pidFile) {
            try {
                $content = Get-Content $pidFile -Raw -ErrorAction SilentlyContinue
                $pidNum = $null
                if ($content -match '"pid"\s*:\s*(\d+)') {
                    $pidNum = [int]$matches[1]
                } elseif ($content -match '^\s*(\d+)\s*$') {
                    $pidNum = [int]$matches[1]
                }
                if ($pidNum) {
                    $p = Get-Process -Id $pidNum -ErrorAction SilentlyContinue
                    if ($p -and ($p.ProcessName -like "*hermes*" -or $p.ProcessName -like "*python*")) {
                        $gwRunning = $true
                    }
                }
            } catch {}
        }
    }

    # D. Fallback check for running gateway process
    if (-not $gwRunning) {
        $procs = Get-Process -Name "hermes", "python" -ErrorAction SilentlyContinue
        if ($procs) {
            $gwProc = Get-CimInstance Win32_Process -Filter "Name LIKE 'python%' OR Name LIKE 'hermes%'" -ErrorAction SilentlyContinue |
                      Where-Object { $_.CommandLine -like "*gateway*" -and $_.CommandLine -like "*run*" } |
                      Select-Object -First 1
            if ($gwProc) { $gwRunning = $true }
        }
    }

    return [PSCustomObject]@{
        Dashboard = $dashRunning
        Gateway   = $gwRunning
    }
}

# 5. Service Control Operations via Silent VBS Helpers
function Start-HermesServices {
    $script = Join-Path $TrayDir "start_services.vbs"
    if (Test-Path $script) {
        Start-Process "wscript.exe" "`"$script`"" -WindowStyle Hidden
    }
}

function Stop-HermesServices {
    $script = Join-Path $TrayDir "stop_services.vbs"
    if (Test-Path $script) {
        Start-Process "wscript.exe" "`"$script`"" -WindowStyle Hidden
    }
}

function Restart-HermesServices {
    $script = Join-Path $TrayDir "restart_services.vbs"
    if (Test-Path $script) {
        Start-Process "wscript.exe" "`"$script`"" -WindowStyle Hidden
    }
}

# 6. UI Setup: NotifyIcon & Context Menu
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$notifyIcon.ContextMenuStrip = $contextMenu

# Status Header Item (Non-clickable, clear status title)
$menuHeader = New-Object System.Windows.Forms.ToolStripMenuItem
$menuHeader.Enabled = $false
$menuHeader.Font = New-Object System.Drawing.Font ($contextMenu.Font, [System.Drawing.FontStyle]::Bold)
$contextMenu.Items.Add($menuHeader) | Out-Null

$menuGwStatus = New-Object System.Windows.Forms.ToolStripMenuItem
$menuGwStatus.Enabled = $false
$contextMenu.Items.Add($menuGwStatus) | Out-Null

$menuDashStatus = New-Object System.Windows.Forms.ToolStripMenuItem
$menuDashStatus.Enabled = $false
$contextMenu.Items.Add($menuDashStatus) | Out-Null

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

# Action Items: Start / Stop / Restart
$menuStart = New-Object System.Windows.Forms.ToolStripMenuItem
$menuStart.Text = "Start All Services"
$menuStart.Add_Click({
    $notifyIcon.Icon = $script:iconCache['busy']
    $notifyIcon.Text = "Hermes Agent: Starting..."
    $notifyIcon.ShowBalloonTip(2000, "Hermes Agent", "Starting Telegram Gateway and Dashboard...", [System.Windows.Forms.ToolTipIcon]::Info)
    Start-HermesServices
})
$contextMenu.Items.Add($menuStart) | Out-Null

$menuStop = New-Object System.Windows.Forms.ToolStripMenuItem
$menuStop.Text = "Stop All Services"
$menuStop.Add_Click({
    $notifyIcon.Icon = $script:iconCache['busy']
    $notifyIcon.Text = "Hermes Agent: Stopping..."
    $notifyIcon.ShowBalloonTip(2000, "Hermes Agent", "Stopping Hermes services...", [System.Windows.Forms.ToolTipIcon]::Info)
    Stop-HermesServices
})
$contextMenu.Items.Add($menuStop) | Out-Null

$menuRestart = New-Object System.Windows.Forms.ToolStripMenuItem
$menuRestart.Text = "Restart All Services"
$menuRestart.Add_Click({
    $notifyIcon.Icon = $script:iconCache['busy']
    $notifyIcon.Text = "Hermes Agent: Restarting..."
    $notifyIcon.ShowBalloonTip(2000, "Hermes Agent", "Restarting Hermes services...", [System.Windows.Forms.ToolTipIcon]::Info)
    Restart-HermesServices
})
$contextMenu.Items.Add($menuRestart) | Out-Null

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

# Utility Items: Launch Desktop App, Open Dashboard, Open Logs
$menuOpenDesktop = New-Object System.Windows.Forms.ToolStripMenuItem
$menuOpenDesktop.Text = "Open Hermes Desktop App"
$menuOpenDesktop.Font = New-Object System.Drawing.Font ($contextMenu.Font, [System.Drawing.FontStyle]::Bold)
$menuOpenDesktop.Add_Click({
    $desktopExe = Join-Path $HermesHome "hermes-agent\apps\desktop\release\win-unpacked\Hermes.exe"
    if (Test-Path $desktopExe) {
        Start-Process $desktopExe
    }
})
$contextMenu.Items.Add($menuOpenDesktop) | Out-Null

$menuOpenDash = New-Object System.Windows.Forms.ToolStripMenuItem
$menuOpenDash.Text = "Open Web Dashboard (Port 9119)"
$menuOpenDash.Add_Click({
    Start-Process "http://localhost:9119"
})
$contextMenu.Items.Add($menuOpenDash) | Out-Null

$menuOpenLogs = New-Object System.Windows.Forms.ToolStripMenuItem
$menuOpenLogs.Text = "Open Logs Folder"
$menuOpenLogs.Add_Click({
    if (Test-Path $LogsDir) { Start-Process "explorer.exe" $LogsDir } else { Start-Process "explorer.exe" $HermesHome }
})
$contextMenu.Items.Add($menuOpenLogs) | Out-Null

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

# Exit Tray Monitor
$menuExit = New-Object System.Windows.Forms.ToolStripMenuItem
$menuExit.Text = "Exit Tray Monitor"
$menuExit.Add_Click({
    $timer.Stop()
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    if ($mutex) {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
    [System.Windows.Forms.Application]::Exit()
})
$contextMenu.Items.Add($menuExit) | Out-Null

# Double click tray icon opens Dashboard
$notifyIcon.Add_DoubleClick({
    Start-Process "http://localhost:9119"
})

# 7. Update UI Function
function Update-UI {
    $status = Get-ServicesStatus
    $gw   = $status.Gateway
    $dash = $status.Dashboard

    $newState = if ($gw -and $dash) {
        'online'
    } elseif ($gw -or $dash) {
        'busy'
    } else {
        'offline'
    }

    if ($newState -ne $script:currentState) {
        $notifyIcon.Icon = $script:iconCache[$newState]
        $script:currentState = $newState
    }

    if ($gw -and $dash) {
        $notifyIcon.Text = "Hermes Agent: ONLINE (Telegram + Web)"
        $menuHeader.Text = "STATUS: ALL SERVICES ONLINE"
        $menuHeader.ForeColor = [System.Drawing.Color]::FromArgb(46, 204, 113)
        $menuStart.Enabled = $false
        $menuStop.Enabled = $true
        $menuRestart.Enabled = $true
    } elseif ($gw -or $dash) {
        $notifyIcon.Text = "Hermes Agent: PARTIAL (Check Services)"
        $menuHeader.Text = "STATUS: PARTIAL SERVICE ACTIVE"
        $menuHeader.ForeColor = [System.Drawing.Color]::FromArgb(243, 156, 18)
        $menuStart.Enabled = $true
        $menuStop.Enabled = $true
        $menuRestart.Enabled = $true
    } else {
        $notifyIcon.Text = "Hermes Agent: OFFLINE (Stopped)"
        $menuHeader.Text = "STATUS: OFFLINE"
        $menuHeader.ForeColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
        $menuStart.Enabled = $true
        $menuStop.Enabled = $false
        $menuRestart.Enabled = $false
    }

    $menuGwStatus.Text = if ($gw) { "  [OK] Telegram Gateway: Connected" } else { "  [--] Telegram Gateway: Stopped" }
    $menuDashStatus.Text = if ($dash) { "  [OK] Web Dashboard: Port 9119" } else { "  [--] Web Dashboard: Stopped" }
}

# Update immediately when right-click menu is about to open
$contextMenu.Add_Opening({
    Update-UI
})

# 8. Background Polling Timer (Checks status every 3.5 seconds)
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3500
$timer.Add_Tick({
    Update-UI
})

# Initial status update and display
Update-UI
$notifyIcon.Visible = $true
$timer.Start()

# 9. Windows Application Event Loop
[System.Windows.Forms.Application]::Run()
