@echo off
setlocal DisableDelayedExpansion

rem --------------------------------------------------------
rem Set working directory to the folder where this script is located
rem --------------------------------------------------------
cd /d "%~dp0"
set "SELF=%~nx0"
set "TARGET_DIR=%~dp0"
set "RULES_FILE=%~dp0custom_rules.txt"
set "LOG_FILE=%~dp0organize_history.log"
set "TEMP_SIM=%~dp0preview_sim.tmp"
set "IS_PREVIEW=0"
set "IS_SILENT=0"

rem Check if first argument is a folder path (e.g. from context menu)
if not "%~1"=="" if exist "%~1\*" (
    cd /d "%~1"
    set "TARGET_DIR=%~f1\"
    set "RULES_FILE=%~f1\custom_rules.txt"
    set "LOG_FILE=%~f1\organize_history.log"
    set "TEMP_SIM=%~f1\preview_sim.tmp"
    shift /1
)

if /i "%~1"=="/silent" goto :RunSilent
if /i "%~1"=="-silent" goto :RunSilent
if /i "%~1"=="/auto" goto :RunSilent
if /i "%~1"=="-auto" goto :RunSilent
if /i "%~1"=="/mode" (
    set "CHOSEN_MODE=%~2"
    goto :RunSilentMode
)
if not "%~1"=="" goto %~1

title Downloads File Organizer

:MainMenu
cls
del "%TEMP_SIM%" 2>nul
echo ======================================================
echo              Downloads File Organizer
echo ======================================================
echo Folder: %CD%
echo.
echo Select an organization style:
echo.
echo  [1] Standard Categories
echo      Images, Documents, Video, Audio, EXEs, Archives, etc.
echo.
echo  [2] Deep Categories (Category + Format Subfolders)
echo      Images\PNG, Images\JPG, Documents\PDF, Code\Python, etc.
echo.
echo  [3] File Extension Directly (Flat by Format)
echo      PNG\, JPG\, PDF\, ZIP\, EXE\, MP4\, etc.
echo.
echo  [4] By Date Downloaded / Modified (Year ^& Month)
echo      2026\11 - November, 2026\10 - October, etc.
echo.
echo  [5] Hybrid (Category + Year ^& Month)
echo      Images\2026-11, Documents\2026-11, Video\2026-10, etc.
echo.
echo  [6] File Size Triage (Disk Space Cleanup)
echo      Gigabytes (Above 1GB), Large (100MB-1GB), Medium, Small
echo.
echo  [7] Alphabetical Groups (A-Z)
echo      A - D\, E - H\, I - L\, M - P\, Q - T\, U - Z\, Symbols\
echo.
echo  [8] Custom Rules (User-Defined ^& Saved Rules)
echo      Create, save, and run your own custom folder rules
echo.
echo  ----------------- Housekeeping Tools -----------------
echo.
echo  [D] Duplicate Cleaner ^& Staging
echo      Detect and isolate duplicate downloads (e.g. (1), (2), - Copy)
echo.
echo  [A] Old Files / Cold Storage Archiver
echo      Archive files older than 30, 60, or 90 days into "Archive_Old\"
echo.
echo  [J] Junk ^& Broken Downloads Cleaner
echo      Clean .crdownload, .part, .tmp and 0-byte ghost files
echo.
echo  [E] Empty Folder Sweeper
echo      Scan and safely remove all empty leftover directories
echo.
echo  ----------------- Power Tools ^& Analytics -----------
echo.
echo  [T] Storage Analytics ^& Space Hogs
echo      Visual breakdown of disk usage, largest files, and health
echo.
echo  [R] Smart Batch Renamer
echo      Clean duplicate tags, fix %%20 URLs, add date prefixes, or case
echo.
echo  [F] Deep File Finder ^& Search
echo      Search across Downloads by keyword, extension, size, or date
echo.
echo  [Z] Folder Compressor ^& Zip Archiver
echo      Compress inactive categories or Archive_Old into .zip files
echo.
echo  [W] Switch Active Working Folder
echo      Switch between Downloads, Desktop, Documents, or any drive
echo.
echo  [M] Windows Right-Click Menu Integration
echo      Add "Organize Files Here" to Windows Explorer right-click menu
echo.
echo  [S] Schedule Automation (Task Scheduler)
echo      Configure Windows to organize Downloads automatically
echo.
echo  ----------------- Safety ^& Controls -----------------
echo.
echo  [P] Preview / Dry-Run (Simulate before moving)
echo      See what would be moved without touching any files
echo.
echo  [U] Undo / Revert Last Organization
echo      Restore moved files from the last session back to root
echo.
echo  [0] Exit (Make no changes)
echo.
echo ======================================================
set "USER_CHOICE="
set /p "USER_CHOICE=Enter choice [0-8, D, A, J, E, T, R, F, Z, W, M, S, P, or U]: "

if "%USER_CHOICE%"=="" goto :MainMenu
if "%USER_CHOICE%"=="0" exit /b 0
if "%USER_CHOICE%"=="1" set "IS_PREVIEW=0" & set "CHOSEN_MODE=1" & goto :RunSelectedMode
if "%USER_CHOICE%"=="2" set "IS_PREVIEW=0" & set "CHOSEN_MODE=2" & goto :RunSelectedMode
if "%USER_CHOICE%"=="3" set "IS_PREVIEW=0" & set "CHOSEN_MODE=3" & goto :RunSelectedMode
if "%USER_CHOICE%"=="4" set "IS_PREVIEW=0" & set "CHOSEN_MODE=4" & goto :RunSelectedMode
if "%USER_CHOICE%"=="5" set "IS_PREVIEW=0" & set "CHOSEN_MODE=5" & goto :RunSelectedMode
if "%USER_CHOICE%"=="6" set "IS_PREVIEW=0" & set "CHOSEN_MODE=6" & goto :RunSelectedMode
if "%USER_CHOICE%"=="7" set "IS_PREVIEW=0" & set "CHOSEN_MODE=7" & goto :RunSelectedMode
if "%USER_CHOICE%"=="8" goto :CustomRulesMenu
if /i "%USER_CHOICE%"=="D" goto :DuplicateMenu
if /i "%USER_CHOICE%"=="A" goto :ArchiveOldMenu
if /i "%USER_CHOICE%"=="J" goto :JunkMenu
if /i "%USER_CHOICE%"=="E" goto :EmptyFolderMenu
if /i "%USER_CHOICE%"=="T" goto :AnalyticsMenu
if /i "%USER_CHOICE%"=="R" goto :RenamerMenu
if /i "%USER_CHOICE%"=="F" goto :FinderMenu
if /i "%USER_CHOICE%"=="Z" goto :CompressMenu
if /i "%USER_CHOICE%"=="W" goto :FolderSwitcherMenu
if /i "%USER_CHOICE%"=="M" goto :ContextMenuMenu
if /i "%USER_CHOICE%"=="S" goto :ScheduleMenu
if /i "%USER_CHOICE%"=="P" goto :PreviewMenu
if /i "%USER_CHOICE%"=="U" goto :RunUndo

echo.
echo [!] Invalid selection. Please choose an option from the menu.
echo.
pause
goto :MainMenu

rem ========================================================
rem Preview / Dry-Run Selection Submenu
rem ========================================================
:PreviewMenu
cls
del "%TEMP_SIM%" 2>nul
echo ======================================================
echo                 Preview / Dry-Run Mode
echo                (No files will be moved)
echo ======================================================
echo.
echo Which organization style would you like to simulate?
echo.
echo  [1] Standard Categories
echo  [2] Deep Categories (Category + Format Subfolders)
echo  [3] File Extension Directly (Flat by Format)
echo  [4] By Date Downloaded / Modified (Year ^& Month)
echo  [5] Hybrid (Category + Year ^& Month)
echo  [6] File Size Triage
echo  [7] Alphabetical Groups (A-Z)
echo  [8] Custom Rules
echo.
echo  [0] Back to Main Menu
echo.
echo ======================================================
set "P_CHOICE="
set /p "P_CHOICE=Enter style to simulate [0-8]: "

if "%P_CHOICE%"=="" goto :PreviewMenu
if "%P_CHOICE%"=="0" goto :MainMenu
if "%P_CHOICE%"=="1" set "IS_PREVIEW=1" & set "CHOSEN_MODE=1" & goto :RunSelectedMode
if "%P_CHOICE%"=="2" set "IS_PREVIEW=1" & set "CHOSEN_MODE=2" & goto :RunSelectedMode
if "%P_CHOICE%"=="3" set "IS_PREVIEW=1" & set "CHOSEN_MODE=3" & goto :RunSelectedMode
if "%P_CHOICE%"=="4" set "IS_PREVIEW=1" & set "CHOSEN_MODE=4" & goto :RunSelectedMode
if "%P_CHOICE%"=="5" set "IS_PREVIEW=1" & set "CHOSEN_MODE=5" & goto :RunSelectedMode
if "%P_CHOICE%"=="6" set "IS_PREVIEW=1" & set "CHOSEN_MODE=6" & goto :RunSelectedMode
if "%P_CHOICE%"=="7" set "IS_PREVIEW=1" & set "CHOSEN_MODE=7" & goto :RunSelectedMode
if "%P_CHOICE%"=="8" set "IS_PREVIEW=1" & set "CHOSEN_MODE=8" & goto :RunSelectedMode

echo.
echo [!] Invalid selection. Please choose a number from 0 to 8.
echo.
pause
goto :PreviewMenu

rem ========================================================
rem Mode Execution Engine
rem ========================================================
:RunSilent
set "IS_SILENT=1"
set "IS_PREVIEW=0"
set "CHOSEN_MODE=1"
goto :RunSelectedMode

:RunSilentMode
set "IS_SILENT=1"
set "IS_PREVIEW=0"
if "%CHOSEN_MODE%"=="" set "CHOSEN_MODE=1"
goto :RunSelectedMode

:RunSelectedMode
if "%IS_PREVIEW%"=="0" del "%LOG_FILE%" 2>nul
del "%TEMP_SIM%" 2>nul
set "MOVED_COUNT=0"

if "%CHOSEN_MODE%"=="1" (
    echo.
    if "%IS_PREVIEW%"=="1" (echo [*] [SIMULATION] Checking Standard Categories...) else (echo [*] Organizing by Standard Categories...)
    echo.
    call :ProcessAllCategories :CategoryStandard
    call :MoveOthersStandard "Others"
    goto :ShowSummary
)

if "%CHOSEN_MODE%"=="2" (
    echo.
    if "%IS_PREVIEW%"=="1" (echo [*] [SIMULATION] Checking Deep Categories...) else (echo [*] Organizing by Deep Categories...)
    echo.
    call :ProcessAllCategories :CategoryDeep
    call :MoveOthersDeep "Others"
    goto :ShowSummary
)

if "%CHOSEN_MODE%"=="3" (
    echo.
    if "%IS_PREVIEW%"=="1" (echo [*] [SIMULATION] Checking File Extensions...) else (echo [*] Organizing directly by File Extension...)
    echo.
    for %%F in (*) do (
        if exist "%%F" (
            if /i not "%%~nxF"=="%SELF%" if /i not "%%~nxF"=="organize_history.log" if /i not "%%~nxF"=="custom_rules.txt" if /i not "%%~nxF"=="preview_sim.tmp" (
                call :ProcessExtension "%%F"
            )
        )
    )
    goto :ShowSummary
)

if "%CHOSEN_MODE%"=="4" (
    echo.
    if "%IS_PREVIEW%"=="1" (echo [*] [SIMULATION] Checking Dates...) else (echo [*] Organizing by Date Downloaded...)
    echo.
    for %%F in (*) do (
        if exist "%%F" (
            if /i not "%%~nxF"=="%SELF%" if /i not "%%~nxF"=="organize_history.log" if /i not "%%~nxF"=="custom_rules.txt" if /i not "%%~nxF"=="preview_sim.tmp" (
                call :ProcessDate "%%F"
            )
        )
    )
    goto :ShowSummary
)

if "%CHOSEN_MODE%"=="5" (
    echo.
    if "%IS_PREVIEW%"=="1" (echo [*] [SIMULATION] Checking Hybrid Categories + Date...) else (echo [*] Organizing by Hybrid...)
    echo.
    call :ProcessAllCategories :CategoryHybrid
    call :MoveOthersHybrid "Others"
    goto :ShowSummary
)

if "%CHOSEN_MODE%"=="6" (
    echo.
    if "%IS_PREVIEW%"=="1" (echo [*] [SIMULATION] Checking File Sizes...) else (echo [*] Organizing by File Size Triage...)
    echo.
    for %%F in (*) do (
        if exist "%%F" (
            if /i not "%%~nxF"=="%SELF%" if /i not "%%~nxF"=="organize_history.log" if /i not "%%~nxF"=="custom_rules.txt" if /i not "%%~nxF"=="preview_sim.tmp" (
                call :ProcessSize "%%F"
            )
        )
    )
    goto :ShowSummary
)

if "%CHOSEN_MODE%"=="7" (
    echo.
    if "%IS_PREVIEW%"=="1" (echo [*] [SIMULATION] Checking Alphabetical Names...) else (echo [*] Organizing Alphabetically...)
    echo.
    for %%F in (*) do (
        if exist "%%F" (
            if /i not "%%~nxF"=="%SELF%" if /i not "%%~nxF"=="organize_history.log" if /i not "%%~nxF"=="custom_rules.txt" if /i not "%%~nxF"=="preview_sim.tmp" (
                call :ProcessAlpha "%%F"
            )
        )
    )
    goto :ShowSummary
)

if "%CHOSEN_MODE%"=="8" (
    if not exist "%RULES_FILE%" call :InitRulesFile
    echo.
    if "%IS_PREVIEW%"=="1" (echo [*] [SIMULATION] Checking Custom Rules from: %RULES_FILE%...) else (echo [*] Running Custom Rules from: %RULES_FILE%...)
    echo.
    for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("%RULES_FILE%") do (
        call :ExecuteCustomRule "%%A" "%%B"
    )
    if "%IS_PREVIEW%"=="1" (
        goto :ShowSummary
    ) else (
        echo.
        set "ORG_REST="
        set /p "ORG_REST=Organize any remaining files into Standard Categories? [Y/N]: "
        if /i "%ORG_REST%"=="Y" (
            echo.
            echo [*] Organizing remaining files into Standard Categories...
            call :ProcessAllCategories :CategoryStandard
            call :MoveOthersStandard "Others"
        )
        goto :ShowSummary
    )
)

:ShowSummary
echo.
echo ======================================================
if "%IS_PREVIEW%"=="1" goto :ShowPreviewSummary

if %MOVED_COUNT% gtr 0 echo Status: Successfully organized %MOVED_COUNT% file^(s^).
if %MOVED_COUNT% equ 0 echo Status: No files needed organizing.
echo ======================================================
echo.
if "%IS_SILENT%"=="1" exit /b 0
pause
exit /b 0

:ShowPreviewSummary
del "%TEMP_SIM%" 2>nul
if %MOVED_COUNT% gtr 0 echo Simulation Complete: %MOVED_COUNT% file^(s^) would be organized.
if %MOVED_COUNT% equ 0 echo Simulation Complete: No files needed organizing.
echo [No files were moved or changed]
echo ======================================================
echo.
if %MOVED_COUNT% equ 0 (
    pause
    goto :MainMenu
)
set "APPLY_NOW="
set /p "APPLY_NOW=Apply this organization and move the files now? [Y/N]: "
if /i "%APPLY_NOW%"=="Y" (
    set "IS_PREVIEW=0"
    goto :RunSelectedMode
)
echo.
echo [*] Preview cancelled. No files were moved.
echo.
pause
goto :MainMenu

rem ========================================================
rem Undo / Revert Routine
rem ========================================================
:RunUndo
cls
echo ======================================================
echo             Undo Last Organization
echo ======================================================
if not exist "%LOG_FILE%" (
    echo.
    echo [!] No organization history log found.
    echo     There are no recent moves to revert.
    echo.
    pause
    goto :MainMenu
)

set "HIST_COUNT=0"
for /f "usebackq tokens=1,2 delims=|" %%A in ("%LOG_FILE%") do (
    set /a HIST_COUNT+=1
)

if %HIST_COUNT% equ 0 (
    echo.
    echo [!] The history log is empty. Nothing to undo.
    echo.
    pause
    goto :MainMenu
)

echo.
echo Found %HIST_COUNT% file^(s^) moved during the last session.
echo.
set "CONFIRM_UNDO="
set /p "CONFIRM_UNDO=Restore these files back to the Downloads root? [Y/N]: "
if /i not "%CONFIRM_UNDO%"=="Y" (
    echo.
    echo [*] Undo cancelled. No files were modified.
    echo.
    pause
    goto :MainMenu
)

echo.
echo [*] Restoring files to Downloads root...
echo.
set "RESTORED_COUNT=0"
for /f "usebackq tokens=1,2 delims=|" %%A in ("%LOG_FILE%") do (
    call :RestoreFile "%%A" "%%B"
)

del "%LOG_FILE%" 2>nul
echo.
echo ======================================================
if %RESTORED_COUNT% gtr 0 echo Status: Successfully restored %RESTORED_COUNT% file^(s^).
if %RESTORED_COUNT% equ 0 echo Status: No files were found to restore.
echo ======================================================
echo.
pause
exit /b 0

:RestoreFile
set "CURR=%~1"
set "ORIG=%~2"
if not exist "%CURR%" goto :CleanDir
if exist "%ORIG%" goto :RestoreDup
move "%CURR%" "%ORIG%" >nul
echo  [-] Restored: %CURR% -^> %ORIG%
set /a RESTORED_COUNT+=1
goto :CleanDir

:RestoreDup
set "R_SRC=%CURR%"
set "R_NAME=%~n2"
set "R_EXT=%~x2"
set /a r_idx=1
:r_dup_loop
set "NEW_R_NAME=%R_NAME% (%r_idx%)%R_EXT%"
if exist "%NEW_R_NAME%" set /a r_idx+=1 & goto :r_dup_loop
move "%R_SRC%" "%NEW_R_NAME%" >nul
echo  [-] Restored (duplicate): %R_SRC% -^> %NEW_R_NAME%
set /a RESTORED_COUNT+=1

:CleanDir
for %%P in ("%CURR%") do (
    rmdir "%%~dpP" 2>nul
    for %%Q in ("%%~dpP..") do if not "%%~fQ"=="%CD%" rmdir "%%~fQ" 2>nul
)
goto :eof

rem ========================================================
rem Duplicate Cleaner & Staging Manager
rem ========================================================
:DuplicateMenu
cls
echo ======================================================
echo           Duplicate Cleaner ^& Staging Manager
echo ======================================================
echo Folder: %CD%
echo.
echo Duplicates clutter your downloads when files are downloaded
echo multiple times (e.g. "report (1).pdf", "photo - Copy.png").
echo.
echo Select an option:
echo.
echo  [1] Scan ^& Isolate Browser Duplicates
echo      Moves *(1).ext, *(2).ext, * - Copy.ext into "Duplicates\"
echo.
echo  [2] Scan ^& Isolate Exact Duplicates (Bit-for-Bit Hash Match)
echo      Finds identical files anywhere in Downloads via SHA256
echo.
echo  [3] Preview / List Duplicates (Report Only)
echo      Displays all duplicates found without moving anything
echo.
echo  [4] Permanently Delete Staged Duplicates ("Duplicates\" folder)
echo      Frees disk space after you've reviewed the duplicates
echo.
echo  [0] Back to Main Menu
echo.
echo ======================================================
set "DUP_CHOICE="
set /p "DUP_CHOICE=Enter choice [0-4]: "

if "%DUP_CHOICE%"=="" goto :DuplicateMenu
if "%DUP_CHOICE%"=="0" goto :MainMenu
if "%DUP_CHOICE%"=="1" goto :RunDupIsolate
if "%DUP_CHOICE%"=="2" goto :RunHashIsolate
if "%DUP_CHOICE%"=="3" goto :RunDupPreview
if "%DUP_CHOICE%"=="4" goto :RunDeleteDuplicates

echo.
echo [!] Invalid selection. Please choose an option from the menu.
echo.
pause
goto :DuplicateMenu

:RunDupIsolate
echo.
echo Select scan scope:
echo  [1] Entire Downloads folder (all subfolders included)
echo  [2] Downloads root only
echo.
set "SCOPE_CHOICE="
set /p "SCOPE_CHOICE=Enter scope [1-2, default=1]: "
set "DUP_SCOPE=all"
if "%SCOPE_CHOICE%"=="2" set "DUP_SCOPE=root"

echo.
echo [*] Scanning for browser duplicate downloads...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR; $scope = $env:DUP_SCOPE; $log = $env:LOG_FILE;" ^
  "$excluded = @('Organize_Downloads_Windows.bat','Organize_Downloads_macOS.command','Organize_Downloads_Linux.sh','Organize_Downloads.bat','organize_history.log','custom_rules.txt','preview_sim.tmp');" ^
  "if ($scope -eq 'root') {" ^
  "  $files = Get-ChildItem -LiteralPath $dir -File | Where-Object { $excluded -notcontains $_.Name };" ^
  "} else {" ^
  "  $files = Get-ChildItem -LiteralPath $dir -File -Recurse | Where-Object { $excluded -notcontains $_.Name -and $_.FullName -notmatch '[\\/]Duplicates[\\/]' };" ^
  "}" ^
  "$pattern = '\s*\(\d+\)$|\s*-\s*Copy(\s*\(\d+\))?$';" ^
  "$dups = @($files | Where-Object { $_.BaseName -match $pattern });" ^
  "if ($dups.Count -eq 0) { Write-Host 'No duplicate downloads found.' -ForegroundColor Yellow; exit 0 };" ^
  "$totalBytes = ($dups | Measure-Object -Property Length -Sum).Sum;" ^
  "$mb = [Math]::Round($totalBytes / 1MB, 2);" ^
  "Write-Host ('Found {0} duplicate file(s) occupying {1} MB.' -f $dups.Count, $mb);" ^
  "$dupBase = Join-Path $dir 'Duplicates';" ^
  "$count = 0;" ^
  "foreach ($d in $dups) {" ^
  "  $rel = $d.DirectoryName.Substring($dir.Length).TrimStart('\', '/');" ^
  "  $destFolder = if ($rel) { Join-Path $dupBase $rel } else { $dupBase };" ^
  "  if (!(Test-Path -LiteralPath $destFolder)) { New-Item -ItemType Directory -Force -Path $destFolder | Out-Null };" ^
  "  $destFile = Join-Path $destFolder $d.Name;" ^
  "  $finalPath = $destFile; $idx = 1;" ^
  "  while (Test-Path -LiteralPath $finalPath) {" ^
  "    $finalPath = Join-Path $destFolder ('{0}_dup{1}{2}' -f $d.BaseName, $idx, $d.Extension); $idx++;" ^
  "  };" ^
  "  Move-Item -LiteralPath $d.FullName -Destination $finalPath -Force;" ^
  "  Add-Content -LiteralPath $log -Value ('{0}|{1}' -f $finalPath, $d.FullName);" ^
  "  Write-Host (' [+] Isolated: {0} -> Duplicates\{1}' -f $d.Name, $rel) -ForegroundColor Green;" ^
  "  $count++;" ^
  "};" ^
  "Write-Host '';" ^
  "Write-Host ('[V] Successfully isolated {0} duplicate file(s) into Duplicates\' -f $count) -ForegroundColor Cyan;"
echo.
pause
goto :DuplicateMenu

:RunHashIsolate
echo.
echo Select scan scope:
echo  [1] Entire Downloads folder (all subfolders included)
echo  [2] Downloads root only
echo.
set "SCOPE_CHOICE="
set /p "SCOPE_CHOICE=Enter scope [1-2, default=1]: "
set "DUP_SCOPE=all"
if "%SCOPE_CHOICE%"=="2" set "DUP_SCOPE=root"

echo.
echo [*] Analyzing file hashes for exact bit-for-bit duplicates...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR; $scope = $env:DUP_SCOPE; $log = $env:LOG_FILE;" ^
  "$excluded = @('Organize_Downloads_Windows.bat','Organize_Downloads_macOS.command','Organize_Downloads_Linux.sh','Organize_Downloads.bat','organize_history.log','custom_rules.txt','preview_sim.tmp');" ^
  "if ($scope -eq 'root') {" ^
  "  $files = Get-ChildItem -LiteralPath $dir -File | Where-Object { $excluded -notcontains $_.Name };" ^
  "} else {" ^
  "  $files = Get-ChildItem -LiteralPath $dir -File -Recurse | Where-Object { $excluded -notcontains $_.Name -and $_.FullName -notmatch '[\\/]Duplicates[\\/]' };" ^
  "}" ^
  "$sizeGroups = $files | Group-Object -Property Length | Where-Object { $_.Count -gt 1 };" ^
  "$dups = @();" ^
  "foreach ($group in $sizeGroups) {" ^
  "  $hashGroups = $group.Group | Group-Object -Property { (Get-FileHash -LiteralPath $_.FullName -Algorithm MD5).Hash } | Where-Object { $_.Count -gt 1 };" ^
  "  foreach ($hg in $hashGroups) {" ^
  "    $orig = $hg.Group[0];" ^
  "    $extra = $hg.Group | Select-Object -Skip 1;" ^
  "    foreach ($e in $extra) { $dups += [PSCustomObject]@{ File = $e; Original = $orig } };" ^
  "  };" ^
  "};" ^
  "if ($dups.Count -eq 0) { Write-Host 'No exact bit-for-bit duplicate files found.' -ForegroundColor Yellow; exit 0 };" ^
  "$totalBytes = ($dups | Measure-Object -Property { $_.File.Length } -Sum).Sum;" ^
  "$mb = [Math]::Round($totalBytes / 1MB, 2);" ^
  "Write-Host ('Found {0} exact duplicate file(s) occupying {1} MB.' -f $dups.Count, $mb);" ^
  "$dupBase = Join-Path $dir 'Duplicates\Exact_Duplicates';" ^
  "$count = 0;" ^
  "foreach ($d in $dups) {" ^
  "  $item = $d.File;" ^
  "  $rel = $item.DirectoryName.Substring($dir.Length).TrimStart('\', '/');" ^
  "  $destFolder = if ($rel) { Join-Path $dupBase $rel } else { $dupBase };" ^
  "  if (!(Test-Path -LiteralPath $destFolder)) { New-Item -ItemType Directory -Force -Path $destFolder | Out-Null };" ^
  "  $destFile = Join-Path $destFolder $item.Name;" ^
  "  $finalPath = $destFile; $idx = 1;" ^
  "  while (Test-Path -LiteralPath $finalPath) {" ^
  "    $finalPath = Join-Path $destFolder ('{0}_dup{1}{2}' -f $item.BaseName, $idx, $item.Extension); $idx++;" ^
  "  };" ^
  "  Move-Item -LiteralPath $item.FullName -Destination $finalPath -Force;" ^
  "  Add-Content -LiteralPath $log -Value ('{0}|{1}' -f $finalPath, $item.FullName);" ^
  "  Write-Host (' [+] Isolated: {0} (Matches: {1})' -f $item.Name, $d.Original.Name) -ForegroundColor Green;" ^
  "  $count++;" ^
  "};" ^
  "Write-Host '';" ^
  "Write-Host ('[V] Successfully isolated {0} exact duplicate file(s) into Duplicates\Exact_Duplicates\' -f $count) -ForegroundColor Cyan;"
echo.
pause
goto :DuplicateMenu

:RunDupPreview
echo.
echo Select scan scope:
echo  [1] Entire Downloads folder (all subfolders included)
echo  [2] Downloads root only
echo.
set "SCOPE_CHOICE="
set /p "SCOPE_CHOICE=Enter scope [1-2, default=1]: "
set "DUP_SCOPE=all"
if "%SCOPE_CHOICE%"=="2" set "DUP_SCOPE=root"

echo.
echo [*] Scanning duplicates for report...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR; $scope = $env:DUP_SCOPE;" ^
  "$excluded = @('Organize_Downloads_Windows.bat','Organize_Downloads_macOS.command','Organize_Downloads_Linux.sh','Organize_Downloads.bat','organize_history.log','custom_rules.txt','preview_sim.tmp');" ^
  "if ($scope -eq 'root') {" ^
  "  $files = Get-ChildItem -LiteralPath $dir -File | Where-Object { $excluded -notcontains $_.Name };" ^
  "} else {" ^
  "  $files = Get-ChildItem -LiteralPath $dir -File -Recurse | Where-Object { $excluded -notcontains $_.Name -and $_.FullName -notmatch '[\\/]Duplicates[\\/]' };" ^
  "}" ^
  "$pattern = '\s*\(\d+\)$|\s*-\s*Copy(\s*\(\d+\))?$';" ^
  "$dups = @($files | Where-Object { $_.BaseName -match $pattern });" ^
  "if ($dups.Count -eq 0) { Write-Host 'No duplicate downloads found.' -ForegroundColor Yellow; exit 0 };" ^
  "$totalBytes = ($dups | Measure-Object -Property Length -Sum).Sum;" ^
  "$mb = [Math]::Round($totalBytes / 1MB, 2);" ^
  "Write-Host ('--- Detected Duplicates ({0} files, {1} MB) ---' -f $dups.Count, $mb) -ForegroundColor Cyan;" ^
  "foreach ($d in $dups | Select-Object -First 30) {" ^
  "  $rel = $d.FullName.Substring($dir.Length).TrimStart('\', '/');" ^
  "  $sizeStr = if ($d.Length -gt 1MB) { '{0:N1} MB' -f ($d.Length/1MB) } else { '{0:N0} KB' -f ($d.Length/1KB) };" ^
  "  Write-Host ('  - {0,-40} [{1}]' -f $rel, $sizeStr);" ^
  "};" ^
  "if ($dups.Count -gt 30) { Write-Host ('  ... and {0} more duplicate files.' -f ($dups.Count - 30)) -ForegroundColor Gray };"
echo.
pause
goto :DuplicateMenu

:RunDeleteDuplicates
cls
echo ======================================================
echo          Delete Staged Duplicates Folder
echo ======================================================
set "STAGED_DIR=%TARGET_DIR%Duplicates"
if not exist "%STAGED_DIR%" (
    echo.
    echo [*] No "Duplicates\" folder found. Nothing to delete.
    echo.
    pause
    goto :DuplicateMenu
)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:STAGED_DIR;" ^
  "$files = Get-ChildItem -LiteralPath $dir -File -Recurse;" ^
  "if ($files.Count -eq 0) { Write-Host 'Duplicates folder is empty.' -ForegroundColor Yellow; exit 0 };" ^
  "$totalBytes = ($files | Measure-Object -Property Length -Sum).Sum;" ^
  "$mb = [Math]::Round($totalBytes / 1MB, 2);" ^
  "Write-Host ('Staged Duplicates: {0} file(s) occupying {1} MB' -f $files.Count, $mb) -ForegroundColor Yellow;"
echo.
echo WARNING: This action will permanently remove all files inside
echo the "%STAGED_DIR%" folder to reclaim your disk space!
echo.
set "CONFIRM_DEL="
set /p "CONFIRM_DEL=Type DELETE to confirm permanent deletion: "
if not "%CONFIRM_DEL%"=="DELETE" (
    echo.
    echo [*] Deletion cancelled. Files were NOT touched.
    echo.
    pause
    goto :DuplicateMenu
)

echo.
echo [*] Deleting Duplicates folder...
rmdir /s /q "%STAGED_DIR%"
echo.
echo [V] "Duplicates\" folder and all its contents have been removed.
echo.
pause
goto :DuplicateMenu

rem ========================================================
rem Old Files / Cold Storage Archiver
rem ========================================================
:ArchiveOldMenu
cls
echo ======================================================
echo           Old Files / Cold Storage Archiver
echo ======================================================
echo Folder: %CD%
echo.
echo Move older, inactive downloads into cold storage so your
echo primary download categories stay fresh and decluttered.
echo.
echo Select age threshold:
echo.
echo  [1] Older than 30 days  (1 Month)
echo  [2] Older than 60 days  (2 Months)
echo  [3] Older than 90 days  (3 Months)
echo  [4] Older than 180 days (6 Months)
echo  [5] Custom age (enter any number of days)
echo.
echo  [P] Preview / List Old Files (Report only)
echo.
echo  [0] Back to Main Menu
echo.
echo ======================================================
set "ARCH_CHOICE="
set /p "ARCH_CHOICE=Enter choice [0-5, or P]: "

if "%ARCH_CHOICE%"=="" goto :ArchiveOldMenu
if "%ARCH_CHOICE%"=="0" goto :MainMenu
if "%ARCH_CHOICE%"=="1" set "OLD_DAYS=30" & goto :RunArchiveOld
if "%ARCH_CHOICE%"=="2" set "OLD_DAYS=60" & goto :RunArchiveOld
if "%ARCH_CHOICE%"=="3" set "OLD_DAYS=90" & goto :RunArchiveOld
if "%ARCH_CHOICE%"=="4" set "OLD_DAYS=180" & goto :RunArchiveOld
if "%ARCH_CHOICE%"=="5" goto :CustomDaysPrompt
if /i "%ARCH_CHOICE%"=="P" goto :RunArchivePreview

echo.
echo [!] Invalid selection. Please choose an option from the menu.
echo.
pause
goto :ArchiveOldMenu

:CustomDaysPrompt
echo.
set "CUSTOM_D="
set /p "CUSTOM_D=Enter minimum file age in days (e.g. 45): "
if "%CUSTOM_D%"=="" goto :ArchiveOldMenu
set "OLD_DAYS=%CUSTOM_D%"
goto :RunArchiveOld

:RunArchiveOld
echo.
echo Select destination folder structure:
echo  [1] Year ^& Month: Archive_Old\2026-08\ (Recommended)
echo  [2] Preserve category: Archive_Old\Documents\, Archive_Old\Images\
echo  [3] Flat: Archive_Old\
echo.
set "FMT_CHOICE="
set /p "FMT_CHOICE=Enter format [1-3, default=1]: "
set "ARCH_FMT=date"
if "%FMT_CHOICE%"=="2" set "ARCH_FMT=rel"
if "%FMT_CHOICE%"=="3" set "ARCH_FMT=flat"

echo.
echo Select scan scope:
echo  [1] Entire Downloads folder (all subfolders included)
echo  [2] Downloads root only
echo.
set "SCOPE_CHOICE="
set /p "SCOPE_CHOICE=Enter scope [1-2, default=1]: "
set "ARCH_SCOPE=all"
if "%SCOPE_CHOICE%"=="2" set "ARCH_SCOPE=root"

echo.
echo [*] Scanning for files older than %OLD_DAYS% days...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR; $days = [int]$env:OLD_DAYS; $scope = $env:ARCH_SCOPE; $fmt = $env:ARCH_FMT; $log = $env:LOG_FILE;" ^
  "$excluded = @('Organize_Downloads_Windows.bat','Organize_Downloads_macOS.command','Organize_Downloads_Linux.sh','Organize_Downloads.bat','organize_history.log','custom_rules.txt','preview_sim.tmp');" ^
  "if ($scope -eq 'root') {" ^
  "  $files = Get-ChildItem -LiteralPath $dir -File | Where-Object { $excluded -notcontains $_.Name };" ^
  "} else {" ^
  "  $files = Get-ChildItem -LiteralPath $dir -File -Recurse | Where-Object { $excluded -notcontains $_.Name -and $_.FullName -notmatch '[\\/]Archive_Old[\\/]' };" ^
  "}" ^
  "$now = Get-Date;" ^
  "$old = @($files | Where-Object { ($now - $_.LastWriteTime).Days -gt $days });" ^
  "if ($old.Count -eq 0) { Write-Host ('No files older than {0} days found.' -f $days) -ForegroundColor Yellow; exit 0 };" ^
  "$totalBytes = ($old | Measure-Object -Property Length -Sum).Sum;" ^
  "$mb = [Math]::Round($totalBytes / 1MB, 2);" ^
  "Write-Host ('Found {0} file(s) older than {1} days occupying {2} MB.' -f $old.Count, $days, $mb);" ^
  "$archiveBase = Join-Path $dir 'Archive_Old';" ^
  "$count = 0;" ^
  "foreach ($f in $old) {" ^
  "  if ($fmt -eq 'date') {" ^
  "    $ym = $f.LastWriteTime.ToString('yyyy-MM');" ^
  "    $destFolder = Join-Path $archiveBase $ym;" ^
  "  } elseif ($fmt -eq 'rel') {" ^
  "    $rel = $f.DirectoryName.Substring($dir.Length).TrimStart('\', '/');" ^
  "    $destFolder = if ($rel) { Join-Path $archiveBase $rel } else { $archiveBase };" ^
  "  } else {" ^
  "    $destFolder = $archiveBase;" ^
  "  };" ^
  "  if (!(Test-Path -LiteralPath $destFolder)) { New-Item -ItemType Directory -Force -Path $destFolder | Out-Null };" ^
  "  $destFile = Join-Path $destFolder $f.Name;" ^
  "  $finalPath = $destFile; $idx = 1;" ^
  "  while (Test-Path -LiteralPath $finalPath) {" ^
  "    $finalPath = Join-Path $destFolder ('{0}_old{1}{2}' -f $f.BaseName, $idx, $f.Extension); $idx++;" ^
  "  };" ^
  "  Move-Item -LiteralPath $f.FullName -Destination $finalPath -Force;" ^
  "  Add-Content -LiteralPath $log -Value ('{0}|{1}' -f $finalPath, $f.FullName);" ^
  "  Write-Host (' [+] Archived: {0} -> Archive_Old\' -f $f.Name) -ForegroundColor Green;" ^
  "  $count++;" ^
  "};" ^
  "Write-Host '';" ^
  "Write-Host ('[V] Successfully archived {0} file(s) into Archive_Old\' -f $count) -ForegroundColor Cyan;"
echo.
pause
goto :ArchiveOldMenu

:RunArchivePreview
echo.
echo Select minimum age to preview:
echo  [1] Older than 30 days
echo  [2] Older than 60 days
echo  [3] Older than 90 days
echo.
set "P_AGE="
set /p "P_AGE=Enter choice [1-3, default=3]: "
set "OLD_DAYS=90"
if "%P_AGE%"=="1" set "OLD_DAYS=30"
if "%P_AGE%"=="2" set "OLD_DAYS=60"

echo.
echo [*] Scanning for old files preview...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR; $days = [int]$env:OLD_DAYS;" ^
  "$excluded = @('Organize_Downloads_Windows.bat','Organize_Downloads_macOS.command','Organize_Downloads_Linux.sh','Organize_Downloads.bat','organize_history.log','custom_rules.txt','preview_sim.tmp');" ^
  "$files = Get-ChildItem -LiteralPath $dir -File -Recurse | Where-Object { $excluded -notcontains $_.Name -and $_.FullName -notmatch '[\\/]Archive_Old[\\/]' };" ^
  "$now = Get-Date;" ^
  "$old = @($files | Where-Object { ($now - $_.LastWriteTime).Days -gt $days });" ^
  "if ($old.Count -eq 0) { Write-Host ('No files older than {0} days found.' -f $days) -ForegroundColor Yellow; exit 0 };" ^
  "$totalBytes = ($old | Measure-Object -Property Length -Sum).Sum;" ^
  "$mb = [Math]::Round($totalBytes / 1MB, 2);" ^
  "Write-Host ('--- Detected Old Files ({0} files, {1} MB older than {2} days) ---' -f $old.Count, $mb, $days) -ForegroundColor Cyan;" ^
  "foreach ($f in $old | Select-Object -First 30) {" ^
  "  $age = ($now - $f.LastWriteTime).Days;" ^
  "  $rel = $f.FullName.Substring($dir.Length).TrimStart('\', '/');" ^
  "  $sizeStr = if ($f.Length -gt 1MB) { '{0:N1} MB' -f ($f.Length/1MB) } else { '{0:N0} KB' -f ($f.Length/1KB) };" ^
  "  Write-Host ('  - {0,-40} [{1}, {2} days old]' -f $rel, $sizeStr, $age);" ^
  "};" ^
  "if ($old.Count -gt 30) { Write-Host ('  ... and {0} more old files.' -f ($old.Count - 30)) -ForegroundColor Gray };"
echo.
pause
goto :ArchiveOldMenu

rem ========================================================
rem Temporary & Broken Downloads Cleaner
rem ========================================================
:JunkMenu
cls
echo ======================================================
echo         Temporary ^& Broken Downloads Cleaner
echo ======================================================
echo Folder: %CD%
echo.
echo Incomplete downloads (.crdownload, .part), temporary cache
echo files (.tmp), and 0-byte corrupt files waste disk space.
echo.
echo Select an option:
echo.
echo  [1] Scan ^& Quarantine Junk into "Junk_Temp\" (Safe ^& Reversible)
echo      Moves partial/junk files to a quarantine folder
echo.
echo  [2] Preview / List Junk Files (Report Only)
echo      Lists all incomplete and empty files found
echo.
echo  [3] Permanently Delete Staged Junk ("Junk_Temp\" folder)
echo      Frees disk space after you've reviewed the quarantined files
echo.
echo  [0] Back to Main Menu
echo.
echo ======================================================
set "JUNK_CHOICE="
set /p "JUNK_CHOICE=Enter choice [0-3]: "

if "%JUNK_CHOICE%"=="" goto :JunkMenu
if "%JUNK_CHOICE%"=="0" goto :MainMenu
if "%JUNK_CHOICE%"=="1" goto :RunJunkQuarantine
if "%JUNK_CHOICE%"=="2" goto :RunJunkPreview
if "%JUNK_CHOICE%"=="3" goto :RunDeleteJunk

echo.
echo [!] Invalid selection. Please choose an option from the menu.
echo.
pause
goto :JunkMenu

:RunJunkQuarantine
echo.
echo [*] Scanning for temporary, partial, and 0-byte files...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR; $log = $env:LOG_FILE;" ^
  "$excluded = @('Organize_Downloads_Windows.bat','Organize_Downloads_macOS.command','Organize_Downloads_Linux.sh','Organize_Downloads.bat','organize_history.log','custom_rules.txt','preview_sim.tmp');" ^
  "$junkExts = @('.crdownload', '.part', '.opdownload', '.partial', '.tmp', '.download');" ^
  "$files = Get-ChildItem -LiteralPath $dir -File -Recurse | Where-Object {" ^
  "  $excluded -notcontains $_.Name -and $_.FullName -notmatch '[\\/]Junk_Temp[\\/]' -and $_.FullName -notmatch '[\\/]Duplicates[\\/]'" ^
  "};" ^
  "$junk = @($files | Where-Object { $junkExts -contains $_.Extension.ToLower() -or $_.Length -eq 0 });" ^
  "if ($junk.Count -eq 0) { Write-Host 'No temporary or broken download files found.' -ForegroundColor Yellow; exit 0 };" ^
  "$totalBytes = ($junk | Measure-Object -Property Length -Sum).Sum;" ^
  "$mb = [Math]::Round($totalBytes / 1MB, 2);" ^
  "Write-Host ('Found {0} junk/broken file(s) occupying {1} MB.' -f $junk.Count, $mb);" ^
  "$junkBase = Join-Path $dir 'Junk_Temp';" ^
  "$count = 0;" ^
  "foreach ($j in $junk) {" ^
  "  $rel = $j.DirectoryName.Substring($dir.Length).TrimStart('\', '/');" ^
  "  $destFolder = if ($rel) { Join-Path $junkBase $rel } else { $junkBase };" ^
  "  if (!(Test-Path -LiteralPath $destFolder)) { New-Item -ItemType Directory -Force -Path $destFolder | Out-Null };" ^
  "  $destFile = Join-Path $destFolder $j.Name;" ^
  "  $finalPath = $destFile; $idx = 1;" ^
  "  while (Test-Path -LiteralPath $finalPath) {" ^
  "    $finalPath = Join-Path $destFolder ('{0}_junk{1}{2}' -f $j.BaseName, $idx, $j.Extension); $idx++;" ^
  "  };" ^
  "  Move-Item -LiteralPath $j.FullName -Destination $finalPath -Force;" ^
  "  Add-Content -LiteralPath $log -Value ('{0}|{1}' -f $finalPath, $j.FullName);" ^
  "  Write-Host (' [+] Quarantined: {0} -> Junk_Temp\{1}' -f $j.Name, $rel) -ForegroundColor Green;" ^
  "  $count++;" ^
  "};" ^
  "Write-Host '';" ^
  "Write-Host ('[V] Successfully quarantined {0} junk file(s) into Junk_Temp\' -f $count) -ForegroundColor Cyan;"
echo.
pause
goto :JunkMenu

:RunJunkPreview
echo.
echo [*] Scanning for junk files report...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR;" ^
  "$excluded = @('Organize_Downloads_Windows.bat','Organize_Downloads_macOS.command','Organize_Downloads_Linux.sh','Organize_Downloads.bat','organize_history.log','custom_rules.txt','preview_sim.tmp');" ^
  "$junkExts = @('.crdownload', '.part', '.opdownload', '.partial', '.tmp', '.download');" ^
  "$files = Get-ChildItem -LiteralPath $dir -File -Recurse | Where-Object {" ^
  "  $excluded -notcontains $_.Name -and $_.FullName -notmatch '[\\/]Junk_Temp[\\/]' -and $_.FullName -notmatch '[\\/]Duplicates[\\/]'" ^
  "};" ^
  "$junk = @($files | Where-Object { $junkExts -contains $_.Extension.ToLower() -or $_.Length -eq 0 });" ^
  "if ($junk.Count -eq 0) { Write-Host 'No temporary or broken download files found.' -ForegroundColor Yellow; exit 0 };" ^
  "$totalBytes = ($junk | Measure-Object -Property Length -Sum).Sum;" ^
  "$mb = [Math]::Round($totalBytes / 1MB, 2);" ^
  "Write-Host ('--- Detected Junk / Temporary Files ({0} files, {1} MB) ---' -f $junk.Count, $mb) -ForegroundColor Cyan;" ^
  "foreach ($j in $junk | Select-Object -First 30) {" ^
  "  $rel = $j.FullName.Substring($dir.Length).TrimStart('\', '/');" ^
  "  $reason = if ($j.Length -eq 0) { '0-byte empty file' } else { 'Incomplete download/cache' };" ^
  "  Write-Host ('  - {0,-40} [{1}]' -f $rel, $reason);" ^
  "};" ^
  "if ($junk.Count -gt 30) { Write-Host ('  ... and {0} more junk files.' -f ($junk.Count - 30)) -ForegroundColor Gray };"
echo.
pause
goto :JunkMenu

:RunDeleteJunk
cls
echo ======================================================
echo           Delete Quarantined Junk Folder
echo ======================================================
set "JUNK_DIR=%TARGET_DIR%Junk_Temp"
if not exist "%JUNK_DIR%" (
    echo.
    echo [*] No "Junk_Temp\" folder found. Nothing to delete.
    echo.
    pause
    goto :JunkMenu
)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:JUNK_DIR;" ^
  "$files = Get-ChildItem -LiteralPath $dir -File -Recurse;" ^
  "if ($files.Count -eq 0) { Write-Host 'Junk_Temp folder is empty.' -ForegroundColor Yellow; exit 0 };" ^
  "$totalBytes = ($files | Measure-Object -Property Length -Sum).Sum;" ^
  "$mb = [Math]::Round($totalBytes / 1MB, 2);" ^
  "Write-Host ('Quarantined Junk: {0} file(s) occupying {1} MB' -f $files.Count, $mb) -ForegroundColor Yellow;"
echo.
echo WARNING: This action will permanently remove all files inside
echo the "%JUNK_DIR%" folder to reclaim your disk space!
echo.
set "CONFIRM_DEL="
set /p "CONFIRM_DEL=Type DELETE to confirm permanent deletion: "
if not "%CONFIRM_DEL%"=="DELETE" (
    echo.
    echo [*] Deletion cancelled. Files were NOT touched.
    echo.
    pause
    goto :JunkMenu
)

echo.
echo [*] Deleting Junk_Temp folder...
rmdir /s /q "%JUNK_DIR%"
echo.
echo [V] "Junk_Temp\" folder and all its contents have been removed.
echo.
pause
goto :JunkMenu

rem ========================================================
rem Empty Folder Sweeper
rem ========================================================
:EmptyFolderMenu
cls
echo ======================================================
echo              Empty Folder Sweeper
echo ======================================================
echo Folder: %CD%
echo.
echo Scans Downloads and removes empty subfolders leftover
echo from moved or deleted files.
echo.
echo [*] Scanning for empty folders...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR;" ^
  "$emptyDirs = Get-ChildItem -LiteralPath $dir -Directory -Recurse | Where-Object {" ^
  "  (Get-ChildItem -LiteralPath $_.FullName -Recurse -File).Count -eq 0" ^
  "} | Sort-Object -Property { $_.FullName.Length } -Descending;" ^
  "if ($emptyDirs.Count -eq 0) { Write-Host 'No empty folders found. All folders contain files!' -ForegroundColor Green; exit 0 };" ^
  "Write-Host ('Found {0} empty folder(s):' -f $emptyDirs.Count) -ForegroundColor Yellow;" ^
  "foreach ($ed in $emptyDirs | Select-Object -First 20) {" ^
  "  $rel = $ed.FullName.Substring($dir.Length).TrimStart('\', '/');" ^
  "  Write-Host ('  - {0}' -f $rel);" ^
  "};" ^
  "if ($emptyDirs.Count -gt 20) { Write-Host ('  ... and {0} more empty folders.' -f ($emptyDirs.Count - 20)) -ForegroundColor Gray };"
echo.
set "CONFIRM_EMPTY="
set /p "CONFIRM_EMPTY=Remove all empty folders now? [Y/N]: "
if /i not "%CONFIRM_EMPTY%"=="Y" (
    echo.
    echo [*] Clean cancelled. Empty folders were NOT removed.
    echo.
    pause
    goto :MainMenu
)

echo.
echo [*] Removing empty folders...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR;" ^
  "$emptyDirs = Get-ChildItem -LiteralPath $dir -Directory -Recurse | Where-Object {" ^
  "  (Get-ChildItem -LiteralPath $_.FullName -Recurse -File).Count -eq 0" ^
  "} | Sort-Object -Property { $_.FullName.Length } -Descending;" ^
  "$count = 0;" ^
  "foreach ($ed in $emptyDirs) {" ^
  "  if (Test-Path -LiteralPath $ed.FullName) {" ^
  "    Remove-Item -LiteralPath $ed.FullName -Force -Recurse;" ^
  "    $count++;" ^
  "  };" ^
  "};" ^
  "Write-Host ('[V] Successfully removed {0} empty folder(s).' -f $count) -ForegroundColor Cyan;"
echo.
pause
goto :MainMenu

rem ========================================================
rem Task Scheduler Automation Menu
rem ========================================================
:ScheduleMenu
cls
echo ======================================================
echo           Task Scheduler Automation
echo ======================================================
echo Script: %~f0
echo.
echo Configure Windows to automatically organize your Downloads
echo in the background on a recurring schedule without any popups.
echo.
schtasks /query /tn "DownloadsOrganizer" >nul 2>&1
if errorlevel 1 (
    echo Current Status: [INACTIVE] No scheduled task registered.
) else (
    echo Current Status: [ACTIVE] Scheduled task is currently active!
)
echo.
echo Select an option:
echo.
echo  [1] Run Automatically Every Day at 8:00 PM
echo  [2] Run Automatically Every Sunday at 8:00 PM
echo  [3] Run Automatically on Windows User Login / Startup
echo  [4] Custom Daily Schedule (Choose your own time)
echo  [5] Remove / Disable Scheduled Automation
echo  [6] View Active Task Details in Windows Task Scheduler
echo.
echo  [0] Back to Main Menu
echo.
echo ======================================================
set "SCH_CHOICE="
set /p "SCH_CHOICE=Enter choice [0-6]: "

if "%SCH_CHOICE%"=="" goto :ScheduleMenu
if "%SCH_CHOICE%"=="0" goto :MainMenu
if "%SCH_CHOICE%"=="1" goto :SetDailySchedule
if "%SCH_CHOICE%"=="2" goto :SetWeeklySchedule
if "%SCH_CHOICE%"=="3" goto :SetLogonSchedule
if "%SCH_CHOICE%"=="4" goto :SetCustomSchedule
if "%SCH_CHOICE%"=="5" goto :DeleteSchedule
if "%SCH_CHOICE%"=="6" goto :ViewSchedule

echo.
echo [!] Invalid selection. Please choose an option from the menu.
echo.
pause
goto :ScheduleMenu

:SetDailySchedule
echo.
echo [*] Registering Daily scheduled task at 8:00 PM...
schtasks /create /tn "DownloadsOrganizer" /tr "\"%~f0\" /silent" /sc daily /st 20:00 /f
if errorlevel 1 (
    echo [!] Failed to create scheduled task.
) else (
    echo [V] Successfully scheduled! Windows will organize Downloads daily at 8:00 PM.
)
echo.
pause
goto :ScheduleMenu

:SetWeeklySchedule
echo.
echo [*] Registering Weekly scheduled task every Sunday at 8:00 PM...
schtasks /create /tn "DownloadsOrganizer" /tr "\"%~f0\" /silent" /sc weekly /d SUN /st 20:00 /f
if errorlevel 1 (
    echo [!] Failed to create scheduled task.
) else (
    echo [V] Successfully scheduled! Windows will organize Downloads every Sunday at 8:00 PM.
)
echo.
pause
goto :ScheduleMenu

:SetLogonSchedule
echo.
echo [*] Registering scheduled task on Windows User Login...
schtasks /create /tn "DownloadsOrganizer" /tr "\"%~f0\" /silent" /sc onlogon /f
if errorlevel 1 (
    echo [!] Note: Login triggers may require administrator privileges.
) else (
    echo [V] Successfully scheduled to run whenever you log into Windows!
)
echo.
pause
goto :ScheduleMenu

:SetCustomSchedule
echo.
set "CUSTOM_TIME="
set /p "CUSTOM_TIME=Enter time in 24-hour format HH:MM (e.g. 14:30 or 23:00): "
if "%CUSTOM_TIME%"=="" goto :ScheduleMenu
echo.
echo [*] Registering Daily scheduled task at %CUSTOM_TIME%...
schtasks /create /tn "DownloadsOrganizer" /tr "\"%~f0\" /silent" /sc daily /st %CUSTOM_TIME% /f
if errorlevel 1 (
    echo [!] Failed to create scheduled task. Please check time format (HH:MM).
) else (
    echo [V] Successfully scheduled! Windows will organize Downloads daily at %CUSTOM_TIME%.
)
echo.
pause
goto :ScheduleMenu

:DeleteSchedule
echo.
echo [*] Removing scheduled task...
schtasks /delete /tn "DownloadsOrganizer" /f
if errorlevel 1 (
    echo [*] No scheduled task found to remove.
) else (
    echo [V] Scheduled task has been successfully removed.
)
echo.
pause
goto :ScheduleMenu

:ViewSchedule
cls
echo ======================================================
echo           Active Task Scheduler Details
echo ======================================================
echo.
schtasks /query /tn "DownloadsOrganizer" /fo LIST /v 2>nul
if errorlevel 1 (
    echo [!] No "DownloadsOrganizer" task is currently registered.
)
echo.
pause
goto :ScheduleMenu

rem ========================================================
rem Storage Analytics & Space Hogs Dashboard
rem ========================================================
:AnalyticsMenu
cls
echo ======================================================
echo         Storage Analytics ^& Space Hogs
echo ======================================================
echo Folder: %CD%
echo.
echo [*] Calculating disk usage and scanning space hogs...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR;" ^
  "$excluded = @('Organize_Downloads_Windows.bat','Organize_Downloads_macOS.command','Organize_Downloads_Linux.sh','Organize_Downloads.bat','organize_history.log','custom_rules.txt','preview_sim.tmp');" ^
  "$files = Get-ChildItem -LiteralPath $dir -File -Recurse | Where-Object { $excluded -notcontains $_.Name };" ^
  "$totalFiles = $files.Count;" ^
  "$totalBytes = ($files | Measure-Object -Property Length -Sum).Sum;" ^
  "$totalGB = [Math]::Round($totalBytes / 1GB, 2);" ^
  "Write-Host ('Total Files: {0:N0} files  |  Total Space: {1} GB' -f $totalFiles, $totalGB) -ForegroundColor Green;" ^
  "Write-Host '';" ^
  "$dirs = Get-ChildItem -LiteralPath $dir -Directory | Where-Object { $_.Name -notmatch '^\.' };" ^
  "$catStats = @();" ^
  "foreach ($d in $dirs) {" ^
  "  $dFiles = Get-ChildItem -LiteralPath $d.FullName -File -Recurse;" ^
  "  if ($dFiles.Count -gt 0) {" ^
  "    $bytes = ($dFiles | Measure-Object -Property Length -Sum).Sum;" ^
  "    $catStats += [PSCustomObject]@{ Name = $d.Name; Bytes = $bytes; Count = $dFiles.Count };" ^
  "  };" ^
  "};" ^
  "$rootFiles = Get-ChildItem -LiteralPath $dir -File | Where-Object { $excluded -notcontains $_.Name };" ^
  "if ($rootFiles.Count -gt 0) {" ^
  "  $rBytes = ($rootFiles | Measure-Object -Property Length -Sum).Sum;" ^
  "  $catStats += [PSCustomObject]@{ Name = '[Root / Loose Files]'; Bytes = $rBytes; Count = $rootFiles.Count };" ^
  "};" ^
  "$catStats = $catStats | Sort-Object -Property Bytes -Descending;" ^
  "Write-Host '--- Category Space Breakdown ---' -ForegroundColor Yellow;" ^
  "$barWidth = 16;" ^
  "foreach ($cat in $catStats) {" ^
  "  $pct = if ($totalBytes -gt 0) { $cat.Bytes / $totalBytes } else { 0 };" ^
  "  $filled = [Math]::Min($barWidth, [Math]::Max(0, [int][Math]::Round($pct * $barWidth)));" ^
  "  $unfilled = $barWidth - $filled;" ^
  "  $bar = ('#' * $filled) + ('-' * $unfilled);" ^
  "  $sizeStr = if ($cat.Bytes -gt 1GB) { '{0,6:N1} GB' -f ($cat.Bytes / 1GB) } else { '{0,6:N1} MB' -f ($cat.Bytes / 1MB) };" ^
  "  Write-Host (' {0,-20} | {1} | {2} ({3,4} files, {4,4:P0})' -f $cat.Name, $bar, $sizeStr, $cat.Count, $pct);" ^
  "};" ^
  "Write-Host '';" ^
  "Write-Host '--- Top 10 Largest Space Hog Files ---' -ForegroundColor Yellow;" ^
  "$top10 = $files | Sort-Object -Property Length -Descending | Select-Object -First 10;" ^
  "$rank = 1;" ^
  "foreach ($f in $top10) {" ^
  "  $rel = $f.FullName.Substring($dir.Length).TrimStart('\', '/');" ^
  "  if ($rel.Length -gt 50) { $rel = '...' + $rel.Substring($rel.Length - 47) };" ^
  "  $sizeStr = if ($f.Length -gt 1GB) { '{0,6:N1} GB' -f ($f.Length / 1GB) } else { '{0,6:N1} MB' -f ($f.Length / 1MB) };" ^
  "  Write-Host (' {0,2}. {1,-50} [{2}]' -f $rank, $rel, $sizeStr);" ^
  "  $rank++;" ^
  "};" ^
  "Write-Host '';" ^
  "Write-Host '--- Clutter & Housekeeping Health Check ---' -ForegroundColor Yellow;" ^
  "$pattern = '\s*\(\d+\)$|\s*-\s*Copy(\s*\(\d+\))?$';" ^
  "$dups = @($files | Where-Object { $_.BaseName -match $pattern -and $_.FullName -notmatch '[\\/]Duplicates[\\/]' });" ^
  "$dupBytes = ($dups | Measure-Object -Property Length -Sum).Sum;" ^
  "$dupMB = [Math]::Round($dupBytes / 1MB, 1);" ^
  "$junkExts = @('.crdownload', '.part', '.opdownload', '.partial', '.tmp', '.download');" ^
  "$junk = @($files | Where-Object { ($junkExts -contains $_.Extension.ToLower() -or $_.Length -eq 0) -and $_.FullName -notmatch '[\\/]Junk_Temp[\\/]' });" ^
  "$now = Get-Date;" ^
  "$old90 = @($files | Where-Object { ($now - $_.LastWriteTime).Days -gt 90 -and $_.FullName -notmatch '[\\/]Archive_Old[\\/]' });" ^
  "$oldBytes = ($old90 | Measure-Object -Property Length -Sum).Sum;" ^
  "$oldGB = [Math]::Round($oldBytes / 1GB, 1);" ^
  "Write-Host (' [!] Numbered Duplicates : {0:N0} files ({1} MB) -> Option [D] to isolate' -f $dups.Count, $dupMB) -ForegroundColor $(if($dups.Count -gt 0){'Cyan'}else{'Green'});" ^
  "Write-Host (' [!] Junk/Broken Files   : {0:N0} files -> Option [J] to clean' -f $junk.Count) -ForegroundColor $(if($junk.Count -gt 0){'Yellow'}else{'Green'});" ^
  "Write-Host (' [!] Old Files (>90 days): {0:N0} files ({1} GB) -> Option [A] to archive' -f $old90.Count, $oldGB) -ForegroundColor $(if($old90.Count -gt 0){'Magenta'}else{'Green'});" ^
  "Write-Host '======================================================' -ForegroundColor Cyan;"
echo.
pause
goto :MainMenu

rem ========================================================
rem Smart Batch Renamer
rem ========================================================
:RenamerMenu
cls
echo ======================================================
echo                Smart Batch Renamer
echo ======================================================
echo Folder: %CD%
echo.
echo Normalize and clean messy download filenames across your files.
echo (All renames show a preview first and are 100%% reversible via Undo)
echo.
echo Select renaming mode:
echo.
echo  [1] Clean Web Duplicate Tags (Remove *(1)*, * - Copy*, etc.)
echo  [2] Fix URL-Encoded Names (Convert %%20 to space, %%26 to ^&, etc.)
echo  [3] Add Date Prefix to Files (YYYY-MM-DD_filename.ext)
echo  [4] Replace Spaces with Underscores (file_name.ext)
echo  [5] Replace Underscores with Spaces (file name.ext)
echo  [6] Normalize to Lowercase (all lowercase names)
echo  [7] Custom Text Find ^& Replace in Filenames
echo.
echo  [0] Back to Main Menu
echo.
echo ======================================================
set "REN_CHOICE="
set /p "REN_CHOICE=Enter choice [0-7]: "

if "%REN_CHOICE%"=="" goto :RenamerMenu
if "%REN_CHOICE%"=="0" goto :MainMenu
if "%REN_CHOICE%"=="1" set "REN_MODE=clean_tags" & goto :RunBatchRename
if "%REN_CHOICE%"=="2" set "REN_MODE=url_decode" & goto :RunBatchRename
if "%REN_CHOICE%"=="3" set "REN_MODE=date_prefix" & goto :RunBatchRename
if "%REN_CHOICE%"=="4" set "REN_MODE=spaces_to_underscores" & goto :RunBatchRename
if "%REN_CHOICE%"=="5" set "REN_MODE=underscores_to_spaces" & goto :RunBatchRename
if "%REN_CHOICE%"=="6" set "REN_MODE=lowercase" & goto :RunBatchRename
if "%REN_CHOICE%"=="7" goto :PromptCustomReplace

echo.
echo [!] Invalid selection. Please choose an option from the menu.
echo.
pause
goto :RenamerMenu

:PromptCustomReplace
echo.
set "FIND_TXT="
set /p "FIND_TXT=Enter text to find in filenames: "
if "%FIND_TXT%"=="" goto :RenamerMenu
set "REPLACE_TXT="
set /p "REPLACE_TXT=Enter replacement text (or leave blank to remove): "
set "REN_MODE=custom_replace"
goto :RunBatchRename

:RunBatchRename
echo.
echo Select scan scope:
echo  [1] Entire Downloads folder (all subfolders included)
echo  [2] Downloads root only
echo.
set "SCOPE_CHOICE="
set /p "SCOPE_CHOICE=Enter scope [1-2, default=1]: "
set "REN_SCOPE=all"
if "%SCOPE_CHOICE%"=="2" set "REN_SCOPE=root"

echo.
echo [*] Analyzing filenames for renaming preview...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR; $mode = $env:REN_MODE; $scope = $env:REN_SCOPE; $log = $env:LOG_FILE;" ^
  "$findTxt = $env:FIND_TXT; $repTxt = $env:REPLACE_TXT;" ^
  "$excluded = @('Organize_Downloads_Windows.bat','Organize_Downloads_macOS.command','Organize_Downloads_Linux.sh','Organize_Downloads.bat','organize_history.log','custom_rules.txt','preview_sim.tmp');" ^
  "if ($scope -eq 'root') {" ^
  "  $files = Get-ChildItem -LiteralPath $dir -File | Where-Object { $excluded -notcontains $_.Name };" ^
  "} else {" ^
  "  $files = Get-ChildItem -LiteralPath $dir -File -Recurse | Where-Object { $excluded -notcontains $_.Name };" ^
  "}" ^
  "$changes = @();" ^
  "foreach ($f in $files) {" ^
  "  $oldName = $f.Name; $base = $f.BaseName; $ext = $f.Extension; $newBase = $base;" ^
  "  if ($mode -eq 'clean_tags') {" ^
  "    $newBase = $newBase -replace '\s*\(\d+\)$', '' -replace '\s*-\s*Copy(\s*\(\d+\))?$', '';" ^
  "  } elseif ($mode -eq 'url_decode') {" ^
  "    $newBase = [System.Uri]::UnescapeDataString($newBase);" ^
  "  } elseif ($mode -eq 'spaces_to_underscores') {" ^
  "    $newBase = $newBase -replace '\s+', '_';" ^
  "  } elseif ($mode -eq 'underscores_to_spaces') {" ^
  "    $newBase = $newBase -replace '_+', ' ';" ^
  "  } elseif ($mode -eq 'date_prefix') {" ^
  "    $ds = $f.LastWriteTime.ToString('yyyy-MM-dd');" ^
  "    if ($newBase -notmatch '^\d{4}-\d{2}-\d{2}_') { $newBase = '${ds}_' + $newBase };" ^
  "  } elseif ($mode -eq 'lowercase') {" ^
  "    $newBase = $newBase.ToLower();" ^
  "  } elseif ($mode -eq 'custom_replace' -and $findTxt) {" ^
  "    $newBase = $newBase.Replace($findTxt, $repTxt);" ^
  "  };" ^
  "  $newName = $newBase + $ext;" ^
  "  if ($newName -ne $oldName) {" ^
  "    $dest = Join-Path $f.DirectoryName $newName;" ^
  "    $changes += [PSCustomObject]@{ File = $f; Old = $oldName; New = $newName; Dest = $dest };" ^
  "  };" ^
  "};" ^
  "if ($changes.Count -eq 0) { Write-Host 'No files needed renaming for this rule.' -ForegroundColor Yellow; exit 0 };" ^
  "Write-Host ('--- Rename Preview: {0} file(s) will be renamed ---' -f $changes.Count) -ForegroundColor Cyan;" ^
  "foreach ($c in $changes | Select-Object -First 25) {" ^
  "  Write-Host ('  - {0}' -f $c.Old) -ForegroundColor Gray;" ^
  "  Write-Host ('    -> {0}' -f $c.New) -ForegroundColor Green;" ^
  "};" ^
  "if ($changes.Count -gt 25) { Write-Host ('  ... and {0} more files.' -f ($changes.Count - 25)) -ForegroundColor Gray };"
echo.
set "CONFIRM_REN="
set /p "CONFIRM_REN=Apply these renames now? [Y/N]: "
if /i not "%CONFIRM_REN%"=="Y" (
    echo.
    echo [*] Rename cancelled. No files were modified.
    echo.
    pause
    goto :RenamerMenu
)

echo.
echo [*] Applying renames...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR; $mode = $env:REN_MODE; $scope = $env:REN_SCOPE; $log = $env:LOG_FILE;" ^
  "$findTxt = $env:FIND_TXT; $repTxt = $env:REPLACE_TXT;" ^
  "$excluded = @('Organize_Downloads_Windows.bat','Organize_Downloads_macOS.command','Organize_Downloads_Linux.sh','Organize_Downloads.bat','organize_history.log','custom_rules.txt','preview_sim.tmp');" ^
  "if ($scope -eq 'root') {" ^
  "  $files = Get-ChildItem -LiteralPath $dir -File | Where-Object { $excluded -notcontains $_.Name };" ^
  "} else {" ^
  "  $files = Get-ChildItem -LiteralPath $dir -File -Recurse | Where-Object { $excluded -notcontains $_.Name };" ^
  "}" ^
  "$count = 0;" ^
  "foreach ($f in $files) {" ^
  "  $oldName = $f.Name; $base = $f.BaseName; $ext = $f.Extension; $newBase = $base;" ^
  "  if ($mode -eq 'clean_tags') {" ^
  "    $newBase = $newBase -replace '\s*\(\d+\)$', '' -replace '\s*-\s*Copy(\s*\(\d+\))?$', '';" ^
  "  } elseif ($mode -eq 'url_decode') {" ^
  "    $newBase = [System.Uri]::UnescapeDataString($newBase);" ^
  "  } elseif ($mode -eq 'spaces_to_underscores') {" ^
  "    $newBase = $newBase -replace '\s+', '_';" ^
  "  } elseif ($mode -eq 'underscores_to_spaces') {" ^
  "    $newBase = $newBase -replace '_+', ' ';" ^
  "  } elseif ($mode -eq 'date_prefix') {" ^
  "    $ds = $f.LastWriteTime.ToString('yyyy-MM-dd');" ^
  "    if ($newBase -notmatch '^\d{4}-\d{2}-\d{2}_') { $newBase = '${ds}_' + $newBase };" ^
  "  } elseif ($mode -eq 'lowercase') {" ^
  "    $newBase = $newBase.ToLower();" ^
  "  } elseif ($mode -eq 'custom_replace' -and $findTxt) {" ^
  "    $newBase = $newBase.Replace($findTxt, $repTxt);" ^
  "  };" ^
  "  $newName = $newBase + $ext;" ^
  "  if ($newName -ne $oldName) {" ^
  "    $dest = Join-Path $f.DirectoryName $newName;" ^
  "    $finalDest = $dest; $idx = 1;" ^
  "    while (Test-Path -LiteralPath $finalDest) {" ^
  "      $finalDest = Join-Path $f.DirectoryName ('{0}_{1}{2}' -f $newBase, $idx, $ext); $idx++;" ^
  "    };" ^
  "    Rename-Item -LiteralPath $f.FullName -NewName (Split-Path $finalDest -Leaf) -Force;" ^
  "    Add-Content -LiteralPath $log -Value ('{0}|{1}' -f $finalDest, $f.FullName);" ^
  "    $count++;" ^
  "  };" ^
  "};" ^
  "Write-Host ('[V] Successfully renamed {0} file(s).' -f $count) -ForegroundColor Cyan;"
echo.
pause
goto :RenamerMenu

rem ========================================================
rem Deep File Finder & Interactive Search
rem ========================================================
:FinderMenu
cls
echo ======================================================
echo           Deep File Finder ^& Search
echo ======================================================
echo Folder: %CD%
echo.
echo Search for files across Downloads and all subfolders.
echo.
echo Select search method:
echo.
echo  [1] Search by Keyword / Name (e.g. "invoice", "setup", "vacation")
echo  [2] Search by File Extension (e.g. "pdf", "zip", "exe", "png")
echo  [3] Search by Minimum File Size (e.g. files larger than 100 MB)
echo  [4] Search Recent Downloads (Modified in last 7 or 30 days)
echo.
echo  [0] Back to Main Menu
echo.
echo ======================================================
set "FND_CHOICE="
set /p "FND_CHOICE=Enter choice [0-4]: "

if "%FND_CHOICE%"=="" goto :FinderMenu
if "%FND_CHOICE%"=="0" goto :MainMenu
if "%FND_CHOICE%"=="1" goto :FindKeyword
if "%FND_CHOICE%"=="2" goto :FindExtension
if "%FND_CHOICE%"=="3" goto :FindSize
if "%FND_CHOICE%"=="4" goto :FindRecent

echo.
echo [!] Invalid selection. Please choose an option from the menu.
echo.
pause
goto :FinderMenu

:FindKeyword
echo.
set "FND_QUERY="
set /p "FND_QUERY=Enter keyword or partial filename: "
if "%FND_QUERY%"=="" goto :FinderMenu
set "FND_TYPE=keyword"
goto :ExecuteSearch

:FindExtension
echo.
set "FND_QUERY="
set /p "FND_QUERY=Enter file extension (e.g. pdf, zip, mp4): "
if "%FND_QUERY%"=="" goto :FinderMenu
set "FND_TYPE=ext"
goto :ExecuteSearch

:FindSize
echo.
set "FND_QUERY="
set /p "FND_QUERY=Enter minimum file size in MB (e.g. 50, 100, 500): "
if "%FND_QUERY%"=="" goto :FinderMenu
set "FND_TYPE=size"
goto :ExecuteSearch

:FindRecent
echo.
set "FND_QUERY="
set /p "FND_QUERY=Enter number of days (e.g. 7 or 30): "
if "%FND_QUERY%"=="" goto :FinderMenu
set "FND_TYPE=recent"
goto :ExecuteSearch

:ExecuteSearch
echo.
echo [*] Searching files...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:TARGET_DIR; $q = $env:FND_QUERY; $type = $env:FND_TYPE;" ^
  "$excluded = @('Organize_Downloads_Windows.bat','Organize_Downloads_macOS.command','Organize_Downloads_Linux.sh','Organize_Downloads.bat','organize_history.log','custom_rules.txt','preview_sim.tmp');" ^
  "$files = Get-ChildItem -LiteralPath $dir -File -Recurse | Where-Object { $excluded -notcontains $_.Name };" ^
  "if ($type -eq 'keyword') {" ^
  "  $matched = @($files | Where-Object { $_.Name -like ('*{0}*' -f $q) });" ^
  "} elseif ($type -eq 'ext') {" ^
  "  $cleanExt = if ($q.StartsWith('.')) { $q } else { '.' + $q };" ^
  "  $matched = @($files | Where-Object { $_.Extension -ieq $cleanExt });" ^
  "} elseif ($type -eq 'size') {" ^
  "  $minBytes = [int64]$q * 1MB;" ^
  "  $matched = @($files | Where-Object { $_.Length -ge $minBytes } | Sort-Object -Property Length -Descending);" ^
  "} elseif ($type -eq 'recent') {" ^
  "  $days = [int]$q; $since = (Get-Date).AddDays(-$days);" ^
  "  $matched = @($files | Where-Object { $_.LastWriteTime -ge $since } | Sort-Object -Property LastWriteTime -Descending);" ^
  "};" ^
  "if ($matched.Count -eq 0) { Write-Host 'No matching files found.' -ForegroundColor Yellow; exit 0 };" ^
  "$totalBytes = ($matched | Measure-Object -Property Length -Sum).Sum;" ^
  "$mb = [Math]::Round($totalBytes / 1MB, 1);" ^
  "Write-Host ('Found {0} matching file(s) ({1} MB):' -f $matched.Count, $mb) -ForegroundColor Cyan;" ^
  "Write-Host '------------------------------------------------------' -ForegroundColor Gray;" ^
  "foreach ($m in $matched | Select-Object -First 30) {" ^
  "  $rel = $m.FullName.Substring($dir.Length).TrimStart('\', '/');" ^
  "  $sizeStr = if ($m.Length -gt 1MB) { '{0,6:N1} MB' -f ($m.Length / 1MB) } else { '{0,6:N1} KB' -f ($m.Length / 1KB) };" ^
  "  Write-Host ('  [{0}] {1}' -f $sizeStr, $rel);" ^
  "};" ^
  "if ($matched.Count -gt 30) { Write-Host ('  ... and {0} more matching files.' -f ($matched.Count - 30)) -ForegroundColor Gray };"
echo.
pause
goto :FinderMenu

rem ========================================================
rem Windows Context Menu Integration
rem ========================================================
:ContextMenuMenu
cls
echo ======================================================
echo         Windows Context Menu Integration
echo ======================================================
echo Script: %~f0
echo.
echo Add a handy "Organize Files Here" option to the Windows Explorer
echo right-click menu so you can organize ANY folder (Desktop, external
echo drive, USB stick, project folder) with a single click.
echo.
echo Note: This configures your user profile registry (HKCU).
echo       No administrator privileges required.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "if (Test-Path 'HKCU:\Software\Classes\Directory\Background\shell\OrganizeDownloads') { Write-Host 'Current Status: [INSTALLED] Right-click menu option is ACTIVE' -ForegroundColor Green } else { Write-Host 'Current Status: [NOT INSTALLED] Right-click menu option is not added' -ForegroundColor Yellow }"
echo.
echo Select an option:
echo.
echo  [1] Install "Organize Files Here" to Right-Click Menu
echo  [2] Remove / Uninstall from Right-Click Menu
echo.
echo  [0] Back to Main Menu
echo.
echo ======================================================
set "CTX_CHOICE="
set /p "CTX_CHOICE=Enter choice [0-2]: "

if "%CTX_CHOICE%"=="" goto :ContextMenuMenu
if "%CTX_CHOICE%"=="0" goto :MainMenu
if "%CTX_CHOICE%"=="1" goto :InstallContextMenu
if "%CTX_CHOICE%"=="2" goto :UninstallContextMenu

echo.
echo [!] Invalid selection. Please choose an option from the menu.
echo.
pause
goto :ContextMenuMenu

:InstallContextMenu
echo.
echo [*] Adding right-click menu entry for current user...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$bat = '%~f0';" ^
  "$bgKey = 'HKCU:\Software\Classes\Directory\Background\shell\OrganizeDownloads';" ^
  "$dirKey = 'HKCU:\Software\Classes\Directory\shell\OrganizeDownloads';" ^
  "New-Item -Path $bgKey -Value 'Organize Files Here' -Force | Out-Null;" ^
  "Set-ItemProperty -Path $bgKey -Name 'Icon' -Value 'imageres.dll,-114' -Force;" ^
  "New-Item -Path (Join-Path $bgKey 'command') -Value ('\"\"{0}\"\"' -f $bat) -Force | Out-Null;" ^
  "New-Item -Path $dirKey -Value 'Organize with Downloads Organizer' -Force | Out-Null;" ^
  "Set-ItemProperty -Path $dirKey -Name 'Icon' -Value 'imageres.dll,-114' -Force;" ^
  "New-Item -Path (Join-Path $dirKey 'command') -Value ('\"\"{0}\"\" \"\"%1\"\"' -f $bat) -Force | Out-Null;" ^
  "Write-Host '[V] Successfully added to Windows Explorer right-click menu!' -ForegroundColor Green;"
echo.
pause
goto :ContextMenuMenu

:UninstallContextMenu
echo.
echo [*] Removing right-click menu entries...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Remove-Item -Path 'HKCU:\Software\Classes\Directory\Background\shell\OrganizeDownloads' -Recurse -Force -ErrorAction SilentlyContinue;" ^
  "Remove-Item -Path 'HKCU:\Software\Classes\Directory\shell\OrganizeDownloads' -Recurse -Force -ErrorAction SilentlyContinue;" ^
  "Write-Host '[V] Successfully removed from Windows Explorer right-click menu.' -ForegroundColor Green;"
echo.
pause
goto :ContextMenuMenu

rem ========================================================
rem Folder Compression & Zip Archiver
rem ========================================================
:CompressMenu
cls
echo ======================================================
echo           Folder Compression ^& Zip Archiver
echo ======================================================
echo Folder: %CD%
echo.
echo Compress inactive or archived folders into .zip files to reclaim
echo gigabytes of disk space while keeping files organized.
echo.
echo Select an option:
echo.
echo  [1] Compress "Archive_Old\" into Archive_Old.zip
echo  [2] Compress Any Category Folder (Images, Documents, Code, etc.)
echo  [3] Extract / Decompress a .zip Archive into a Folder
echo.
echo  [0] Back to Main Menu
echo.
echo ======================================================
set "ZIP_CHOICE="
set /p "ZIP_CHOICE=Enter choice [0-3]: "

if "%ZIP_CHOICE%"=="" goto :CompressMenu
if "%ZIP_CHOICE%"=="0" goto :MainMenu
if "%ZIP_CHOICE%"=="1" goto :CompressArchiveOld
if "%ZIP_CHOICE%"=="2" goto :CompressCategoryPrompt
if "%ZIP_CHOICE%"=="3" goto :ExtractZipPrompt

echo.
echo [!] Invalid selection. Please choose an option from the menu.
echo.
pause
goto :CompressMenu

:CompressArchiveOld
cls
echo ======================================================
echo           Compress "Archive_Old\" Folder
echo ======================================================
set "SRC_ARCHIVE=%TARGET_DIR%Archive_Old"
if not exist "%SRC_ARCHIVE%" (
    echo.
    echo [*] No "Archive_Old\" folder found in the active directory.
    echo     Run option [A] to archive older files first.
    echo.
    pause
    goto :CompressMenu
)
echo.
echo [*] Calculating size of "Archive_Old\"...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:SRC_ARCHIVE;" ^
  "$files = Get-ChildItem -LiteralPath $dir -File -Recurse;" ^
  "if ($files.Count -eq 0) { Write-Host 'Archive_Old is empty.' -ForegroundColor Yellow; exit 0 };" ^
  "$totalBytes = ($files | Measure-Object -Property Length -Sum).Sum;" ^
  "$mb = [Math]::Round($totalBytes / 1MB, 2);" ^
  "Write-Host ('Archive_Old contains {0} file(s) occupying {1} MB.' -f $files.Count, $mb) -ForegroundColor Cyan;"
echo.
set "CONFIRM_ZIP="
set /p "CONFIRM_ZIP=Compress Archive_Old into Archive_Old.zip now? [Y/N]: "
if /i not "%CONFIRM_ZIP%"=="Y" (
    echo.
    echo [*] Compression cancelled.
    echo.
    pause
    goto :CompressMenu
)

echo.
echo [*] Compressing Archive_Old... (this may take a moment for large files)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dir = $env:SRC_ARCHIVE; $parent = Split-Path $dir -Parent; $zip = Join-Path $parent 'Archive_Old.zip';" ^
  "$origBytes = (Get-ChildItem -LiteralPath $dir -File -Recurse | Measure-Object -Property Length -Sum).Sum;" ^
  "Compress-Archive -LiteralPath $dir -DestinationPath $zip -CompressionLevel Optimal -Force;" ^
  "$zipBytes = (Get-Item -LiteralPath $zip).Length;" ^
  "$saved = [Math]::Max(0, ($origBytes - $zipBytes));" ^
  "$savedMB = [Math]::Round($saved / 1MB, 2);" ^
  "$origMB = [Math]::Round($origBytes / 1MB, 2);" ^
  "$zipMB = [Math]::Round($zipBytes / 1MB, 2);" ^
  "$pct = if ($origBytes -gt 0) { [Math]::Round(($saved / $origBytes) * 100, 1) } else { 0 };" ^
  "Write-Host ('[V] Created: {0} ({1} MB)' -f (Split-Path $zip -Leaf), $zipMB) -ForegroundColor Green;" ^
  "Write-Host ('[V] Reclaimed: {0} MB ({1}% space saved!)' -f $savedMB, $pct) -ForegroundColor Cyan;"
echo.
set "DEL_ORIG="
set /p "DEL_ORIG=Delete the uncompressed Archive_Old folder to reclaim space? [Y/N]: "
if /i "%DEL_ORIG%"=="Y" (
    rmdir /s /q "%SRC_ARCHIVE%"
    echo [V] Removed uncompressed Archive_Old folder.
)
echo.
pause
goto :CompressMenu

:CompressCategoryPrompt
cls
echo ======================================================
echo           Compress Category Folder
echo ======================================================
echo Active Folder: %CD%
echo.
echo Available folders in this directory:
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dirs = Get-ChildItem -LiteralPath $env:TARGET_DIR -Directory | Where-Object { $_.Name -notmatch '^\.' };" ^
  "foreach ($d in $dirs) { Write-Host ('  - {0}' -f $d.Name) };"
echo.
set "CAT_TO_ZIP="
set /p "CAT_TO_ZIP=Enter folder name to compress (e.g. Images, Code, Documents): "
if "%CAT_TO_ZIP%"=="" goto :CompressMenu
set "TARGET_FOLDER=%TARGET_DIR%%CAT_TO_ZIP%"
if not exist "%TARGET_FOLDER%" (
    echo.
    echo [!] Folder "%CAT_TO_ZIP%" not found.
    echo.
    pause
    goto :CompressCategoryPrompt
)

echo.
echo [*] Compressing "%CAT_TO_ZIP%"...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$fld = $env:TARGET_FOLDER; $cat = $env:CAT_TO_ZIP; $parent = Split-Path $fld -Parent;" ^
  "$zip = Join-Path $parent ($cat + '.zip');" ^
  "$origBytes = (Get-ChildItem -LiteralPath $fld -File -Recurse | Measure-Object -Property Length -Sum).Sum;" ^
  "Compress-Archive -LiteralPath $fld -DestinationPath $zip -CompressionLevel Optimal -Force;" ^
  "$zipBytes = (Get-Item -LiteralPath $zip).Length;" ^
  "$saved = [Math]::Max(0, ($origBytes - $zipBytes));" ^
  "$savedMB = [Math]::Round($saved / 1MB, 2);" ^
  "$pct = if ($origBytes -gt 0) { [Math]::Round(($saved / $origBytes) * 100, 1) } else { 0 };" ^
  "Write-Host ('[V] Created: {0} ({1} MB)' -f (Split-Path $zip -Leaf), [Math]::Round($zipBytes / 1MB, 2)) -ForegroundColor Green;" ^
  "Write-Host ('[V] Space saved: {0} MB ({1}%)' -f $savedMB, $pct) -ForegroundColor Cyan;"
echo.
set "DEL_CAT_ORIG="
set /p "DEL_CAT_ORIG=Delete original uncompressed folder? [Y/N]: "
if /i "%DEL_CAT_ORIG%"=="Y" (
    rmdir /s /q "%TARGET_FOLDER%"
    echo [V] Removed uncompressed "%CAT_TO_ZIP%" folder.
)
echo.
pause
goto :CompressMenu

:ExtractZipPrompt
cls
echo ======================================================
echo           Extract / Decompress .zip Archive
echo ======================================================
echo Active Folder: %CD%
echo.
echo Available .zip files in this directory:
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$zips = Get-ChildItem -LiteralPath $env:TARGET_DIR -File -Filter *.zip;" ^
  "if ($zips.Count -eq 0) { Write-Host '  (No .zip files found)' -ForegroundColor Gray } else {" ^
  "  foreach ($z in $zips) { Write-Host ('  - {0} ({1} MB)' -f $z.Name, [Math]::Round($z.Length / 1MB, 2)) };" ^
  "};"
echo.
set "ZIP_TO_EXT="
set /p "ZIP_TO_EXT=Enter .zip filename to extract (e.g. Archive_Old.zip): "
if "%ZIP_TO_EXT%"=="" goto :CompressMenu
set "ZIP_FILE_PATH=%TARGET_DIR%%ZIP_TO_EXT%"
if not exist "%ZIP_FILE_PATH%" (
    echo.
    echo [!] File "%ZIP_TO_EXT%" not found.
    echo.
    pause
    goto :ExtractZipPrompt
)

echo.
echo [*] Extracting "%ZIP_TO_EXT%"...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$zip = $env:ZIP_FILE_PATH; $dir = $env:TARGET_DIR; $base = [System.IO.Path]::GetFileNameWithoutExtension($zip);" ^
  "$dest = Join-Path $dir $base;" ^
  "Expand-Archive -LiteralPath $zip -DestinationPath $dest -Force;" ^
  "Write-Host ('[V] Successfully extracted into: {0}\' -f $base) -ForegroundColor Green;"
echo.
pause
goto :CompressMenu

rem ========================================================
rem Switch Active Working Folder
rem ========================================================
:FolderSwitcherMenu
cls
echo ======================================================
echo             Switch Active Working Folder
echo ======================================================
echo Current Target: %CD%
echo.
echo You can organize, clean, or analyze any folder on your computer.
echo.
echo Select target folder:
echo.
echo  [1] Downloads Folder (Default: %USERPROFILE%\Downloads)
echo  [2] Desktop Folder   (%USERPROFILE%\Desktop)
echo  [3] Documents Folder (%USERPROFILE%\Documents)
echo  [4] Pictures Folder  (%USERPROFILE%\Pictures)
echo  [5] Videos Folder    (%USERPROFILE%\Videos)
echo  [6] Custom Path      (Enter any drive letter, folder, or USB)
echo.
echo  [0] Keep Current Folder
echo.
echo ======================================================
set "SW_CHOICE="
set /p "SW_CHOICE=Enter choice [0-6]: "

if "%SW_CHOICE%"=="" goto :FolderSwitcherMenu
if "%SW_CHOICE%"=="0" goto :MainMenu
if "%SW_CHOICE%"=="1" set "NEW_TARGET=%USERPROFILE%\Downloads" & goto :ApplyNewFolder
if "%SW_CHOICE%"=="2" set "NEW_TARGET=%USERPROFILE%\Desktop" & goto :ApplyNewFolder
if "%SW_CHOICE%"=="3" set "NEW_TARGET=%USERPROFILE%\Documents" & goto :ApplyNewFolder
if "%SW_CHOICE%"=="4" set "NEW_TARGET=%USERPROFILE%\Pictures" & goto :ApplyNewFolder
if "%SW_CHOICE%"=="5" set "NEW_TARGET=%USERPROFILE%\Videos" & goto :ApplyNewFolder
if "%SW_CHOICE%"=="6" goto :CustomFolderPrompt

echo.
echo [!] Invalid selection. Please choose an option from the menu.
echo.
pause
goto :FolderSwitcherMenu

:CustomFolderPrompt
echo.
set "CUSTOM_PATH="
set /p "CUSTOM_PATH=Enter full folder path (e.g. D:\Projects or E:\USB): "
if "%CUSTOM_PATH%"=="" goto :FolderSwitcherMenu
set "NEW_TARGET=%CUSTOM_PATH%"
goto :ApplyNewFolder

:ApplyNewFolder
if not exist "%NEW_TARGET%" (
    echo.
    echo [!] Folder does not exist: %NEW_TARGET%
    echo.
    pause
    goto :FolderSwitcherMenu
)
cd /d "%NEW_TARGET%"
set "TARGET_DIR=%CD%\"
set "RULES_FILE=%CD%\custom_rules.txt"
set "LOG_FILE=%CD%\organize_history.log"
set "TEMP_SIM=%CD%\preview_sim.tmp"
echo.
echo [V] Switched active folder to: %CD%
echo.
pause
goto :MainMenu

rem ========================================================
rem Custom Rules Submenu
rem ========================================================
:CustomRulesMenu
cls
if not exist "%RULES_FILE%" call :InitRulesFile

echo ======================================================
echo               Custom Folder Rules
echo ======================================================
echo Rules file: %RULES_FILE%
echo.
echo Active Saved Rules:
set "RULE_COUNT=0"
for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("%RULES_FILE%") do (
    call :PrintRule "%%A" "%%B"
)
if %RULE_COUNT% equ 0 echo   (No active custom rules saved yet)

echo.
echo Options:
echo   [1] Run organization using these custom rules
echo   [2] Add a new custom rule (Quick Add)
echo   [3] Open custom_rules.txt in Notepad to view/edit
echo   [4] Return to Main Menu
echo.
echo ======================================================
set "C_CHOICE="
set /p "C_CHOICE=Enter choice [1-4]: "

if "%C_CHOICE%"=="" goto :CustomRulesMenu
if "%C_CHOICE%"=="1" set "IS_PREVIEW=0" & set "CHOSEN_MODE=8" & goto :RunSelectedMode
if "%C_CHOICE%"=="2" goto :AddCustomRule
if "%C_CHOICE%"=="3" goto :EditRulesInNotepad
if "%C_CHOICE%"=="4" goto :MainMenu

echo.
echo [!] Invalid selection. Please enter 1, 2, 3, or 4.
echo.
pause
goto :CustomRulesMenu

:PrintRule
set /a RULE_COUNT+=1
echo   [%RULE_COUNT%] %~1  -^>  %~2
goto :eof

:InitRulesFile
(
echo # ========================================================
echo # Downloads Organizer - Custom Rules File
echo # ========================================================
echo # Format: Extension=TargetFolder
echo # Lines starting with # are comments and will be ignored.
echo # You can use a leading dot or leave it out ^(.psd or psd^).
echo #
echo # Examples:
echo # .torrent=Torrents
echo # .blend=Blender Projects
echo # .mkv=Movies
echo # .psd=Photoshop
echo # .epub=Books
echo # ========================================================
) > "%RULES_FILE%"
goto :eof

:AddCustomRule
echo.
echo ------------------------------------------------------
echo                 Add New Custom Rule
echo ------------------------------------------------------
set "IN_EXT="
set /p "IN_EXT=Enter file extension (e.g. .torrent or blend): "
if "%IN_EXT%"=="" echo [!] Extension cannot be empty. & pause & goto :CustomRulesMenu

set "IN_DIR="
set /p "IN_DIR=Enter target folder name (e.g. Torrents): "
if "%IN_DIR%"=="" echo [!] Folder name cannot be empty. & pause & goto :CustomRulesMenu

if not "%IN_EXT:~0,1%"=="." set "IN_EXT=.%IN_EXT%"

echo %IN_EXT%=%IN_DIR%>> "%RULES_FILE%"
echo.
echo [+] Successfully saved rule: %IN_EXT% -^> %IN_DIR%
echo.
pause
goto :CustomRulesMenu

:EditRulesInNotepad
start notepad "%RULES_FILE%"
echo.
echo [*] Opened custom_rules.txt in Notepad.
echo     Make your changes, save the file (Ctrl+S), and close Notepad.
echo.
pause
goto :CustomRulesMenu

:ExecuteCustomRule
set "EXT_PAT=%~1"
set "T_DIR=%~2"
if not "%EXT_PAT:~0,1%"=="." set "EXT_PAT=.%EXT_PAT%"

for %%F in (*%EXT_PAT%) do (
    if exist "%%F" (
        if /i not "%%~nxF"=="%SELF%" if /i not "%%~nxF"=="organize_history.log" if /i not "%%~nxF"=="custom_rules.txt" if /i not "%%~nxF"=="preview_sim.tmp" (
            call :MoveFile "%%F" "%T_DIR%"
        )
    )
)
goto :eof

rem ========================================================
rem Category Runner (Includes full filesamples.com catalog)
rem ========================================================
:ProcessAllCategories
set "HANDLER=%~1"

rem Images
call %HANDLER% "Images" .jpg .jpeg .png .gif .bmp .webp .svg .ico .cur .tiff .tif .jfif .jp2 .jpe .jps .mng .wbmp .avif .apng .xmp
call %HANDLER% "Images" .cr2 .cr3 .crw .nef .nrw .arw .srf .sr2 .orf .rw2 .pef .raf .dng .raw .x3f .erf .kdc .dcr .mrw .mos
call %HANDLER% "Images" .exr .hdr .dds .tga .sgi .ras .pict .pct .pnm .pbm .pgm .ppm .pam .pfm
call %HANDLER% "Images" .psd .psb .ai .eps .xcf .cdr .sketch .figma .indd .pes .wpg .xpm .xbm .xwd .pcd .pcx .fts .picon .sfw
call %HANDLER% "Images" .heic .heif .hif

rem EXEs & Installers
call %HANDLER% "EXEs" .exe .msi .msix .appx .appxbundle .bat .cmd .com .scr .vbs .vbe .wsf .wsh .pif .gadget .apk .apks .xapk .aab .ipa .deb .rpm .pkg .jar .war .ear

rem Documents, Office & eBooks
call %HANDLER% "Documents" .pdf .doc .docx .docm .dot .dotx .dotm .odt .ott .rtf .txt .tex .wpd .wps
call %HANDLER% "Documents" .xls .xlsx .xlsm .xlsb .xlt .xltx .csv .tsv .ods .ots
call %HANDLER% "Documents" .ppt .pptx .pptm .pot .potx .pps .ppsx .odp .otp
call %HANDLER% "Documents" .epub .mobi .azw .azw3 .fb2 .ibooks .cbr .cbz .lrf .pdb .snb .djvu .md .markdown

rem Video & Animations
call %HANDLER% "Video" .mp4 .m4v .mkv .webm .mov .avi .wmv .flv .f4v .ts .m2ts .mts .m2v .mpg .mpeg .vob .mxf .mjpeg .ogv .3gp .3g2 .asf .rm .rmvb .wtv .divx .xvid .swf .hevc .h264 .h265 .av1

rem Audio & Voice
call %HANDLER% "Audio" .mp3 .aac .m4a .m4r .ogg .oga .opus .wma .flac .alac .wav .aiff .aif .aifc .w64 .wv .ape .tta .dts .ac3
call %HANDLER% "Audio" .mid .midi .mod .s3m .xm .it .kar
call %HANDLER% "Audio" .amr .voc .vox .ra .spx .au .snd .sndr .sndt .sou .sph .8svx .amb .avr .caf .cdda .cvs .cvsd .cvu .dvms .fap .fssd .gsrt .hcom .htk .ima .ircam .maud .mp2 .nist .paf .prc .pvf .sd2 .sln .smp .txw .vms .wve

rem Archives & Disk Images
call %HANDLER% "Archives" .zip .zipx .rar .7z .tar .gz .gzip .bz2 .bzip2 .xz .tgz .tbz2 .txz .z .lz .lzma .lzo .zst .cab .arj .cpio .wim
call %HANDLER% "Archives" .iso .img .dmg .bin .cue .nrg .mdf .vhd .vhdx .vmdk .qcow2 .ova .ovf .toast

rem Code, Scripts, Databases & Configs
call %HANDLER% "Code" .py .pyw .ipynb .java .class .c .cpp .cc .cxx .h .hpp .hxx .cs .go .rs .rb .php .swift .kt .kts .m .mm .pl .pm .r .dart .lua .scala
call %HANDLER% "Code" .html .htm .xhtml .css .scss .sass .less .js .jsx .mjs .cjs .ts .tsx
call %HANDLER% "Code" .json .jsonc .json5 .xml .yaml .yml .toml .ini .env .conf .cfg .config .properties .plist .reg .kml .gpx .bson .ct .htaccess
call %HANDLER% "Code" .sql .sqlite .sqlite3 .db .db3 .mdb .accdb .sh .bash .zsh .ps1 .psm1 .psd1 .patch .diff .vb .vba

rem Fonts
call %HANDLER% "Fonts" .ttf .otf .woff .woff2 .eot .fon .fnt .dfont .cff .pfb .pfa .afm .sfd .ps

rem 3D Models & CAD
call %HANDLER% "3D Models" .obj .fbx .stl .dae .3ds .blend .blend1 .gltf .glb .step .stp .iges .igs .dwg .dxf .skp

rem Shortcuts
call %HANDLER% "Shortcuts" .lnk .url .webloc .desktop
goto :eof

rem ========================================================
rem Handler Implementations
rem ========================================================

rem --- Mode 1: Standard Category ---
:CategoryStandard
set "CAT_NAME=%~1"
for %%E in (%*) do (
    if not "%%~E"=="%~1" (
        for %%F in (*%%~E) do (
            if exist "%%F" (
                if /i not "%%~nxF"=="%SELF%" if /i not "%%~nxF"=="organize_history.log" if /i not "%%~nxF"=="custom_rules.txt" if /i not "%%~nxF"=="preview_sim.tmp" (
                    call :MoveFile "%%F" "%CAT_NAME%"
                )
            )
        )
    )
)
goto :eof

:MoveOthersStandard
set "CAT_NAME=%~1"
for %%F in (*) do (
    if exist "%%F" (
        if /i not "%%~nxF"=="%SELF%" if /i not "%%~nxF"=="organize_history.log" if /i not "%%~nxF"=="custom_rules.txt" if /i not "%%~nxF"=="preview_sim.tmp" (
            call :MoveOtherStandardHelper "%%F" "%CAT_NAME%"
        )
    )
)
goto :eof

:MoveOtherStandardHelper
if "%IS_PREVIEW%"=="1" (
    if exist "%TEMP_SIM%" (
        findstr /x /i /c:"%~nx1" "%TEMP_SIM%" >nul 2>&1
        if not errorlevel 1 goto :eof
    )
)
call :MoveFile "%~1" "%~2"
goto :eof

rem --- Mode 2: Deep Category (Category + Sub-Extension) ---
:CategoryDeep
set "CAT_NAME=%~1"
for %%E in (%*) do (
    if not "%%~E"=="%~1" (
        for %%F in (*%%~E) do (
            if exist "%%F" (
                if /i not "%%~nxF"=="%SELF%" if /i not "%%~nxF"=="organize_history.log" if /i not "%%~nxF"=="custom_rules.txt" if /i not "%%~nxF"=="preview_sim.tmp" (
                    call :DeepMoveHelper "%%F" "%CAT_NAME%" "%%~E"
                )
            )
        )
    )
)
goto :eof

:DeepMoveHelper
call :SetCleanExt "%~3"
call :MoveFile "%~1" "%~2\%CLEAN_EXT%"
goto :eof

:MoveOthersDeep
set "CAT_NAME=%~1"
for %%F in (*) do (
    if exist "%%F" (
        if /i not "%%~nxF"=="%SELF%" if /i not "%%~nxF"=="organize_history.log" if /i not "%%~nxF"=="custom_rules.txt" if /i not "%%~nxF"=="preview_sim.tmp" (
            call :MoveOtherDeepHelper "%%F" "%CAT_NAME%"
        )
    )
)
goto :eof

:MoveOtherDeepHelper
if "%IS_PREVIEW%"=="1" (
    if exist "%TEMP_SIM%" (
        findstr /x /i /c:"%~nx1" "%TEMP_SIM%" >nul 2>&1
        if not errorlevel 1 goto :eof
    )
)
call :SetCleanExt "%~x1"
call :MoveFile "%~1" "%~2\%CLEAN_EXT%"
goto :eof

rem --- Mode 3: Direct Extension ---
:ProcessExtension
set "F_EXT=%~x1"
if "%F_EXT%"=="" (
    call :MoveFile "%~1" "No_Extension"
    goto :eof
)
call :SetCleanExt "%F_EXT%"
call :MoveFile "%~1" "%CLEAN_EXT%"
goto :eof

rem --- Mode 4: By Date (Year & Month) ---
:ProcessDate
call :GetDateFolder "%~1"
call :MoveFile "%~1" "%DATE_FOLDER%"
goto :eof

rem --- Mode 5: Hybrid (Category + Year-Month) ---
:CategoryHybrid
set "CAT_NAME=%~1"
for %%E in (%*) do (
    if not "%%~E"=="%~1" (
        for %%F in (*%%~E) do (
            if exist "%%F" (
                if /i not "%%~nxF"=="%SELF%" if /i not "%%~nxF"=="organize_history.log" if /i not "%%~nxF"=="custom_rules.txt" if /i not "%%~nxF"=="preview_sim.tmp" (
                    call :HybridMoveHelper "%%F" "%CAT_NAME%"
                )
            )
        )
    )
)
goto :eof

:HybridMoveHelper
call :GetDateShort "%~1"
call :MoveFile "%~1" "%~2\%DATE_SHORT%"
goto :eof

:MoveOthersHybrid
set "CAT_NAME=%~1"
for %%F in (*) do (
    if exist "%%F" (
        if /i not "%%~nxF"=="%SELF%" if /i not "%%~nxF"=="organize_history.log" if /i not "%%~nxF"=="custom_rules.txt" if /i not "%%~nxF"=="preview_sim.tmp" (
            call :MoveOtherHybridHelper "%%F" "%CAT_NAME%"
        )
    )
)
goto :eof

:MoveOtherHybridHelper
if "%IS_PREVIEW%"=="1" (
    if exist "%TEMP_SIM%" (
        findstr /x /i /c:"%~nx1" "%TEMP_SIM%" >nul 2>&1
        if not errorlevel 1 goto :eof
    )
)
call :GetDateShort "%~1"
call :MoveFile "%~1" "%~2\%DATE_SHORT%"
goto :eof

rem --- Mode 6: File Size Triage ---
:ProcessSize
call :GetSizeFolder "%~1"
call :MoveFile "%~1" "%SIZE_FOLDER%"
goto :eof

rem --- Mode 7: Alphabetical ---
:ProcessAlpha
call :GetAlphaFolder "%~1"
call :MoveFile "%~1" "%ALPHA_FOLDER%"
goto :eof

rem ========================================================
rem Utility Subroutines
rem ========================================================

:SetCleanExt
set "RAW_EXT=%~1"
if "%RAW_EXT%"=="" set "CLEAN_EXT=No_Extension" & goto :eof
set "CLEAN_EXT=%RAW_EXT:~1%"
for %%U in (
    "png=PNG" "jpg=JPG" "jpeg=JPEG" "gif=GIF" "webp=WEBP" "svg=SVG" "bmp=BMP" "ico=ICO" "tiff=TIFF" "heic=HEIC"
    "pdf=PDF" "doc=DOC" "docx=DOCX" "xls=XLS" "xlsx=XLSX" "ppt=PPT" "pptx=PPTX" "txt=TXT" "csv=CSV" "md=MD" "epub=EPUB"
    "zip=ZIP" "rar=RAR" "7z=7Z" "tar=TAR" "gz=GZ" "iso=ISO" "dmg=DMG"
    "mp3=MP3" "wav=WAV" "flac=FLAC" "m4a=M4A" "ogg=OGG" "aac=AAC"
    "mp4=MP4" "mkv=MKV" "avi=AVI" "mov=MOV" "wmv=WMV" "webm=WEBM"
    "exe=EXE" "msi=MSI" "bat=BAT" "cmd=CMD" "apk=APK" "jar=JAR"
    "py=PY" "js=JS" "ts=TS" "html=HTML" "css=CSS" "json=JSON" "sql=SQL" "xml=XML" "sh=SH" "yaml=YAML"
    "obj=OBJ" "fbx=FBX" "stl=STL" "blend=BLEND" "dwg=DWG"
    "ttf=TTF" "otf=OTF" "woff=WOFF" "woff2=WOFF2"
    "lnk=LNK" "url=URL"
) do (
    for /f "tokens=1,2 delims==" %%X in (%%U) do (
        if /i "%CLEAN_EXT%"=="%%X" set "CLEAN_EXT=%%Y" & goto :eof
    )
)
goto :eof

:GetDateFolder
set "FTIME=%~t1"
for /f "tokens=1-3 delims=/-. " %%A in ("%FTIME%") do (
    set "T1=%%A"
    set "T2=%%B"
    set "T3=%%C"
)
set "YEAR=%T3%"
set "MONTH=%T2%"
if "%T1:~3,1%" neq "" (
    set "YEAR=%T1%"
    set "MONTH=%T2%"
)
set "MNAME=Month-%MONTH%"
if "%MONTH%"=="01" set "MNAME=01 - January"
if "%MONTH%"=="02" set "MNAME=02 - February"
if "%MONTH%"=="03" set "MNAME=03 - March"
if "%MONTH%"=="04" set "MNAME=04 - April"
if "%MONTH%"=="05" set "MNAME=05 - May"
if "%MONTH%"=="06" set "MNAME=06 - June"
if "%MONTH%"=="07" set "MNAME=07 - July"
if "%MONTH%"=="08" set "MNAME=08 - August"
if "%MONTH%"=="09" set "MNAME=09 - September"
if "%MONTH%"=="10" set "MNAME=10 - October"
if "%MONTH%"=="11" set "MNAME=11 - November"
if "%MONTH%"=="12" set "MNAME=12 - December"
if "%MONTH%"=="1" set "MNAME=01 - January"
if "%MONTH%"=="2" set "MNAME=02 - February"
if "%MONTH%"=="3" set "MNAME=03 - March"
if "%MONTH%"=="4" set "MNAME=04 - April"
if "%MONTH%"=="5" set "MNAME=05 - May"
if "%MONTH%"=="6" set "MNAME=06 - June"
if "%MONTH%"=="7" set "MNAME=07 - July"
if "%MONTH%"=="8" set "MNAME=08 - August"
if "%MONTH%"=="9" set "MNAME=09 - September"
set "DATE_FOLDER=%YEAR%\%MNAME%"
goto :eof

:GetDateShort
set "FTIME=%~t1"
for /f "tokens=1-3 delims=/-. " %%A in ("%FTIME%") do (
    set "T1=%%A"
    set "T2=%%B"
    set "T3=%%C"
)
set "YEAR=%T3%"
set "MONTH=%T2%"
if "%T1:~3,1%" neq "" (
    set "YEAR=%T1%"
    set "MONTH=%T2%"
)
set "DATE_SHORT=%YEAR%-%MONTH%"
goto :eof

:GetSizeFolder
set "BYTES=%~z1"
set "LEN=0"
set "S_VAL=%BYTES%"
:len_loop
if defined S_VAL (
    set "S_VAL=%S_VAL:~1%"
    set /a LEN+=1
    goto :len_loop
)
if %LEN% geq 10 set "SIZE_FOLDER=Gigabytes (Above 1 GB)" & goto :eof
if %LEN% equ 9 set "SIZE_FOLDER=Large (100 MB - 1 GB)" & goto :eof
if %LEN% equ 8 set "SIZE_FOLDER=Medium (10 MB - 100 MB)" & goto :eof
if %LEN% equ 7 set "SIZE_FOLDER=Small (1 MB - 10 MB)" & goto :eof
set "SIZE_FOLDER=Tiny (Under 1 MB)"
goto :eof

:GetAlphaFolder
set "BNAME=%~n1"
set "CH=%BNAME:~0,1%"
set "ALPHA_FOLDER=0-9 and Symbols"
for %%L in (A B C D a b c d) do if "%CH%"=="%%L" set "ALPHA_FOLDER=A - D" & goto :eof
for %%L in (E F G H e f g h) do if "%CH%"=="%%L" set "ALPHA_FOLDER=E - H" & goto :eof
for %%L in (I J K L i j k l) do if "%CH%"=="%%L" set "ALPHA_FOLDER=I - L" & goto :eof
for %%L in (M N O P m n o p) do if "%CH%"=="%%L" set "ALPHA_FOLDER=M - P" & goto :eof
for %%L in (Q R S T q r s t) do if "%CH%"=="%%L" set "ALPHA_FOLDER=Q - T" & goto :eof
for %%L in (U V W X Y Z u v w x y z) do if "%CH%"=="%%L" set "ALPHA_FOLDER=U - Z" & goto :eof
goto :eof

rem ========================================================
rem Safe File Moving Routine (With Simulation Support)
rem ========================================================
:MoveFile
set "SRC=%~1"
set "DEST_DIR=%~2"
set "FNAME=%~nx1"
set "BASE_NAME=%~n1"
set "EXT_NAME=%~x1"

if /i "%FNAME%"=="Organize_Downloads_Windows.bat" goto :eof
if /i "%FNAME%"=="Organize_Downloads.bat" goto :eof
if /i "%FNAME%"=="Organize_Downloads_macOS.command" goto :eof
if /i "%FNAME%"=="Organize_Downloads_Linux.sh" goto :eof
if /i "%FNAME%"=="README.md" goto :eof
if /i "%FNAME%"==".gitignore" goto :eof
if /i "%FNAME%"=="organize_history.log" goto :eof
if /i "%FNAME%"=="custom_rules.txt" goto :eof
if /i "%FNAME%"=="preview_sim.tmp" goto :eof

if "%IS_PREVIEW%"=="1" goto :MoveFilePreview

if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

if exist "%DEST_DIR%\%FNAME%" goto :HandleDup
move "%SRC%" "%DEST_DIR%\" >nul
echo %DEST_DIR%\%FNAME%^|%SRC%>> "%LOG_FILE%"
echo  [+] Moved: %FNAME% -^> %DEST_DIR%\
set /a MOVED_COUNT+=1
goto :eof

:HandleDup
set /a dup_idx=1
:dup_loop
set "NEW_FNAME=%BASE_NAME% (%dup_idx%)%EXT_NAME%"
if exist "%DEST_DIR%\%NEW_FNAME%" set /a dup_idx+=1 & goto :dup_loop
move "%SRC%" "%DEST_DIR%\%NEW_FNAME%" >nul
echo %DEST_DIR%\%NEW_FNAME%^|%SRC%>> "%LOG_FILE%"
echo  [+] Moved (renamed duplicate): %FNAME% -^> %DEST_DIR%\%NEW_FNAME%
set /a MOVED_COUNT+=1
goto :eof

:MoveFilePreview
echo %FNAME%>> "%TEMP_SIM%"
echo  [PREVIEW] %FNAME% -^> %DEST_DIR%\
set /a MOVED_COUNT+=1
goto :eof
