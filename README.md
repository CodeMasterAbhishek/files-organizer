# Files Organizer

A modular Windows batch script designed to organize, clean, and manage cluttered directories such as Downloads, Desktop, or Documents.

## Features

- **8 Organization Modes**:
  1. Standard Categories (Images, Videos, Documents, Audio, Code, Archives, etc.)
  2. Deep Categories (Organizes files into sub-extension folders)
  3. Flat Extension (Direct extension-based sorting)
  4. Date Modified (Organizes into Year and Month folders)
  5. Hybrid (Category + Year-Month hierarchy)
  6. File Size Triage (Tiny, Small, Medium, Large, Gigantic)
  7. Alphabetical (A-Z groupings)
  8. Custom Rules Engine (`custom_rules.txt`)

- **Housekeeping Suite**:
  - Duplicate file finder and cleaner (SHA-256 hash matching)
  - Broken download and temporary file cleanup (`.crdownload`, `.part`, `.tmp`)
  - Cold storage archiver for older files
  - Empty directory removal

- **Power Tools**:
  - Storage analytics and space usage breakdown
  - Smart batch renamer (cleans whitespace, URL tags, adds date prefixes)
  - Deep file search across folders
  - Native ZIP compression for cold storage

- **Safety**:
  - Dry-run simulation mode
  - Single-click undo logging (`organize_history.log`)
  - Parenthesis-safe path handling

## Getting Started

1. Place `Organize_Downloads.bat` in your target directory (e.g. `Downloads`).
2. Optionally edit `custom_rules.txt` to define custom extension mappings.
3. Double-click `Organize_Downloads.bat` or run it from Command Prompt / PowerShell.
4. Select a menu option to organize or clean your files.
