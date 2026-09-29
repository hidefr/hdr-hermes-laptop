# HDR Hermes Laptop Appliance

A 24/7 autonomous AI assistant and personal computing appliance powered by [Nous Research Hermes Agent](https://github.com/NousResearch/hermes-agent), Google Gemini 2.5/3.x, and an integrated Windows ecosystem.

---

## 🌟 Key Features

* **24/7 Telegram Gateway:** Interact with Hermes remotely from your phone or any Telegram client with strict user-ID whitelisting.
* **Unified Desktop App & Tray Controller:** Seamless integration between the official Hermes native desktop application and a persistent Windows system tray monitor.
* **Always-On Laptop Power Policy:** Configured Windows power schemes so the laptop remains running as a silent headless appliance with the lid closed when connected to AC power.
* **Local Speech-to-Text (STT):** On-device voice-to-text powered by `faster-whisper` (v1.2.1) and `ffmpeg`, offering 100% private, free audio transcription without third-party cloud audio APIs.
* **Stealth Background Execution:** All background workers (Telegram Gateway, Web Dashboard, Tray Monitor) run completely silently without stray console windows or flashing terminal prompts.
* **Local Web Dashboard:** Full web-based agent management dashboard hosted on loopback (`http://127.0.0.1:9119`).

---

## 📁 Repository Structure

```text
├── .gitignore                   # Prevents committing secrets, databases, logs, or sessions
├── .env.example                 # Template for required environment variables & API keys
├── README.md                    # Appliance architecture and setup documentation
├── config/
│   └── config.yaml              # Appliance engine configuration reference
└── scripts/
    ├── bin/
    │   └── HermesLauncher.vbs   # Unified launcher: starts background services & desktop app
    ├── desktop/
    │   ├── Hermes Terminal Chat.cmd       # Quick launch for the classic CLI/terminal interface
    │   ├── Hermes Tray App.cmd            # Launches the system tray monitor
    │   ├── Start Hermes 24-7 Appliance.cmd# Starts Telegram gateway & web dashboard
    │   └── Stop Hermes Appliance.cmd      # Stops all active background services
    ├── startup/
    │   ├── Hermes_Dashboard.vbs # Auto-starts web dashboard on Windows login
    │   ├── Hermes_Gateway.vbs   # Auto-starts Telegram gateway on Windows login
    │   └── Hermes_Tray.vbs      # Auto-starts system tray monitor on Windows login
    └── tray/
        ├── HermesTray.ps1       # System tray monitor: dynamic color status & service controls
        ├── start_services.vbs   # Headless service starter
        ├── stop_services.vbs    # Headless service stopper
        └── restart_services.vbs # Headless service restarter
```

---

## 🚀 Quick Setup & Configuration

### 1. Prerequisites
* Windows 10 or 11 (64-bit)
* [Hermes Agent runtime](https://hermes-agent.nousresearch.com)
* Google AI Studio API Key (Pay-as-you-go recommended for multi-turn agent tool use)
* Telegram Bot Token (obtained from [@BotFather](https://t.me/botfather))

### 2. Environment Setup
1. Copy `.env.example` to `.env`:
   ```powershell
   Copy-Item .env.example .env
   ```
2. Populate `.env` with your credentials:
   ```env
   GEMINI_API_KEY=AIzaSy...
   TELEGRAM_BOT_TOKEN=8926812471:AA...
   TELEGRAM_ALLOWED_USERS=1571229776
   ```

### 3. Service Management
* **Start Services:** Double-click `scripts/desktop/Start Hermes 24-7 Appliance.cmd` or right-click the system tray icon and select **Start All Services**.
* **Stop Services:** Double-click `scripts/desktop/Stop Hermes Appliance.cmd` or select **Stop All Services** from the tray.
* **Desktop App:** Launch via `scripts/bin/HermesLauncher.vbs` or the Windows desktop shortcut to start the graphical UI and automatically verify background services.

---

## 🔒 Security & Privacy Practices

* **No Credential Leaks:** `.env`, `.install_id`, `auth.json`, SQLite state databases (`state.db`, `kanban.db`), and session transcripts are strictly ignored by `.gitignore`.
* **Loopback Dashboard:** The web dashboard strictly binds to `127.0.0.1:9119` (not accessible over local LAN or public networks without SSH tunneling).
* **Telegram Whitelist:** The gateway only accepts messages from user IDs explicitly enumerated in `TELEGRAM_ALLOWED_USERS`. Unlisted senders receive an access-denied response.
