# Half-Life & GoldSrc MasterServer Monitor (MSMonitor)

A fast, multithreaded server browser and monitor for GoldSrc engines (Half-Life 1, Counter-Strike 1.6, Adrenaline Gamer, Opposing Force, Day of Defeat, Team Fortress Classic) built on the Valve Master Server Query and A2S_INFO protocols.

MSMonitor combines a **feature-rich GUI desktop application** and a **high-speed CLI utility** in a single unified binary.

Developed in **Delphi (Object Pascal / VCL)** for Windows with native **Win32** and **Win64** architectures.

---

## Key Features

1. **Favorite Servers**:
   * Add or remove servers with one click using the **`★ Favorite`** toolbar button or right-click context menu.
   * Favorite servers are **pinned to the top of the list** regardless of active column sorting.
   * Marked with a distinct **`★`** indicator in the `#` column and rendered with a highlighted golden tone.
   * Dedicated background thread automatically updates favorite server statuses every **30 seconds**.
   * Favorites are persisted across sessions in the Windows Registry (`HKCU\Software\MSMonitor\Favorites`).

2. **Flicker-Free Real-Time List Updates**:
   * Existing table entries are updated in-place without clearing or resetting the view, eliminating visual stutter.
   * True double buffering and adaptive throttled sorting ensure smooth UI rendering under high update frequencies.

3. **Modern VCL Light & Dark Themes**:
   * Out-of-the-box support for both **Light (`Windows10`, default)** and **Dark (`Windows10 Dark`)** themes.
   * Switch themes on the fly in the Settings dialog without restarting the application.
   * Smart color coding for server ping latencies, player capacities, and mod identifiers.

4. **Parallel Multi-Master Query Engine**:
   * Simultaneously queries multiple master servers in parallel background worker threads.
   * Pre-configured with fast, reliable public master servers:
     - `ms.cs16.net:27010`
     - `ms.gs-monitor.com:27010`
     - `ms.varq.net:27010`
     - `ms.tsarvar.com:27010`
     - `master.csmetahook.com:27010`
     - `masterserver.csboost.eu:27010`
   * Master servers and game mod filters can be freely customized in the Settings dialog (`TMemo`, one item per line).

5. **Streaming Server Discovery & A2S Probing**:
   * A2S_INFO server querying begins immediately as servers are discovered, without waiting for master queries to finish.
   * Dynamic thread worker pool (up to 10 parallel threads) ensures rapid server pinging and metadata retrieval.

6. **Unified Server List with Source Provenance**:
   * Servers across all configured GoldSrc game directories (`valve`, `cstrike`, `ag`, `gearbox`, `dod`, `tfc`) appear in one consolidated view.
   * The **Master Server** column tracks which master server listed the endpoint, with automatic deduplication.

7. **Automatic Background Refresh**:
   * Optional background timer refreshes all known servers every 60 seconds without freezing or interrupting user interactions.

8. **Smart Server Filtering & Sorting**:
   * Instant sorting by any column (Ping ascending by default, Server Name, Players, Map, IP, Mod, Master Server).
   * Filter out empty servers (0 players) and unresponsive servers (enabled by default; favorites always remain visible).

9. **Microsecond Precision Ping**:
   * Measures latency using high-resolution hardware timers (`QueryPerformanceCounter`).

10. **One-Click Connect & Export**:
    * Launch Half-Life or Counter-Strike 1.6 directly with `+connect <IP:Port>`.
    * Export server lists to CSV or formatted text files.

11. **Unified CLI Mode**:
    * Run headless or in terminal workflows using `-cli` or standard command-line flags.

---

## Project Structure

* **`msmonitor.dpr`** — Main application entry point (GUI + CLI dispatcher).
* **`msmonitor.dproj`** — Embarcadero Delphi project file.
* **`MSMonitor.rc` / `MSMonitor.res`** — Application resources, version info, and embedded styles.
* **`MainForm.pas` / `MainForm.dfm`** — Main window, server list view, live updates, sorting, and user actions.
* **`SettingsForm.pas` / `SettingsForm.dfm`** — Settings dialog (master servers, game filters, threads, timeouts, theme, paths).
* **`HLMasterProtocol.pas`** — Core networking library implementing Valve Master Server and A2S_INFO query protocols.
* **`MSCliRunner.pas`** — Headless console runner with formatted terminal table output.
* **`build.bat`** — Automated build script for both Win32 and Win64 targets.
* **`Windows10.vsf`** — VCL Light Style.
* **`Windows10Dark.vsf`** — VCL Dark Style.

---

## Building the Project

### Prerequisites
* Embarcadero RAD Studio / Delphi (10.3 Rio or newer).

### Method 1: Using the Automated Build Script
Run `build.bat` from the command prompt:
```cmd
build.bat
```
This builds both architectures and produces:
* `msmonitor32.exe` (Win32 x86 binary)
* `msmonitor64.exe` (Win64 x64 binary)
* `msmonitor.exe` (Win64 default binary)

### Method 2: Command Line Compilers
```cmd
:: 32-bit build
dcc32.exe -B -Q msmonitor.dpr

:: 64-bit build
dcc64.exe -B -Q msmonitor.dpr
```

### Method 3: Embarcadero RAD Studio IDE
1. Open `msmonitor.dproj` in RAD Studio.
2. Select target platform (`32-bit Windows` or `64-bit Windows`) and configuration (`Release`).
3. Press **Shift + F9** (Project -> Build MSMonitor).

---

## CLI Usage

Run `msmonitor.exe -cli` with optional parameters:

```text
Usage:
  msmonitor.exe -cli [options] [host[:port]] [filter]

Options:
  -host:<address[:port]> Master Server address (default: ms.cs16.net:27010)
  -filter:<filter>       Game filter: valve, cstrike, ag, gearbox, dod, tfc
  -limit:<number>        Maximum number of servers (default: 30)
  -threads:<1..10>       Number of query threads (default: 10)
  -region:<code>         Region code (0xFF - Worldwide, 0x03 - Europe)
  -timeout:<ms>          A2S query timeout in milliseconds (default: 350 ms)
  -help, -h, -?          Show help message

Examples:
  msmonitor.exe -cli
  msmonitor.exe -cli masterserver.csboost.eu:27010 cstrike
  msmonitor.exe -cli -threads:10 -timeout:350 -limit:50
```

---

## License & Distribution
Open-source under the MIT License. Contributions and feedback are welcome!
