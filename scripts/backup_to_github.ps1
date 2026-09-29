# =============================================================================
# Automated Backup Script for HDR Hermes Laptop Appliance
# Syncs live scripts/configs, commits, and pushes to GitHub repository
# =============================================================================
param(
    [string]$CommitMessage = "chore(backup): auto-sync appliance configs and scripts $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
)

$ErrorActionPreference = "Stop"
$repoRoot = "C:\HermesAgent"
$git = "C:\Users\HR-lenovo\AppData\Local\hermes\tools\git-2.53.0+3-win32-x64\cmd\git.exe"

Write-Host "==> Starting HDR Hermes Laptop Appliance Backup..." -ForegroundColor Cyan

# 1. Sync live scripts and configurations
Write-Host "==> Syncing live scripts and configuration files..." -ForegroundColor Gray
Copy-Item "C:\Users\HR-lenovo\AppData\Local\hermes\tray\*" "$repoRoot\scripts\tray\" -Force
Copy-Item "C:\Users\HR-lenovo\AppData\Local\hermes\bin\HermesLauncher.vbs" "$repoRoot\scripts\bin\" -Force
Copy-Item "C:\Users\HR-lenovo\Desktop\*.cmd" "$repoRoot\scripts\desktop\" -Force
Copy-Item "C:\Users\HR-lenovo\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Hermes_*.vbs" "$repoRoot\scripts\startup\" -Force
Copy-Item "C:\Users\HR-lenovo\AppData\Local\hermes\config.yaml" "$repoRoot\config\config.yaml" -Force
Copy-Item "C:\Users\HR-lenovo\AppData\Local\hermes\SOUL.md" "$repoRoot\config\SOUL.md" -Force

# 2. Strict Security Check: Verify .env is NOT tracked
Push-Location $repoRoot
try {
    $trackedEnv = & $git ls-files ".env"
    if ($trackedEnv) {
        Write-Error "CRITICAL: .env file is tracked by git! Aborting backup to prevent credential leaks."
        exit 1
    }

    # 3. Check for git changes
    $status = & $git status --porcelain
    if (-not $status) {
        Write-Host "[OK] Everything is already up to date. No changes to commit." -ForegroundColor Green
        & $git push origin main
        Write-Host "[OK] Remote repository is fully synchronized." -ForegroundColor Green
        return
    }

    Write-Host "==> Staging changed files..." -ForegroundColor Gray
    & $git add .

    Write-Host "==> Committing: $CommitMessage" -ForegroundColor Gray
    & $git commit -m "$CommitMessage"

    Write-Host "==> Pushing to origin main..." -ForegroundColor Gray
    & $git push origin main

    Write-Host "[OK] Backup completed successfully to GitHub!" -ForegroundColor Green
} finally {
    Pop-Location
}
