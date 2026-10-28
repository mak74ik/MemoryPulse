# MemoryPulse 

<p align="center">
  <img src="assets/icon_1024.png" width="128" height="128" alt="MemoryPulse App Icon">
</p>

<p align="center">
  <b>A lightweight, 100% native macOS RAM cleaner and process studio for Apple Silicon.</b><br>
  No subscriptions. No background bloat. No daemon telemetry. Built with Swift 6 and Liquid Glass SwiftUI.
</p>

<p align="center">
  <a href="#installation"><img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 14+"></a>
  <a href="#build-from-source"><img src="https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 6"></a>
  <a href="#architecture"><img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20-0071e3?style=for-the-badge" alt="Apple Silicon"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-34d399?style=for-the-badge" alt="MIT License"></a>
</p>

---

<p align="center">
  <img src="assets/hero_banner.png" width="100%" alt="MemoryPulse Interface on macOS">
</p>

---

## 💡 Why MemoryPulse?

| Feature | macOS Activity Monitor | CleanMyMac X | MemoryPulse  |
|:---|:---:|:---:|:---:|
| **Menu Bar Quick Access** | ❌ None | ⚠️ Heavy helper |  **Instant popup** |
| **RAM Footprint** | ~75 MB | ~240 MB |  **~22 MB** |
| **Background CPU Usage** | 1.5% - 4% | 2% - 5% (daemons) |  **< 0.1%** |
| **Purge Inactive Cache** | ❌ (Need `sudo purge` in Terminal) | ⚠️ Clunky |  **1-Click (No root)** |
| **App Architecture (ARM64 vs Intel)** | Column in deep sub-menu | ❌ No |  **Visible badge** |
| **Swap Storage Meter** | Hidden in tab | Hidden |  **Visible live card** |
| **Price** | Free (built-in) | $39.95 / year |  **100% Free & Open Source** |
| **Telemetry & Tracking** | Apple telemetry | Active trackers |  **Zero tracking / 0 dependencies** |

---

## ⚡️ Key Features

- **Liquid Glass Architecture**: Built with native AppKit & SwiftUI `.fullScreenUI` materials, ambient mesh illumination, and Apple Taptic Engine feedback.
- **Apple Glowing Sort Pills**: Tap to sort processes by **RAM**, **CPU Load**, or **Name**. Active buttons softly illuminate with a neon sapphire glow, and re-tapping toggles ascending/descending order.
- **Accurate CPU Metering**: Uses Darwin `mach_timebase_info` hardware conversion for exact per-process CPU usage matching `top` and `Activity Monitor`.
- **Safe Userspace Cache Purge**: Triggers Mach VM page cache reclaim without needing root passwords (`sudo`).
- **"Quit Background Apps" Button**: Closes all inactive minimized applications with one click.
- **Confirmation Dialog with "Don't Ask Again"**: Warns before terminating apps, with a remember option for instant 1-click kills.
- **Context Menu (Right-Click)**:
  - Show in Finder
  - Copy PID
  - Copy Executable Path
  - Terminate / Force Kill
- **Bilingual (Auto-Detect)**: Automatically speaks your system language (English / Russian) with a quick `RU / EN` toggle.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Description |
|:---:|:---|
| <kbd>⌘</kbd> + <kbd>R</kbd> | Refresh process list (with 360° spin) |
| <kbd>⌘</kbd> + <kbd>K</kbd> | Purge inactive memory cache |
| <kbd>⌘</kbd> + <kbd>F</kbd> | Focus search field |
| <kbd>⌘</kbd> + <kbd>W</kbd> | Close window (app keeps running in Menu Bar) |
| <kbd>⌘</kbd> + <kbd>Q</kbd> | Quit MemoryPulse |

---

## 📥 Installation

### Option 1: Direct Download (Ready-to-use `.app`)
Clone or download the repo and run:
```bash
git clone https://github.com/mak74ik/MemoryPulse.git
cd MemoryPulse
./Scripts/build_app.sh
```
The script will compile the project and install `MemoryPulse.app` directly into `/Applications`.

### Option 2: Run directly
```bash
open /Applications/MemoryPulse.app
```

---

## ⌨️ Shortcuts & Interaction

| Action | Function |
| :--- | :--- |
| **Click Menu Bar Icon** | Opens real-time RAM breakdown & instant Purge popover |
| **Sort Pills (`RAM`, `CPU`, `Name`)** | Cycles primary sort key with animated neon accent |
| **Arrow Indicator (▲ / ▼)** | Inverts sort direction between Descending and Ascending |
| **Scope Filters** | Switch between **Apps** (interactive GUI apps), **All**, and **Heavy** (>300 MB) |
| **Kill Button (✕)** | Initiates process termination modal with "Don't ask again" option |

---

## 🛠 Tech Stack & Architecture

- **Language**: Swift 6 (Strict Concurrency & Sendable checks enabled)
- **Supported Systems**: macOS 14.0+ (Apple Silicon M1/M2/M3/M4 & Intel x86_64)
- **UI**: SwiftUI & AppKit hybrid (`NSHostingController` + `NSVisualEffectView`)
- **Kernel APIs**:
  - Mach VM Subsystem: `host_statistics64` (`vm_statistics64_data_t`)
  - Darwin Process Inspection: `libproc` (`proc_listpids`, `proc_pidinfo`)
  - Sysctl: `vm.swapusage`, `kern.memorystatus_vm_pressure_level`
  - Host CPU statistics: `host_cpu_load_info`
  - Architecture detection: `NSRunningApplication.executableArchitecture`
- **Binary Size**: ~1.4 MB compiled binary.

---

## 👥 Contributors & Credits

- [**Yoshi (@mak74ik)**](https://github.com/mak74ik) — Lead Creator, Systems Architecture & Core Engineering
- [**Claude (@claude)**](https://github.com/claude) — Autonomous Pair Programming & Systems Architecture

---

## 📄 License

Distributed under the [MIT License](LICENSE). Free for personal and commercial use.
