# PiShock Serial Controller

A powerful, local desktop controller for PiShock devices, developed in **Delphi / Object Pascal (VCL)**. This tool serves as a standalone bridge between the serial USB hardware, an integrated WebSocket server for external control (e.g., streaming overlays, interactive chat integrations), and a Health Data Server (HDS) integration for biological feedback loops (e.g., heart-rate-driven automated actions).

---

## 🚀 Features

* **Automated Hardware Detection:** Automatically scans and detects connected PiShock hardware using USB Vendor IDs (VID) and Product IDs (PID), supporting both *PiShock Next* and *PiShock Lite* generations.
* **Low-Latency Serial Communication:** Reliable connection handling running at 115200 Baud (8N1) powered by `ComPortDriver`.
* **Embedded WebSocket Server:** A thread-safe standalone implementation of RFC 6455 built on top of Indy (`TIdTCPServer`). Allows third-party software, browser scripts, or stream tools to pipe custom commands into the system.
* **Health Data Server (HDS) Triggers:** Real-time processing of incoming health telemetry data (e.g., `heartRate`, `oxygenSaturation`, `speed`, `calories`).
  * Supports conditional threshold logic (`>`, `>=`, `<`, `<=`).
  * Automatically fires localized PiShock actions (Shock, Vibrate, Beep) when thresholds are breached.
  * Built-in customizable cooldown system to prevent infinite execution chains.
* **Flexible Command Mapping:** Allows users to map incoming external API triggers to specific modules, intensities, and durations.
* **🚨 GLOBAL EMERGENCY STOP:** A dedicated safety hotkey feature that immediately drops all active WebSocket client connections, kills pending serial signals, and transmits instant termination commands to all shocker modules.
* **Bilingual UI Architecture:** Fully dynamic localization engine supporting English and German out of the box (`uLanguage.pas`).

---

## 📂 Project Structure & Components

* `piserial.pas` / `.dfm`: The core application form. Manages the visual interface, server life-cycles, multi-threaded cross-talk, and configuration persistence.
* `uPiShockDevice.pas`: Serial interaction layer. Handles VID/PID scanning, interrogates hardware strings, parses the `TERMINALINFO` JSON payload, and formats hardware commands.
* `uWebSocketServer.pas`: Handcrafted WebSocket frame encoder/decoder. Manages the initial HTTP handshake upgrade and routes data thread-safely back to the main GUI thread.
* `uHdsTrigger.pas`: Implements the schema for health telemetry properties (camelCase protocol fields) and encapsulates the mathematical validation logic (`ShouldFire`).
* `uHdsForm.pas` / `uAddHdsTrigger.pas`: Management modals and editor dialogs for defining, tweaking, and removing active telemetry rules.
* `uAddMapping.pas`: Configuration layout to bind inbound web commands to physical device responses.
* `uSettingsForm.pas`: Setup panel for network configurations, authorization tokens, Windows hotkey registration, and language switching.
* `uLogForm.pas`: A non-modal, lightweight scrolling console window providing live diagnostic output.
* `uLanguage.pas`: Localization dictionary hosting runtime text structures (`TLangStrings`).

---

## 🛠️ Requirements & Compilation

To build and compile this codebase, you need a modern Delphi development toolkit:

* **IDE Environment:** Embarcadero Delphi (verified working on 10.4 / 11 / 12)
* **Framework Layer:** Windows VCL (Winapi backend)
* **External Dependencies:**
  * **Indy Components:** Used for TCP socket scaffolding (bundled by default with modern Delphi editions).
  * **ComPortDriver (MHumm):** Provides the underlying asynchronous serial wrapper (`CPDrv`).
  * **SerialPorts Unit:** Hardware utility unit to query OS-level COM registries.

---

## ⚠️ Safety Warning & Disclaimer

This software speaks directly to live physical stimulation devices. Extreme caution is urged, particularly when engineering autonomous automation triggers inside the HDS framework.

1. Always benchmark new configuration schemas, step-scaling intensities, or untested data streams using `opBeep` (audio tone) or `opVibrate` (vibration) first before switching to a live `opShock` instruction.
2. Confirm that your **EMERGENCY STOP** keybinding is mapped to a highly accessible and responsive keystroke layout before initiating live operations.
3. Use of this repository is completely at your own risk. The developer accepts no legal liability or responsibility for unexpected hardware responses, altered code execution paths, or biological positive-feedback loops (e.g., getting shocked, panicking, spiking your heart rate, and triggering an accidental loop).

---

*Made with ☕ and Delphi.*
