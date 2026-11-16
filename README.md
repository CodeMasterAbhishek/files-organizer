# Files Organizer

A modular, zero-dependency file organization and cleaning suite designed to manage cluttered directories such as `Downloads`, `Desktop`, or `Documents` across **Windows, macOS, and Linux**.

Each operating system has its own dedicated, native script with 100% feature parity and zero required installations:

| Operating System | File | How to Run |
| :--- | :--- | :--- |
| **Windows** | [`Organize_Downloads_Windows.bat`](file:///e:/GitHub%20projects/files-organizer/Organize_Downloads_Windows.bat) | **Double-click** in File Explorer (or run from CMD / PowerShell) |
| **macOS** | [`Organize_Downloads_macOS.command`](file:///e:/GitHub%20projects/files-organizer/Organize_Downloads_macOS.command) | **Double-click** in Finder (or run `./Organize_Downloads_macOS.command` in Terminal) |
| **Linux** | [`Organize_Downloads_Linux.sh`](file:///e:/GitHub%20projects/files-organizer/Organize_Downloads_Linux.sh) | Run `./Organize_Downloads_Linux.sh` in Terminal |

---

## Features

- **8 Organization Modes**:
  1. **Standard Categories**: Images, Documents, Video, Audio, Installers/Packages, Archives, Code, etc.
  2. **Deep Categories**: Sub-extension sorting (e.g. `Images/PNG`, `Documents/PDF`, `Code/Python`)
  3. **Flat Extension**: Direct extension-based sorting (`PNG/`, `JPG/`, `PDF/`, `ZIP/`)
  4. **Date Modified**: Organizes into Year and Month folders (e.g. `2026/11 - November/`)
  5. **Hybrid**: Category + Year-Month hierarchy (e.g. `Images/2026-11/`)
  6. **File Size Triage**: Sorts by magnitude (`Gigabytes (>1GB)`, `Large`, `Medium`, `Small`, `Tiny`)
  7. **Alphabetical**: Alphabetical groupings (`A - D/`, `E - H/`, `I - L/`, `0-9 and Symbols/`)
  8. **Custom Rules Engine**: User-defined rules via `custom_rules.txt`

- **Housekeeping Suite**:
  - **Duplicate Cleaner**: Isolate browser duplicates (`file (1).ext`, `file - Copy.ext`) and exact bit-for-bit duplicates (SHA-256 hash match) into a `Duplicates/` staging folder.
  - **Junk & Broken Downloads Cleaner**: Quarantine or purge `.crdownload`, `.part`, `.tmp`, and 0-byte ghost files.
  - **Empty Folder Sweeper**: Scan and safely remove leftover empty directories.

- **Power Tools**:
  - **Storage Analytics**: Space usage breakdown and top 10 space hogs.
  - **Smart Batch Renamer**: Clean duplicate tags, fix `%20` URL spaces, and add date prefixes.

- **Safety**:
  - **Dry-Run Simulation**: Preview exactly what will move before touching any files.
  - **Single-Click Undo**: Revert moved files back to their original locations using `organize_history.log`.
  - **Collision Protection**: Automatically renames destination collisions to `file (1).ext` instead of overwriting.

---

## Getting Started

1. Place the appropriate script for your operating system into your target directory (e.g. `Downloads` or `Desktop`):
   - **Windows**: `Organize_Downloads_Windows.bat`
   - **macOS**: `Organize_Downloads_macOS.command`
   - **Linux**: `Organize_Downloads_Linux.sh`
2. Run or double-click the script.
3. Select an organization mode from the interactive menu (if you choose Custom Rules, a starter `custom_rules.txt` file is generated automatically).
