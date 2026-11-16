#!/usr/bin/env bash
# ==============================================================================
# Files Organizer (macOS Edition)
# Double-clickable .command script for macOS Finder / Terminal.
# 8 Organization Modes, Duplicate Cleaner (SHA-256), Junk Cleaner, Storage
# Analytics, Undo History, and Safe Collision Protection.
# ==============================================================================

# Ensure script runs from its directory
cd "$(cd "$(dirname "$0")" && pwd)" || exit 1

SELF="$(basename "$0")"
TARGET_DIR="$(pwd)"
RULES_FILE="$TARGET_DIR/custom_rules.txt"
LOG_FILE="$TARGET_DIR/organize_history.log"
TEMP_SIM="$TARGET_DIR/preview_sim.tmp"
IS_PREVIEW=0
IS_SILENT=0
CHOSEN_MODE=""
MOVED_COUNT=0

# Check if first argument is a folder path
if [ -n "$1" ] && [ -d "$1" ]; then
    cd "$1" || exit 1
    TARGET_DIR="$(pwd)"
    RULES_FILE="$TARGET_DIR/custom_rules.txt"
    LOG_FILE="$TARGET_DIR/organize_history.log"
    TEMP_SIM="$TARGET_DIR/preview_sim.tmp"
    shift
fi

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --silent|-silent|/silent|--auto|-auto|/auto)
            IS_SILENT=1
            ;;
        --mode|-mode|/mode)
            CHOSEN_MODE="$2"
            shift
            ;;
        --preview|-preview|/preview)
            IS_PREVIEW=1
            ;;
        --undo|-undo|/undo)
            DO_UNDO=1
            ;;
        --junk|-junk|/junk)
            DO_JUNK=1
            ;;
        --duplicates|-duplicates|/duplicates)
            DO_DUPS=1
            ;;
    esac
    shift
done

# Terminal colors
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

# Files excluded from being moved
is_excluded() {
    local fn
    fn="$(basename "$1")"
    case "$fn" in
        Organize_Downloads_Windows.bat|\
        Organize_Downloads_macOS.command|\
        Organize_Downloads_Linux.sh|\
        Organize_Downloads.bat|\
        organize_history.log|\
        custom_rules.txt|\
        preview_sim.tmp|\
        README.md|\
        .gitignore|\
        .DS_Store|\
        .localized)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Format bytes to human readable
format_bytes() {
    local b="$1"
    if [ "$b" -lt 1024 ]; then
        echo "${b} B"
    elif [ "$b" -lt 1048576 ]; then
        echo "$(( (b + 512) / 1024 )) KB"
    elif [ "$b" -lt 1073741824 ]; then
        echo "$(( (b + 524288) / 1048576 )) MB"
    else
        echo "$(( (b + 536870912) / 1073741824 )) GB"
    fi
}

# Collision-safe move: renames duplicate destination to "name (1).ext"
safe_move() {
    local src="$1"
    local dest_dir="$2"
    local fname
    fname="$(basename "$src")"

    if is_excluded "$src"; then
        return
    fi

    if [ "$IS_PREVIEW" -eq 1 ]; then
        echo "$fname" >> "$TEMP_SIM"
        echo -e " ${CYAN}[PREVIEW]${RESET} $fname -> ${BOLD}$dest_dir/${RESET}"
        ((MOVED_COUNT++))
        return
    fi

    mkdir -p "$dest_dir"

    local base="${fname%.*}"
    local ext="${fname##*.}"
    if [ "$base" = "$fname" ]; then
        ext=""
    else
        ext=".$ext"
    fi

    local target="$dest_dir/$fname"
    if [ -e "$target" ]; then
        local idx=1
        while [ -e "$dest_dir/$base ($idx)$ext" ]; do
            ((idx++))
        done
        target="$dest_dir/$base ($idx)$ext"
        mv "$src" "$target"
        echo "$target|$src" >> "$LOG_FILE"
        echo -e " ${YELLOW}[+] Moved (renamed duplicate):${RESET} $fname -> ${BOLD}$(basename "$target")${RESET}"
    else
        mv "$src" "$target"
        echo "$target|$src" >> "$LOG_FILE"
        echo -e " ${GREEN}[+] Moved:${RESET} $fname -> ${BOLD}$dest_dir/${RESET}"
    fi
    ((MOVED_COUNT++))
}

# ------------------------------------------------------------------------------
# Category Definitions
# ------------------------------------------------------------------------------
classify_and_move() {
    local file="$1"
    local mode="$2"
    local fname
    fname="$(basename "$file")"

    if is_excluded "$file" || [ ! -f "$file" ]; then
        return
    fi

    local ext
    ext="${fname##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
    if [ "$fname" = "$ext" ]; then
        ext=""
    fi

    local cat="Others"
    case "$ext" in
        jpg|jpeg|png|gif|bmp|webp|svg|ico|cur|tiff|tif|jfif|heic|heif|avif|raw|cr2|cr3|nef|arw|dng|psd|ai|eps|xcf)
            cat="Images"
            ;;
        pdf|doc|docx|docm|dot|dotx|odt|rtf|txt|tex|wpd|xls|xlsx|xlsm|csv|tsv|ods|ppt|pptx|odp|epub|mobi|azw3|cbr|cbz|djvu|md|markdown)
            cat="Documents"
            ;;
        mp4|m4v|mkv|webm|mov|avi|wmv|flv|ts|m2ts|mts|mpg|mpeg|vob|mxf|ogv|3gp|divx|xvid|hevc)
            cat="Video"
            ;;
        mp3|aac|m4a|m4r|ogg|oga|opus|wma|flac|alac|wav|aiff|aif|mid|midi|amr|vox|ac3|dts)
            cat="Audio"
            ;;
        zip|zipx|rar|7z|tar|gz|gzip|bz2|bzip2|xz|tgz|zst|cab|dmg|iso|img|bin|pkg|vhd|ova|ovf)
            cat="Archives"
            ;;
        dmg|pkg|app|appx|deb|rpm|exe|msi|bin|sh|command)
            cat="Installers"
            ;;
        py|ipynb|java|class|c|cpp|h|hpp|cs|go|rs|rb|php|swift|kt|kts|m|mm|pl|r|dart|lua|scala|html|htm|css|scss|js|jsx|ts|tsx|json|xml|yaml|yml|toml|ini|env|sql|sqlite|sh|bash|zsh)
            cat="Code"
            ;;
        ttf|otf|woff|woff2|eot|fon|dfont)
            cat="Fonts"
            ;;
        obj|fbx|stl|dae|3ds|blend|gltf|glb|step|stp|dwg|dxf)
            cat="3D Models"
            ;;
        webloc|url|desktop|alias)
            cat="Shortcuts"
            ;;
        *)
            cat="Others"
            ;;
    esac

    # Determine destination folder according to mode
    local dest_dir=""
    case "$mode" in
        1) # Standard
            dest_dir="$cat"
            ;;
        2) # Deep
            local uext
            uext="$(echo "$ext" | tr '[:lower:]' '[:upper:]')"
            [ -z "$uext" ] && uext="NO_EXT"
            dest_dir="$cat/$uext"
            ;;
        3) # Flat Extension
            local uext
            uext="$(echo "$ext" | tr '[:lower:]' '[:upper:]')"
            [ -z "$uext" ] && uext="NO_EXT"
            dest_dir="$uext"
            ;;
        4) # Date Modified (macOS stat)
            local mod_year mod_month
            mod_year="$(stat -f "%Sm" -t "%Y" "$file" 2>/dev/null || date +"%Y")"
            mod_month="$(stat -f "%Sm" -t "%m - %B" "$file" 2>/dev/null || date +"%m - %B")"
            dest_dir="$mod_year/$mod_month"
            ;;
        5) # Hybrid (Category + Year-Month)
            local mod_ym
            mod_ym="$(stat -f "%Sm" -t "%Y-%m" "$file" 2>/dev/null || date +"%Y-%m")"
            dest_dir="$cat/$mod_ym"
            ;;
        6) # File Size Triage
            local fsize
            fsize="$(stat -f "%z" "$file" 2>/dev/null || echo 0)"
            if [ "$fsize" -ge 1073741824 ]; then
                dest_dir="Gigabytes (Above 1 GB)"
            elif [ "$fsize" -ge 104857600 ]; then
                dest_dir="Large (100 MB - 1 GB)"
            elif [ "$fsize" -ge 10485760 ]; then
                dest_dir="Medium (10 MB - 100 MB)"
            elif [ "$fsize" -ge 1048576 ]; then
                dest_dir="Small (1 MB - 10 MB)"
            else
                dest_dir="Tiny (Under 1 MB)"
            fi
            ;;
        7) # Alphabetical
            local first_char
            first_char="$(echo "${fname:0:1}" | tr '[:lower:]' '[:upper:]')"
            case "$first_char" in
                [ABCD]) dest_dir="A - D" ;;
                [EFGH]) dest_dir="E - H" ;;
                [IJKL]) dest_dir="I - L" ;;
                [MNOP]) dest_dir="M - P" ;;
                [QRST]) dest_dir="Q - T" ;;
                [UVWXYZ]) dest_dir="U - Z" ;;
                *) dest_dir="0-9 and Symbols" ;;
            esac
            ;;
        8) # Custom Rules
            local matched=0
            if [ -f "$RULES_FILE" ]; then
                while IFS= read -r line || [ -n "$line" ]; do
                    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
                    [[ -z "$line" || "$line" =~ ^# ]] && continue
                    if [[ "$line" == *:* ]]; then
                        local folder_name="${line%%:*}"
                        folder_name="$(echo "$folder_name" | sed 's/[[:space:]]*$//')"
                        local triggers="${line#*:}"
                        IFS=',' read -ra TRIG_ARR <<< "$triggers"
                        for trig in "${TRIG_ARR[@]}"; do
                            trig="$(echo "$trig" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')"
                            [ -z "$trig" ] && continue
                            if [[ "$trig" == .* ]]; then
                                local clean_trig="${trig#.}"
                                if [ "$ext" = "$clean_trig" ]; then
                                    dest_dir="$folder_name"
                                    matched=1
                                    break 2
                                fi
                            else
                                local lower_fname
                                lower_fname="$(echo "$fname" | tr '[:upper:]' '[:lower:]')"
                                if [[ "$lower_fname" == *"$trig"* ]]; then
                                    dest_dir="$folder_name"
                                    matched=1
                                    break 2
                                fi
                            fi
                        done
                    fi
                done < "$RULES_FILE"
            fi
            [ "$matched" -eq 0 ] && dest_dir="$cat"
            ;;
    esac

    safe_move "$file" "$dest_dir"
}

run_organization() {
    local mode="$1"
    MOVED_COUNT=0
    rm -f "$TEMP_SIM" 2>/dev/null

    echo
    echo -e "${CYAN}[*] Processing files in:${RESET} ${BOLD}$TARGET_DIR${RESET}"
    echo

    for f in "$TARGET_DIR"/*; do
        if [ -f "$f" ]; then
            classify_and_move "$f" "$mode"
        fi
    done

    echo
    echo -e "${BOLD}======================================================${RESET}"
    if [ "$IS_PREVIEW" -eq 1 ]; then
        echo -e "${YELLOW}Simulation Finished:${RESET} $MOVED_COUNT file(s) would be organized."
        echo "No files were moved. Run without preview to apply changes."
    else
        echo -e "${GREEN}Organization Complete:${RESET} Successfully organized $MOVED_COUNT file(s)."
        echo -e "History saved to: ${BOLD}organize_history.log${RESET} (Use Undo [U] to revert)."
    fi
    echo -e "${BOLD}======================================================${RESET}"
    echo
}

# ------------------------------------------------------------------------------
# Housekeeping Tools
# ------------------------------------------------------------------------------
run_undo() {
    clear
    echo -e "${BOLD}======================================================${RESET}"
    echo -e "${CYAN}             Undo Last Organization${RESET}"
    echo -e "${BOLD}======================================================${RESET}"

    if [ ! -f "$LOG_FILE" ]; then
        echo
        echo -e "${YELLOW}[!] No organize_history.log found.${RESET} Nothing to undo."
        echo
        return
    fi

    local count
    count="$(wc -l < "$LOG_FILE" | tr -d ' ')"
    if [ "$count" -eq 0 ]; then
        echo
        echo -e "${YELLOW}[!] The history log is empty.${RESET}"
        echo
        return
    fi

    echo
    echo -e "Found ${BOLD}$count${RESET} file(s) moved during the last session."
    echo
    read -r -p "Restore these files back to root directory? [Y/N]: " confirm
    confirm="$(echo "$confirm" | tr -d '\r')"
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n${YELLOW}[*] Undo cancelled.${RESET}\n"
        return
    fi

    echo
    echo -e "${CYAN}[*] Restoring files...${RESET}"
    local restored=0

    # Read log backwards (FILO)
    while IFS='|' read -r curr orig || [ -n "$curr" ]; do
        [ -z "$curr" ] && continue
        if [ -f "$curr" ]; then
            mkdir -p "$(dirname "$orig")"
            if [ -e "$orig" ]; then
                local base="${orig%.*}"
                local ext="${orig##*.}"
                [ "$base" = "$orig" ] && ext="" || ext=".$ext"
                local idx=1
                while [ -e "$base ($idx)$ext" ]; do ((idx++)); done
                mv "$curr" "$base ($idx)$ext"
                echo -e " ${YELLOW}[-] Restored (duplicate):${RESET} $(basename "$curr") -> $(basename "$base ($idx)$ext")"
            else
                mv "$curr" "$orig"
                echo -e " ${GREEN}[-] Restored:${RESET} $(basename "$curr") -> $orig"
            fi
            ((restored++))

            # Prune empty parent folder
            local pdir
            pdir="$(dirname "$curr")"
            while [ "$pdir" != "$TARGET_DIR" ] && [ "$pdir" != "/" ]; do
                if [ -d "$pdir" ] && [ -z "$(ls -A "$pdir")" ]; then
                    rmdir "$pdir" 2>/dev/null
                    pdir="$(dirname "$pdir")"
                else
                    break
                fi
            done
        fi
    done < <(tail -r "$LOG_FILE" 2>/dev/null || tac "$LOG_FILE" 2>/dev/null || cat "$LOG_FILE")

    rm -f "$LOG_FILE" 2>/dev/null
    echo
    echo -e "${BOLD}======================================================${RESET}"
    echo -e "${GREEN}Status: Restored $restored file(s) successfully.${RESET}"
    echo -e "${BOLD}======================================================${RESET}"
    echo
}

run_junk_cleaner() {
    clear
    echo -e "${BOLD}======================================================${RESET}"
    echo -e "${CYAN}         Junk & Broken Downloads Cleaner${RESET}"
    echo -e "${BOLD}======================================================${RESET}"
    echo

    local junk_files=()
    for f in "$TARGET_DIR"/*; do
        if [ -f "$f" ]; then
            local fname
            fname="$(basename "$f")"
            if is_excluded "$f"; then continue; fi
            local fsize
            fsize="$(stat -f "%z" "$f" 2>/dev/null || echo 1)"
            if [[ "$fname" =~ \.(crdownload|part|tmp|download)$ ]] || [ "$fsize" -eq 0 ]; then
                junk_files+=("$f")
            fi
        fi
    done

    if [ "${#junk_files[@]}" -eq 0 ]; then
        echo -e "${GREEN}[✓] No junk or 0-byte ghost files found!${RESET}\n"
        return
    fi

    echo -e "Found ${BOLD}${#junk_files[@]}${RESET} junk file(s):"
    for j in "${junk_files[@]}"; do
        local sz
        sz="$(stat -f "%z" "$j" 2>/dev/null || echo 0)"
        echo -e "  • $(basename "$j") ($(format_bytes "$sz"))"
    done
    echo
    echo " [1] Quarantine into 'Junk_Temp/' (Recommended)"
    echo " [2] Permanently Delete"
    echo " [0] Cancel"
    echo
    read -r -p "Enter choice [0-2]: " jchoice
    jchoice="$(echo "$jchoice" | tr -d '\r')"

    case "$jchoice" in
        1)
            mkdir -p "$TARGET_DIR/Junk_Temp"
            for j in "${junk_files[@]}"; do
                mv "$j" "$TARGET_DIR/Junk_Temp/"
            done
            echo -e "\n${GREEN}[✓] Moved ${#junk_files[@]} file(s) into 'Junk_Temp/'.${RESET}\n"
            ;;
        2)
            for j in "${junk_files[@]}"; do
                rm -f "$j"
            done
            echo -e "\n${RED}[✓] Deleted ${#junk_files[@]} file(s) permanently.${RESET}\n"
            ;;
        *)
            echo -e "\n${YELLOW}[*] Cancelled.${RESET}\n"
            ;;
    esac
}

run_duplicates_finder() {
    clear
    echo -e "${BOLD}======================================================${RESET}"
    echo -e "${CYAN}          Duplicate Cleaner & Staging Manager${RESET}"
    echo -e "${BOLD}======================================================${RESET}"
    echo
    echo " [1] Scan & Isolate Browser Duplicates (*(1), *-Copy)"
    echo " [2] Scan & Isolate Exact Bit-for-Bit Duplicates (SHA-256)"
    echo " [0] Back to Main Menu"
    echo
    read -r -p "Enter choice [0-2]: " dchoice
    dchoice="$(echo "$dchoice" | tr -d '\r')"

    case "$dchoice" in
        1)
            local dups=()
            for f in "$TARGET_DIR"/*; do
                if [ -f "$f" ]; then
                    local fn
                    fn="$(basename "$f")"
                    if is_excluded "$f"; then continue; fi
                    if [[ "$fn" =~ [[:space:]]*\([0-9]+\)\.[^.]+$ || "$fn" =~ [[:space:]]*-[[:space:]]*Copy\.[^.]+$ ]]; then
                        dups+=("$f")
                    fi
                fi
            done
            if [ "${#dups[@]}" -eq 0 ]; then
                echo -e "\n${GREEN}[✓] No browser duplicate files found.${RESET}\n"
            else
                mkdir -p "$TARGET_DIR/Duplicates"
                for d in "${dups[@]}"; do
                    mv "$d" "$TARGET_DIR/Duplicates/"
                    echo -e " ${YELLOW}[+] Isolated:${RESET} $(basename "$d") -> Duplicates/"
                done
                echo -e "\n${GREEN}[✓] Isolated ${#dups[@]} duplicate file(s) into 'Duplicates/'.${RESET}\n"
            fi
            ;;
        2)
            echo -e "\n${CYAN}[*] Computing SHA-256 checksums...${RESET}"
            mkdir -p "$TARGET_DIR/Duplicates"
            local hash_tmp="$TARGET_DIR/.shasum_tmp_$$"
            rm -f "$hash_tmp" 2>/dev/null
            for f in "$TARGET_DIR"/*; do
                if [ -f "$f" ]; then
                    if is_excluded "$f"; then continue; fi
                    local h
                    h="$(shasum -a 256 "$f" 2>/dev/null | awk '{print $1}')"
                    if [ -n "$h" ]; then
                        echo "$h $f" >> "$hash_tmp"
                    fi
                fi
            done

            local dup_count=0
            if [ -f "$hash_tmp" ]; then
                while read -r dup_hash; do
                    [ -z "$dup_hash" ] && continue
                    local is_first=1
                    while IFS= read -r line; do
                        local fpath="${line#* }"
                        fpath="${fpath# }"
                        if [ "$is_first" -eq 1 ]; then
                            is_first=0
                        else
                            if [ -f "$fpath" ]; then
                                mv "$fpath" "$TARGET_DIR/Duplicates/"
                                echo -e " ${YELLOW}[+] Isolated exact duplicate:${RESET} $(basename "$fpath")"
                                ((dup_count++))
                            fi
                        fi
                    done < <(grep "^$dup_hash" "$hash_tmp")
                done < <(awk '{print $1}' "$hash_tmp" | sort | uniq -d)
                rm -f "$hash_tmp" 2>/dev/null
            fi

            if [ "$dup_count" -eq 0 ]; then
                echo -e "\n${GREEN}[✓] No exact bit-for-bit duplicate files found.${RESET}\n"
            else
                echo -e "\n${GREEN}[✓] Isolated $dup_count exact duplicate(s) into 'Duplicates/'.${RESET}\n"
            fi
            ;;
    esac
}

run_storage_analytics() {
    clear
    echo -e "${BOLD}======================================================${RESET}"
    echo -e "${CYAN}           Storage Analytics & Space Hogs${RESET}"
    echo -e "${BOLD}======================================================${RESET}"
    echo -e "${CYAN}Folder:${RESET} $TARGET_DIR"
    echo

    local total_files=0
    local total_bytes=0

    while IFS= read -r f; do
        if [ -f "$f" ]; then
            if is_excluded "$f"; then continue; fi
            local sz
            sz="$(stat -f "%z" "$f" 2>/dev/null || echo 0)"
            total_bytes=$((total_bytes + sz))
            ((total_files++))
        fi
    done < <(find "$TARGET_DIR" -type f -maxdepth 2 2>/dev/null)

    echo -e "Total Files: ${BOLD}$total_files${RESET}  |  Total Disk Usage: ${BOLD}$(format_bytes "$total_bytes")${RESET}"
    echo
    echo -e "${BOLD}Top 10 Largest Space Hogs:${RESET}"
    echo "------------------------------------------------------"
    find "$TARGET_DIR" -type f -maxdepth 2 -exec stat -f "%z %N" {} + 2>/dev/null | \
        sort -nr | head -n 10 | while read -r sz filepath; do
            if ! is_excluded "$filepath"; then
                printf "  %-12s %s\n" "$(format_bytes "$sz")" "$(basename "$filepath")"
            fi
        done
    echo "------------------------------------------------------"
    echo
}

run_empty_sweeper() {
    clear
    echo -e "${BOLD}======================================================${RESET}"
    echo -e "${CYAN}               Empty Folder Sweeper${RESET}"
    echo -e "${BOLD}======================================================${RESET}"
    echo
    local count=0
    while IFS= read -r d; do
        if [ "$d" != "$TARGET_DIR" ] && [ -d "$d" ] && [ -z "$(ls -A "$d")" ]; then
            rmdir "$d" 2>/dev/null && ((count++))
            echo -e " ${RED}[-] Removed empty folder:${RESET} $(basename "$d")"
        fi
    done < <(find "$TARGET_DIR" -mindepth 1 -type d -empty 2>/dev/null)

    echo
    echo -e "${GREEN}[✓] Swept $count empty folder(s).${RESET}\n"
}

# ------------------------------------------------------------------------------
# Main Menu
# ------------------------------------------------------------------------------
main_menu() {
    while true; do
        clear
        rm -f "$TEMP_SIM" 2>/dev/null
        echo -e "${BOLD}======================================================${RESET}"
        echo -e "${CYAN}           Files Organizer (macOS Edition)${RESET}"
        echo -e "${BOLD}======================================================${RESET}"
        echo -e "Folder: ${BOLD}$TARGET_DIR${RESET}"
        echo
        echo "Select an organization style:"
        echo
        echo " [1] Standard Categories"
        echo "     Images, Documents, Video, Audio, Installers, Archives, Code, etc."
        echo
        echo " [2] Deep Categories (Category + Format Subfolders)"
        echo "     Images/PNG, Images/JPG, Documents/PDF, Code/Python, etc."
        echo
        echo " [3] File Extension Directly (Flat by Format)"
        echo "     PNG/, JPG/, PDF/, ZIP/, DMG/, MP4/, etc."
        echo
        echo " [4] By Date Modified (Year & Month)"
        echo "     2026/11 - November, 2026/10 - October, etc."
        echo
        echo " [5] Hybrid (Category + Year & Month)"
        echo "     Images/2026-11, Documents/2026-11, Video/2026-10, etc."
        echo
        echo " [6] File Size Triage (Disk Space Cleanup)"
        echo "     Gigabytes (>1GB), Large (100MB-1GB), Medium, Small, Tiny"
        echo
        echo " [7] Alphabetical Groups (A-Z)"
        echo "     A - D/, E - H/, I - L/, M - P/, Q - T/, U - Z/, 0-9 and Symbols/"
        echo
        echo " [8] Custom Rules (custom_rules.txt)"
        echo "     Custom extension & keyword mapping"
        echo
        echo " ----------------- Housekeeping Tools -----------------"
        echo
        echo " [D] Duplicate Cleaner & Staging (SHA-256 / Browser Tags)"
        echo " [J] Junk & Broken Downloads Cleaner (.crdownload, .tmp, 0-byte)"
        echo " [E] Empty Folder Sweeper"
        echo " [T] Storage Analytics & Space Hogs Breakdown"
        echo
        echo " ----------------- Safety & Controls ------------------"
        echo
        echo " [P] Preview / Dry-Run (Simulate before moving)"
        echo " [U] Undo / Revert Last Organization"
        echo
        echo " [0] Exit"
        echo
        echo -e "${BOLD}======================================================${RESET}"
        read -r -p "Enter choice [0-8, D, J, E, T, P, U]: " choice
        choice="$(echo "$choice" | tr -d '\r')"

        case "$choice" in
            0)
                echo -e "\nGoodbye!\n"
                exit 0
                ;;
            1|2|3|4|5|6|7|8)
                IS_PREVIEW=0
                run_organization "$choice"
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            [Dd])
                run_duplicates_finder
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            [Jj])
                run_junk_cleaner
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            [Ee])
                run_empty_sweeper
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            [Tt])
                run_storage_analytics
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            [Pp])
                echo
                echo "Select style to simulate [1-8]:"
                read -r -p "> " sim_mode
                if [[ "$sim_mode" =~ ^[1-8]$ ]]; then
                    IS_PREVIEW=1
                    run_organization "$sim_mode"
                fi
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            [Uu])
                run_undo
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
        esac
    done
}

# Handle flags if supplied
if [ "$DO_UNDO" = "1" ]; then
    run_undo
    exit 0
elif [ "$DO_JUNK" = "1" ]; then
    run_junk_cleaner
    exit 0
elif [ "$DO_DUPS" = "1" ]; then
    run_duplicates_finder
    exit 0
elif [ -n "$CHOSEN_MODE" ]; then
    run_organization "$CHOSEN_MODE"
    exit 0
fi

# Launch interactive menu if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_menu
fi
