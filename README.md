# MemoryPulse 

<p align="center">
  <img src="build/icon_1024.png" width="128" height="128" alt="MemoryPulse App Icon">
</p>

<p align="center">
  <b>A Luxury, 100% Native macOS RAM Cleaner, Cache Optimizer & Process Studio</b><br>
  Built with Swift 6, SwiftUI & Liquid Glass aesthetics for Apple Silicon.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-black?style=flat-square&logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%2F%20Universal-blue?style=flat-square" alt="Apple Silicon">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/badge/Dependencies-Zero%20(Pure%20Native)-purple?style=flat-square" alt="Zero Dependencies">
</p>

---

## ✨ Features (Особенности)

-  **Liquid Glass & VisionOS Design Standard**:
  - Pure native SwiftUI window chrome with `.fullScreenUI` frosted glass and dynamic ambient breathing lights.
  - Interactive **Apple Glowing Sort Pills**: buttons illuminate with a neon sapphire/cyan glow when active, with animated arrow indicators for ascending/descending order.
  - Native haptic feedback via `NSHapticFeedbackManager` on every action.

- ⚡️ **Menu Bar Extra & Floating HUD Studio**:
  - Live RAM usage percentage and chip glyph in the macOS menu bar.
  - Quick popup with circular memory pressure ring, top consumers, and one-click purge.
  - Full detached floating task studio with search, filter tabs, architecture badges, and swap monitoring.

- 🎛 **Advanced Sorting & Smart Filtering**:
  - **Memory (RAM)**: Sort by real resident set size (RSS).
  - **CPU Load**: Live CPU percentage per process.
  - **Name (A-Z / А-Я)**: Case-insensitive alphabetical sorting.
  - Filter categories: **Apps** (regular GUI applications with high-res icons), **All Processes** (system daemons & helpers), and **Heavy (>300 MB)**.

- 🧹 **Hybrid Safe Memory Purge**:
  - Asynchronous userspace cache reclaim triggering Darwin kernel's VM pager to flush inactive file caches without requiring `sudo`.
  - Exact freed megabytes counter and banner feedback.
  - One-click **"Quit Background Apps"** (закрыть все фоновые программы) to instantly free gigabytes of memory.

- 🌐 **Bilingual (Auto-Detect RU / EN)**:
  - Automatically matches system language (Russian or English).
  - One-click `RU / EN` globe toggle in the header.

- 🔍 **Power-User Context Menu & Details**:
  - Right-click any row to **Show in Finder**, **Copy PID**, **Copy Path**, or trigger **Force Kill**.
  - Displays binary architecture: ` Silicon` (ARM64) vs `Intel` (Rosetta 2).
  - Displays active **Swap Storage** (файл подкачки).

---

## ⌨️ Keyboard Shortcuts (Горячие клавиши)

| Shortcut | Action |
|:---:|:---|
| <kbd>⌘</kbd> + <kbd>R</kbd> | Refresh process list and memory stats (with 360° spin) |
| <kbd>⌘</kbd> + <kbd>K</kbd> | Quick Memory Purge (Очистить память) |
| <kbd>⌘</kbd> + <kbd>F</kbd> | Focus search field |
| <kbd>⌘</kbd> + <kbd>W</kbd> | Close window (keeps running in menu bar) |
| <kbd>⌘</kbd> + <kbd>Q</kbd> | Quit application |

---

## 🚀 Installation & Build (Установка и сборка)

### Quick Run:
```bash
open /Applications/MemoryPulse.app
```

### Build from source:
```bash
git clone https://github.com/your-username/MemoryPulse.git
cd MemoryPulse
./Scripts/build_app.sh
```

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).
