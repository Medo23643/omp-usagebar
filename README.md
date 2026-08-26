# OMP Usagebar — Omarchy Quattro Plugin

A native, theme-aware Omarchy Quattro plugin providing a real-time visual indicator and dashboard for **[Oh My Pi (OMP)](https://github.com/can1357/oh-my-pi)** AI usage, quota tracking, live streaming state, and a universal system-wide **Crash Sentinel ("Fix with AI")**.

---

## ✨ Key Features

### 🤖 Native Bar Widget & Thinking State
- **Official Omarchy Design**: Uses the official Omarchy robot icon glyph (`󱚣`), typography, and border styling for a seamless system panel experience.
- **100% Theme-Aware**: Dynamically follows the active Omarchy theme colors in real time without reloading.
- **Pulsing Thinking Wave**: Smoothly slides the robot icon to reveal three animated pulsing dots in the top bar whenever OMP is actively thinking, reasoning, calling tools, or streaming tokens.
- **Real-Time Stream Detection**: Automatically detects active prompt generation vs idle terminal state (stays idle while waiting for user input at the prompt).
- **Intelligent Status Tints**:
  - ⚪ **Normal**: All providers healthy and within limits.
  - 🟡 **Warning**: One provider exhausted while alternatives remain available.
  - 🔴 **Urgent**: All configured providers exhausted.
  - 🔘 **Muted Grey**: Widget monitoring paused by user.

### 📊 Dynamic Quota & Quota Windows
- **Least-Used First Sorting**: Dynamically sorts models with the least consumed quota on top for instant decision making.
- **Full Model Support**: Tracks all metered limits (Gemini, Claude, GPT-OSS) and unmetered providers (GLM/Zai, OpenRouter, Copilot).
- **Reset Timers**: Shows remaining time until daily quota reset (`Daily · resets in Xh Ym`).

### 📈 Dual-Timeframe Token Metrics
- **Current Boot / Session Tokens**: Displays `Tokens since boot : X M` directly under each provider's progress bar.
- **Daily Cumulative Tokens**: Dedicated section calculating tokens per model and grand total consumed today (`TOKENS SINCE YYYY-MM-DD 00:00`).
- **Compact Metric Formatting**: Formatted in readable metric units (`1.20M`, `18.4K`, `850`).

### 🛡️ Universal System Crash Sentinel ("Fix with AI")
- **Universal Application Coverage**: Actively monitors kernel & systemd coredump events across **all** GUI apps (Nautilus, Firefox, VS Code, Discord), desktop components (Hyprland, Waybar, Omarchy, UPower), and background CLI utilities.
- **Interactive Notifications**: Dispatches rich desktop notifications with a custom robot badge icon whenever an application experiences a fatal crash (`SIGSEGV`, `SIGABRT`, `SIGBUS`, `SIGFPE`, `SIGILL`, `SIGKILL`).
- **1-Click AI Diagnostics**: Clicking the notification or **`Fix with AI`** button immediately opens a new terminal launching `omp` with:
  - Application metadata, binary path, PID, signal, and timestamp.
  - Arch Linux package information (`pacman -Qo`).
  - Recent application stderr / journal logs.
  - Full thread stack trace and coredump traceback.
  - Actionable prompt instructing OMP to diagnose and fix the root cause.

### 🎛️ Footer Action Controls
- **Crash Sentinel Toggle (`󰒄`)**: Easily enable or disable AI crash notifications. Displays in red when disabled.
- **Pause / Resume Monitoring (`󰏤` / `󰐥`)**: Halts all polling intervals, background scanning, and dims the top bar widget.
- **Interactive Web Dashboard (``)**: Launches the local `omp stats` browser dashboard with an automated 5-minute auto-timeout to prevent lingering background daemons.
- **Manual Refresh (`↻`)**: Instantly refresh quotas (or right-click the top bar widget).

---

## 📦 Installation

1. Clone the repository into your Omarchy plugins directory:

```bash
mkdir -p ~/.config/omarchy/plugins
git clone https://github.com/Medo23643/omp-usagebar.git ~/.config/omarchy/plugins/omp.usagebar
```

2. Validate and enable the plugin:

```bash
omarchy plugin validate ~/.config/omarchy/plugins/omp.usagebar
omarchy plugin enable omp.usagebar
omarchy restart shell
```

3. (Optional) Add to your bar layout in `~/.config/omarchy/shell.json`:

```json
{
  "layout": {
    "right": [
      "omp.usagebar",
      "omarchy.tray"
    ]
  }
}
```

---

## 🧪 Testing the Crash Sentinel

You can test the Crash Sentinel notification and 1-click OMP diagnostic session anytime:

```bash
~/.config/omarchy/plugins/omp.usagebar/crash-monitor.sh --test
```

---

## 📂 Project Structure

```
omp-usagebar/
├── manifest.json                  # Plugin manifest contract
├── Panel.qml                      # Top bar button & popup keyboard panel
├── Main.qml                       # omp usage/stats polling engine & supervisor
├── Activity.qml                   # Real-time streaming & prompt activity detector
├── crash-monitor.sh               # Universal system crash sentinel daemon
├── open-dashboard.sh              # Web stats launcher with auto-timeout
├── assets/
│   └── robot-icon.svg             # Robot badge notification icon
├── components/
│   ├── ActivityBars.qml           # Thinking wave dots animation
│   ├── QuotaCard.qml              # Full-width quota meters & reset countdowns
│   ├── SeverityProgressBar.qml    # Theme & severity-colored meter bar
│   └── TokenRow.qml               # Formatted token consumption rows
└── README.md
```

---

## 🙏 Credits & Acknowledgements

- **Inspiration**: Inspired by **[ai-usagebar](https://github.com/akitaonrails/ai-usagebar)** by [@akitaonrails](https://github.com/akitaonrails) — thank you for pioneering beautiful AI quota monitoring on the Linux desktop!
- **AI Agent**: Built for **[Oh My Pi (OMP)](https://github.com/can1357/oh-my-pi)** by [@can1357](https://github.com/can1357).
- **Desktop Environment**: Built for **[Omarchy Quattro](https://omarchy.org)** and **[Quickshell](https://quickshell.org)**.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
