#!/bin/bash

# ==============================================================================
#  VESPER CAPITAL — MOBILE BUILD & RELEASE ENGINE
#  A unified, interactive, and automated compilation & distribution CLI tool.
# ==============================================================================

set -o pipefail

# ========================= 0. CLI ARGUMENTS =========================
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --integrate-gdrive|--gdrive-setup)
            echo -e "Launching Google Workspace Setup..."
            if ! command -v gws &> /dev/null; then
                echo "Installing @googleworkspace/cli via npm..."
                npm install -g @googleworkspace/cli
            fi
            gws auth setup
            exit 0
            ;;
        --deintegrate-gdrive|--gdrive-reset)
            echo -e "Resetting Google Workspace configuration..."
            rm -rf ~/.config/gws
            echo -e "Done. Google Drive upload has been de-integrated locally."
            exit 0
            ;;
        *)
            # Ignore other flags for now or just break
            break
            ;;
    esac
    shift
done

# ========================= 1. UI TOKENS & STYLING =========================
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'

# ANSI 256 Palette
CYAN='\033[38;5;45m'
BLUE='\033[38;5;39m'
GREEN='\033[38;5;84m'
YELLOW='\033[38;5;221m'
RED='\033[38;5;203m'
MAGENTA='\033[38;5;207m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;244m'
DARK_GRAY='\033[38;5;238m'
WHITE='\033[38;5;255m'

TICK="${GREEN}✔${NC}"
CROSS="${RED}✘${NC}"
INFO="${CYAN}ℹ${NC}"
WARN="${YELLOW}⚠${NC}"
STAR="${PURPLE}✦${NC}"
ARROW="${CYAN}➜${NC}"
DOT="${GRAY}•${NC}"
BOX_CHECK="${GREEN}[✔]${NC}"
BOX_UNCHECK="${GRAY}[ ]${NC}"

# ========================= 2. CORE CONFIGURATION =========================
APP_TITLE="Vesper Capital"
PREFIX="VC"
OUTPUT_DIR="output"
IOS_DIR="${OUTPUT_DIR}/ios"
ANDROID_DIR="${OUTPUT_DIR}/android"
TIMESTAMP=$(date +"%I-%M_%p_%d_%b")

# Single Variant Configuration (No Flavors / Schemes)
HAS_FLAVORS=false
VALID_FLAVORS=()
FLAVOR=""

# State Flags
BUILD_APK=false
BUILD_AAB=false
BUILD_IPA=false
NOSIGN=false
UPLOAD_PLAYSTORE=false
UPLOAD_APPSTORE=false
UPLOAD_GDRIVE=false
UPLOAD_DIAWI=false
UPLOAD_APPSHARE=false
RUN_CLEAN=true
DRY_RUN=false
VERBOSE=false
FORCE_INTERACTIVE=false

CLI_ANDROID_VERSION=""
CLI_IOS_VERSION=""
CLI_GENERIC_VERSION=""

# ----------------- CREDENTIALS & CONFIG -----------------
CONFIG_FILE=".build-config.env"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${WARN} ${YELLOW}No .build-config.env found! Generating a template...${NC}"
    cat << 'EOF' > "$CONFIG_FILE"
# ==============================================================================
#  BUILD ENGINE CONFIGURATION
#  Fill this out with your project-specific credentials before running the build.
# ==============================================================================

# App Identifiers
IOS_BUNDLE_ID="com.yourcompany.app"
ANDROID_PACKAGE_NAME="com.yourcompany.app"

# Apple App Store Connect API Key (.p8)
APPLE_API_KEY_ID=""
APPLE_API_ISSUER_ID=""

# Google Play Service Account (Place JSON in private_keys/)
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=""

# Distribution Gateways
GDRIVE_BASE_FOLDER_ID=""
DIAWI_TOKEN=""
EOF
    echo -e "${INFO} Please fill out ${BOLD}${CONFIG_FILE}${NC} and run the script again."
    exit 1
fi

# Load Config
set -a
source "$CONFIG_FILE"
set +a

# Auto-detect keys in private_keys/ if missing
APPLE_API_KEY_PATH="./private_keys/AuthKey_${APPLE_API_KEY_ID}.p8"
if [ ! -f "$APPLE_API_KEY_PATH" ]; then
    DETECTED_P8=$(find private_keys output/secret . -maxdepth 2 -name "AuthKey_*.p8" 2>/dev/null | head -n 1)
    [ -n "$DETECTED_P8" ] && APPLE_API_KEY_PATH="$DETECTED_P8"
fi

if [ ! -f "$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON" ]; then
    DETECTED_JSON=$(find private_keys output/secret . -maxdepth 2 -name "*.json" 2>/dev/null | head -n 1)
    [ -n "$DETECTED_JSON" ] && GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="$DETECTED_JSON"
fi
# ------------------------------------------------------

# Artifact Tracking
FINAL_APK_PATH=""
FINAL_APK_SIZE=""
FINAL_AAB_PATH=""
FINAL_AAB_SIZE=""
FINAL_IPA_PATH=""
FINAL_IPA_SIZE=""
FINAL_IOS_ARCHIVE=""

# Toolchain Detection (FVM priority per SOP)
if command -v fvm &> /dev/null; then
    FLUTTER_CMD="fvm flutter"
else
    FLUTTER_CMD="flutter"
fi

PUBSPEC_FILE="pubspec.yaml"
LOG_TEMP="/tmp/vc_build_$(date +%s)_$$.log"
START_TOTAL_TIME=$(date +%s)

# Suppress Fastlane update checks and banner noise
export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_HIDE_CHANGELOG=1

# ========================= 3. TERMINAL CONTROLS & CLEANUP =========================
hide_cursor() { [ -t 1 ] && printf "\033[?25l"; }
show_cursor() { [ -t 1 ] && printf "\033[?25h"; }

cleanup_exit() {
    show_cursor
    [ -t 0 ] && stty echo 2>/dev/null
    rm -f "$LOG_TEMP"
}

cleanup_interrupt() {
    show_cursor
    [ -t 0 ] && stty echo 2>/dev/null
    echo -e "\n\n  ${WARN} ${YELLOW}Pipeline cancelled by operator.${NC}\n"
    rm -f "$LOG_TEMP"
    exit 130
}

trap cleanup_interrupt SIGINT SIGTERM
trap cleanup_exit EXIT
hide_cursor

get_term_width() {
    local width
    width=$(tput cols 2>/dev/null || echo 80)
    [ "$width" -lt 40 ] && width=80
    echo "$width"
}

draw_line() {
    local width
    width=$(get_term_width)
    [ "$width" -gt 80 ] && width=80
    local line=""
    for ((i=0; i<width; i++)); do line="${line}─"; done
    echo -e "${DARK_GRAY}${line}${NC}"
}

# ========================= 4. WELCOME BANNER =========================
print_welcome_banner() {
    [ ! -t 1 ] && return 0
    local git_branch=""
    if command -v git &>/dev/null && [ -d ".git" ]; then
        git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    fi

    local flutter_ver
    flutter_ver=$($FLUTTER_CMD --version 2>/dev/null | head -n 1 | awk '{print $2}')
    [ -z "$flutter_ver" ] && flutter_ver="3.x"

    echo ""
    echo -e "${CYAN}  ╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}  ║${NC}   ${BOLD}${WHITE}❖  ${APP_TITLE} — MOBILE BUILD & RELEASE ENGINE${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}  ║${NC}   ${DIM}Automated compilation, artifact management & store distribution${NC}    ${CYAN}║${NC}"
    echo -e "${CYAN}  ╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "   ${DIM}Branch:${NC} ${CYAN}${git_branch:-main}${NC}  ${DIM}•${NC}  ${DIM}Toolchain:${NC} ${GREEN}${FLUTTER_CMD} (v${flutter_ver})${NC}  ${DIM}•${NC}  ${DIM}Time:${NC} ${YELLOW}${TIMESTAMP}${NC}"
    draw_line
    echo ""
}

# ========================= 5. STEP PROGRESS HEADER =========================
draw_step_header() {
    local current=$1
    local total=$2
    local title=$3

    local pct=$(( current * 100 / total ))
    local bar_len=18
    local filled=$(( current * bar_len / total ))
    local unfilled=$(( bar_len - filled ))

    local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=0; i<unfilled; i++)); do bar="${bar}░"; done

    echo ""
    echo -e "${BOLD}${CYAN}[Step ${current}/${total}]${NC} ${BOLD}${WHITE}${title}${NC}"
    echo -e " ${CYAN}[${bar}]${NC} ${DIM}${pct}% pipeline completed${NC}"
    echo ""
}

# ========================= 6. ANIMATED SPINNER ENGINE =========================
spin_engine() {
    local pid=$1
    local msg=$2
    local logfile=$3
    local start_time
    start_time=$(date +%s)
    local spin_chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local num_chars=${#spin_chars[@]}
    local i=0
    local delay=0.08

    if [ -t 1 ] && [ "$VERBOSE" = false ]; then
        while kill -0 "$pid" 2>/dev/null; do
            local now_time
            now_time=$(date +%s)
            local elapsed=$(( now_time - start_time ))
            local mins=$(( elapsed / 60 ))
            local secs=$(( elapsed % 60 ))
            local timer_str=$(printf "[%02d:%02d]" "$mins" "$secs")

            printf "\r\033[K  ${PURPLE}%s${NC} ${DIM}%s${NC} %s..." "${spin_chars[$i]}" "$timer_str" "$msg"
            i=$(( (i + 1) % num_chars ))
            sleep $delay
        done
    fi

    wait "$pid"
    local exit_status=$?

    local end_time
    end_time=$(date +%s)
    local total_elapsed=$(( end_time - start_time ))
    local t_mins=$(( total_elapsed / 60 ))
    local t_secs=$(( total_elapsed % 60 ))
    local final_timer=$(printf "[%02d:%02d]" "$t_mins" "$t_secs")

    if [ $exit_status -eq 0 ]; then
        if [ -t 1 ]; then
            printf "\r\033[K  ${TICK} ${DIM}%s${NC} %s\n" "$final_timer" "$msg"
        else
            printf "  ${TICK} %s %s\n" "$final_timer" "$msg"
        fi
        return 0
    else
        if [ -t 1 ]; then
            printf "\r\033[K  ${CROSS} ${DIM}%s${NC} ${RED}Failed: %s (Exit Code: %s)${NC}\n" "$final_timer" "$msg" "$exit_status"
        else
            printf "  ${CROSS} %s Failed: %s (Exit Code: %s)\n" "$final_timer" "$msg" "$exit_status"
        fi

        print_error_card "Compilation/Execution Step Failed" "$msg returned non-zero status ($exit_status)" "$logfile"
        exit "$exit_status"
    fi
}

# ========================= 7. THE HUMAN ERROR ENGINE (NO STACK TRACES) =========================
print_error_card() {
    local title=$1
    local cause=$2
    local logfile=$3

    show_cursor
    [ -t 0 ] && stty echo 2>/dev/null
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}${RED}✘ BUILD PIPELINE ERROR: ${title}${NC}"
    echo -e "${RED}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${RED}║${NC}  ${BOLD}Reason:${NC} ${WHITE}${cause}${NC}"
    
    local quick_fix=""
    if [ -n "$logfile" ] && [ -f "$logfile" ]; then
        echo -e "${RED}║${NC}"
        echo -e "${RED}║${NC}  ${BOLD}Recent Diagnostic Output:${NC}"
        local error_snip
        error_snip=$(tail -n 35 "$logfile" 2>/dev/null | grep -v 'Running Gradle' | grep -v 'Downloading' | grep -v 'Running pod install' | tail -n 10)
        while IFS= read -r line; do
            [ -n "$line" ] && echo -e "${RED}║${NC}    ${DIM}${line}${NC}"
        done <<< "$error_snip"
        echo -e "${RED}║${NC}"
        echo -e "${RED}║${NC}  ${BOLD}Complete Log Location:${NC} ${CYAN}${logfile}${NC}"

        # Diagnose common root causes
        if grep -qi "pod" "$logfile" 2>/dev/null || grep -qi "CocoaPods" "$logfile" 2>/dev/null; then
            quick_fix="Run 'cd ios && pod install --repo-update && cd ..' to refresh CocoaPods."
        elif grep -qi "keystore" "$logfile" 2>/dev/null || grep -qi "signing" "$logfile" 2>/dev/null; then
            quick_fix="Check android/key.properties or signing configuration in Xcode."
        elif grep -qi "AuthKey" "$logfile" 2>/dev/null || grep -qi "altool" "$logfile" 2>/dev/null; then
            quick_fix="Verify Apple API Key ID, Issuer ID, and .p8 file in private_keys/ folder."
        elif grep -qi "google-play" "$logfile" 2>/dev/null || grep -qi "supply" "$logfile" 2>/dev/null; then
            quick_fix="Verify Google Play Service Account JSON key permissions in Google Cloud Console."
        fi
    fi

    echo -e "${RED}║${NC}"
    echo -e "${RED}║${NC}  ${BOLD}Actionable Next Steps:${NC}"
    if [ -n "$quick_fix" ]; then
        echo -e "${RED}║${NC}    ${CYAN}✦${NC} ${YELLOW}${quick_fix}${NC}"
    fi
    echo -e "${RED}║${NC}    ${CYAN}1.${NC} Run ${BOLD}${FLUTTER_CMD} clean && ${FLUTTER_CMD} pub get${NC}"
    echo -e "${RED}║${NC}    ${CYAN}2.${NC} Check ${BOLD}${FLUTTER_CMD} doctor -v${NC} to confirm toolchain health."
    echo -e "${RED}║${NC}    ${CYAN}3.${NC} Inspect the complete log file: ${CYAN}${logfile:-/tmp/}${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ========================= 8. INTERACTIVE MENU ENGINES =========================
read_key() {
    local key=""
    local rest=""
    IFS= read -r -s -n 1 key 2>/dev/null
    if [[ "$key" == $'\033' ]]; then
        read -r -s -n 2 -t 1 rest 2>/dev/null
        case "$rest" in
            "[A"|"OA") echo "UP" ;;
            "[B"|"OB") echo "DOWN" ;;
            "[C"|"OC") echo "RIGHT" ;;
            "[D"|"OD") echo "LEFT" ;;
            *) echo "ESC" ;;
        esac
    elif [[ -z "$key" || "$key" == $'\n' || "$key" == $'\r' ]]; then
        echo "ENTER"
    elif [[ "$key" == " " ]]; then
        echo "SPACE"
    elif [[ "$key" == $'\177' || "$key" == $'\b' ]]; then
        echo "BACKSPACE"
    elif [[ "$key" =~ ^[0-9]$ ]]; then
        echo "$key"
    elif [[ "$key" == "q" || "$key" == "Q" ]]; then
        echo "QUIT"
    elif [[ "$key" == "a" || "$key" == "A" ]]; then
        echo "TOGGLE_ALL"
    elif [[ "$key" == "k" ]]; then
        echo "UP"
    elif [[ "$key" == "j" ]]; then
        echo "DOWN"
    else
        echo "$key"
    fi
}

menu_single_select() {
    local title=$1
    local default_idx=$2
    shift 2
    local options=("$@")
    local count=${#options[@]}
    local current=$default_idx
    [ "$current" -ge "$count" ] && current=0

    echo -e "${BOLD}${WHITE}${title}${NC} ${DIM}(Use ↑/↓ or 1-${count}, Enter to select)${NC}"

    for ((i=0; i<count; i++)); do
        if [ "$i" -eq "$current" ]; then
            echo -e "  ${ARROW} ${BOLD}${CYAN}${options[$i]}${NC}"
        else
            echo -e "    ${DIM}${options[$i]}${NC}"
        fi
    done

    while true; do
        local key
        key=$(read_key)
        case "$key" in
            UP)
                current=$(( (current - 1 + count) % count ))
                ;;
            DOWN)
                current=$(( (current + 1) % count ))
                ;;
            ENTER)
                break
                ;;
            QUIT)
                echo -e "\n  ${WARN} Operation cancelled by user."
                exit 130
                ;;
            [1-9])
                local num_idx=$(( key - 1 ))
                if [ "$num_idx" -lt "$count" ]; then
                    current=$num_idx
                    break
                fi
                ;;
        esac

        printf "\033[%dA" "$count"
        for ((i=0; i<count; i++)); do
            if [ "$i" -eq "$current" ]; then
                printf "\r\033[K  ${ARROW} ${BOLD}${CYAN}%s${NC}\n" "${options[$i]}"
            else
                printf "\r\033[K    ${DIM}%s${NC}\n" "${options[$i]}"
            fi
        done
    done

    MENU_RESULT=$current
}

menu_multi_select() {
    local title=$1
    local defaults_csv=$2
    shift 2
    local options=("$@")
    local count=${#options[@]}
    local current=0

    local selected=()
    for ((i=0; i<count; i++)); do selected[i]=0; done

    IFS=',' read -r -a def_arr <<< "$defaults_csv"
    for idx in "${def_arr[@]}"; do
        if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -lt "$count" ]; then
            selected[idx]=1
        fi
    done

    echo -e "${BOLD}${WHITE}${title}${NC} ${DIM}(Space: Toggle, 'a': All, 1-${count}: Direct, Enter: Confirm)${NC}"

    for ((i=0; i<count; i++)); do
        local box="$BOX_UNCHECK"
        [ "${selected[i]}" -eq 1 ] && box="$BOX_CHECK"
        if [ "$i" -eq "$current" ]; then
            echo -e "  ${ARROW} ${box} ${BOLD}${WHITE}${options[$i]}${NC}"
        else
            echo -e "    ${box} ${DIM}${options[$i]}${NC}"
        fi
    done

    while true; do
        local key
        key=$(read_key)
        case "$key" in
            UP)
                current=$(( (current - 1 + count) % count ))
                ;;
            DOWN)
                current=$(( (current + 1) % count ))
                ;;
            SPACE)
                if [ "${selected[current]}" -eq 1 ]; then
                    selected[current]=0
                else
                    selected[current]=1
                fi
                ;;
            TOGGLE_ALL)
                local all_sel=1
                for ((i=0; i<count; i++)); do
                    [ "${selected[i]}" -eq 0 ] && all_sel=0
                done
                for ((i=0; i<count; i++)); do
                    if [ "$all_sel" -eq 1 ]; then selected[i]=0; else selected[i]=1; fi
                done
                ;;
            [1-9])
                local num_idx=$(( key - 1 ))
                if [ "$num_idx" -lt "$count" ]; then
                    if [ "${selected[num_idx]}" -eq 1 ]; then
                        selected[num_idx]=0
                    else
                        selected[num_idx]=1
                    fi
                fi
                ;;
            ENTER)
                local any=0
                for ((i=0; i<count; i++)); do
                    [ "${selected[i]}" -eq 1 ] && any=1
                done
                if [ $any -eq 1 ]; then
                    break
                else
                    printf "\r\033[K  ${WARN} ${YELLOW}Please select at least one option before pressing Enter.${NC}"
                    sleep 1
                fi
                ;;
            QUIT)
                echo -e "\n  ${WARN} Operation cancelled by user."
                exit 130
                ;;
        esac

        printf "\033[%dA" "$count"
        for ((i=0; i<count; i++)); do
            local box="$BOX_UNCHECK"
            [ "${selected[i]}" -eq 1 ] && box="$BOX_CHECK"
            if [ "$i" -eq "$current" ]; then
                printf "\r\033[K  ${ARROW} %b ${BOLD}${WHITE}%s${NC}\n" "$box" "${options[$i]}"
            else
                printf "\r\033[K    %b ${DIM}%s${NC}\n" "$box" "${options[$i]}"
            fi
        done
    done

    MULTI_MENU_RESULTS=()
    for ((i=0; i<count; i++)); do
        MULTI_MENU_RESULTS[i]=${selected[i]}
    done
}

prompt_text_with_validation() {
    local prompt_label=$1
    local default_value=$2
    local var_name=$3

    show_cursor
    while true; do
        printf "  ${INFO} %s ${DIM}[default: ${CYAN}%s${DIM}]${NC}: " "$prompt_label" "$default_value"
        read -r user_input
        local val="${user_input:-$default_value}"

        # Validate semantic version pattern: <version>+<build> (e.g. 1.0.0+2, 1.0+9)
        if [[ "$val" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?\+[0-9]+$ ]]; then
            eval "$var_name=\"$val\""
            break
        else
            echo -e "  ${CROSS} ${RED}Invalid format '${val}'. Expected format: <version>+<build> (e.g. 1.0.0+2)${NC}"
        fi
    done
    hide_cursor
}

prompt_confirm_yn() {
    local prompt_text=$1
    local default_ans=$2
    local var_name=$3

    show_cursor
    local hint="[y/N]"
    [ "$default_ans" = "y" ] && hint="[Y/n]"
    printf "  ${INFO} %s %s: " "$prompt_text" "$hint"
    read -r user_input
    local result="${user_input:-$default_ans}"
    result=$(echo "$result" | tr '[:upper:]' '[:lower:]')
    if [[ "$result" =~ ^(y|yes)$ ]]; then
        eval "$var_name=true"
    else
        eval "$var_name=false"
    fi
    hide_cursor
}

# ========================= 9. INTERACTIVE WIZARD FLOW =========================
run_interactive_wizard() {
    print_welcome_banner

    # Step 1: Platforms
    echo -e "${BOLD}${CYAN}❖ Step 1: Select Compilation Platform Packages${NC}\n"
    local platform_opts=(
        "Android APK (Testing / Direct Device Install)"
        "Android App Bundle (AAB - Google Play Store)"
        "iOS IPA (App Store Connect / TestFlight)"
        "iOS Unsigned Archive (Xcode Organizer / No-codesign)"
    )
    menu_multi_select "Choose platforms to compile:" "0,2" "${platform_opts[@]}"
    
    BUILD_APK=false
    BUILD_AAB=false
    BUILD_IPA=false
    NOSIGN=false

    [ "${MULTI_MENU_RESULTS[0]}" -eq 1 ] && BUILD_APK=true
    [ "${MULTI_MENU_RESULTS[1]}" -eq 1 ] && BUILD_AAB=true
    [ "${MULTI_MENU_RESULTS[2]}" -eq 1 ] && BUILD_IPA=true
    if [ "${MULTI_MENU_RESULTS[3]}" -eq 1 ]; then
        BUILD_IPA=true
        NOSIGN=true
    fi

    # Determine Active Target Platforms
    local target_android=false
    local target_ios=false
    [ "$BUILD_APK" = true ] || [ "$BUILD_AAB" = true ] && target_android=true
    [ "$BUILD_IPA" = true ] && target_ios=true

    # Version Extraction Defaults from pubspec.yaml
    local def_pub_ver=""
    [ -f "$PUBSPEC_FILE" ] && def_pub_ver=$(grep '^version:' "$PUBSPEC_FILE" | head -n 1 | awk '{print $2}')
    [ -z "$def_pub_ver" ] && def_pub_ver="1.0.0+1"

    local def_android_ver=""
    if [ -f "$PUBSPEC_FILE" ]; then
        def_android_ver=$(grep -E '^# ?(Android version:|version:)' "$PUBSPEC_FILE" | head -n 1 | awk '{print $NF}')
    fi
    [ -z "$def_android_ver" ] && def_android_ver="$def_pub_ver"

    local def_ios_ver=""
    if [ -f "$PUBSPEC_FILE" ]; then
        def_ios_ver=$(grep -E '^# ?(iOS version:|version:)' "$PUBSPEC_FILE" | grep -v 'Android' | head -n 1 | awk '{print $NF}')
    fi
    [ -z "$def_ios_ver" ] && def_ios_ver="$def_pub_ver"

    echo ""
    echo -e "${BOLD}${CYAN}❖ Step 2: Platform Version Configurations${NC}\n"

    # Only prompt for Android version if Android is targeted
    if [ "$target_android" = true ]; then
        prompt_text_with_validation "Android Version (Format: <version>+<build>)" "$def_android_ver" CLI_ANDROID_VERSION
    else
        echo -e "  ${DIM}ℹ Skipping Android version input (Android platform not selected).${NC}"
    fi

    # Only prompt for iOS version if iOS is targeted
    if [ "$target_ios" = true ]; then
        prompt_text_with_validation "iOS Version (Format: <version>+<build>)" "$def_ios_ver" CLI_IOS_VERSION
    else
        echo -e "  ${DIM}ℹ Skipping iOS version input (iOS platform not selected).${NC}"
    fi

    # Step 3: Upload Gateways
    echo ""
    echo -e "${BOLD}${CYAN}❖ Step 3: Distribution & Store Gateways${NC}\n"
    
    local upload_opts=()
    local upload_mappings=()
    
    if [ "$target_android" = true ]; then
        upload_opts+=("Google Play Console (Internal Track)")
        upload_mappings+=("playstore")
        upload_opts+=("Google Drive (APK Only)")
        upload_mappings+=("gdrive")
    fi
    if [ "$target_ios" = true ] && [ "$NOSIGN" = false ]; then
        upload_opts+=("Apple App Store / TestFlight")
        upload_mappings+=("appstore")
        upload_opts+=("Diawi (Internal Testing)")
        upload_mappings+=("diawi")
    fi
    upload_opts+=("Local Build Only (Do not upload to stores)")
    upload_mappings+=("none")

    UPLOAD_PLAYSTORE=false
    UPLOAD_APPSTORE=false
    UPLOAD_GDRIVE=false
    UPLOAD_DIAWI=false

    if [ ${#upload_opts[@]} -gt 1 ]; then
        menu_single_select "Select automated release distribution destination:" 0 "${upload_opts[@]}"
        local sel_target="${upload_mappings[$MENU_RESULT]}"
        if [ "$sel_target" = "playstore" ]; then
            UPLOAD_PLAYSTORE=true
            # Ensure AAB is built if upload is requested
            [ "$BUILD_AAB" = false ] && [ "$BUILD_APK" = false ] && BUILD_AAB=true
        elif [ "$sel_target" = "gdrive" ]; then
            UPLOAD_GDRIVE=true
            [ "$BUILD_APK" = false ] && BUILD_APK=true
        elif [ "$sel_target" = "appstore" ]; then
            UPLOAD_APPSTORE=true
        elif [ "$sel_target" = "diawi" ]; then
            UPLOAD_DIAWI=true
        fi
    else
        echo -e "  ${INFO} Skipping store gateways (Unsigned / Local build selected)."
    fi

    # Step 4: Pre-Flight Confirmation
    echo ""
    draw_line
    echo -e "${BOLD}${WHITE}📋 Pre-Flight Execution Summary${NC}"
    draw_line
    echo -e "  ${DOT} ${BOLD}App:${NC}               ${WHITE}${APP_TITLE}${NC} (${PREFIX})"
    
    local plat_summary=""
    [ "$BUILD_APK" = true ] && plat_summary="${plat_summary}APK "
    [ "$BUILD_AAB" = true ] && plat_summary="${plat_summary}AAB "
    [ "$BUILD_IPA" = true ] && [ "$NOSIGN" = false ] && plat_summary="${plat_summary}IPA "
    [ "$BUILD_IPA" = true ] && [ "$NOSIGN" = true ] && plat_summary="${plat_summary}IPA(Unsigned) "
    echo -e "  ${DOT} ${BOLD}Platforms:${NC}         ${GREEN}${plat_summary}${NC}"

    if [ "$target_android" = true ]; then
        echo -e "  ${DOT} ${BOLD}Android Version:${NC}   ${YELLOW}${CLI_ANDROID_VERSION}${NC}"
    fi
    if [ "$target_ios" = true ]; then
        echo -e "  ${DOT} ${BOLD}iOS Version:${NC}       ${YELLOW}${CLI_IOS_VERSION}${NC}"
    fi

    local upload_summary="Local Only"
    if [ "$UPLOAD_PLAYSTORE" = true ] && [ "$UPLOAD_APPSTORE" = true ]; then
        upload_summary="Google Play + TestFlight"
    elif [ "$UPLOAD_PLAYSTORE" = true ]; then
        upload_summary="Google Play (Internal)"
    elif [ "$UPLOAD_APPSTORE" = true ]; then
        upload_summary="TestFlight (App Store)"
    fi
    echo -e "  ${DOT} ${BOLD}Distribution:${NC}      ${MAGENTA}${upload_summary}${NC}"
    echo -e "  ${DOT} ${BOLD}Sanitation:${NC}        ${WHITE}Clean & Pub Get${NC}"
    draw_line
    echo ""

    local confirm_run=true
    prompt_confirm_yn "Ready to proceed with compilation pipeline?" "y" confirm_run
    if [ "$confirm_run" = false ]; then
        echo -e "\n  ${WARN} ${YELLOW}Pipeline cancelled by operator.${NC}\n"
        exit 0
    fi
}

# ========================= 10. HELP FUNCTION =========================
usage() {
    show_cursor
    print_welcome_banner
    echo -e "${BOLD}${WHITE}USAGE:${NC}"
    echo -e "  ${CYAN}./build.sh${NC}                    Launch interactive wizard ${DIM}(Default)${NC}"
    echo -e "  ${CYAN}./build.sh [options]${NC}          Execute in headless / CI/CD mode\n"
    
    echo -e "${BOLD}${WHITE}OPTIONS:${NC}"
    echo -e "  ${CYAN}-p, --platform${NC} <targets> Target packages: ${BOLD}apk, appbundle, ipa, nosign${NC}"
    echo -e "  ${CYAN}-v, --version${NC} <versions>   Explicit versions: ${BOLD}a1.0.0+2${NC} (Android), ${BOLD}i1.0.0+9${NC} (iOS)"
    echo -e "  ${CYAN}-u, --upload${NC} <targets>    Distribution: ${BOLD}playstore, appstore${NC}"
    echo -e "  ${CYAN}-i, --interactive${NC}         Force interactive wizard"
    echo -e "  ${CYAN}--no-clean${NC}                Skip workspace cleaning step (${FLUTTER_CMD} clean)"
    echo -e "  ${CYAN}--dry-run${NC}                 Validate configurations and paths without executing build"
    echo -e "  ${CYAN}-V, --verbose${NC}             Stream full compilation output directly to terminal"
    echo -e "  ${CYAN}-h, --help${NC}                Display this command manual\n"

    echo -e "${BOLD}${WHITE}EXAMPLES:${NC}"
    echo -e "  ${DIM}# Interactive wizard:${NC}"
    echo -e "  ${CYAN}./build.sh${NC}\n"
    echo -e "  ${DIM}# Build Android APK & iOS IPA locally:${NC}"
    echo -e "  ${CYAN}./build.sh -p apk ipa${NC}\n"
    echo -e "  ${DIM}# Build iOS IPA only (Android versions are automatically ignored):${NC}"
    echo -e "  ${CYAN}./build.sh -p ipa -v i1.0.0+9${NC}\n"
    echo -e "  ${DIM}# Build Production AAB & IPA and upload to both stores:${NC}"
    echo -e "  ${CYAN}./build.sh -p appbundle ipa -u playstore appstore -v a1.0.0+2 i1.0.0+9${NC}\n"
    exit 0
}

# ========================= 11. ARGUMENT PARSING =========================
if [ "$#" -eq 0 ]; then
    if [ -t 0 ] && [ -t 1 ]; then
        run_interactive_wizard
    else
        usage
    fi
else
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -f|--flavor)
                echo -e "  ${INFO} Flavor flag (-f) provided but this project has no flavors configured ${DIM}(ignoring)${NC}"
                shift ;;
            -p|--platform) shift
                if [[ -z "$1" || "$1" =~ ^- ]]; then
                    print_error_card "Invalid Argument" "Option -p requires at least one platform target (apk, appbundle, ipa, nosign)" ""
                    exit 1
                fi
                while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                    case $1 in
                        apk) BUILD_APK=true ;;
                        appbundle|aab) BUILD_AAB=true ;;
                        ipa) BUILD_IPA=true ;;
                        nosign) NOSIGN=true ;;
                        *)
                            print_error_card "Invalid Platform" "Unknown platform target '$1'. Allowed: apk, appbundle, ipa, nosign" ""
                            exit 1 ;;
                    esac
                    shift
                done
                continue ;;
            -v|--version) shift
                if [[ -z "$1" || "$1" =~ ^- ]]; then
                    print_error_card "Invalid Argument" "Option -v requires version string (e.g. -v a1.0.0+2 i1.0.0+9)" ""
                    exit 1
                fi
                while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                    if [[ $1 =~ ^a[0-9] ]]; then
                        CLI_ANDROID_VERSION="${1#a}"
                    elif [[ $1 =~ ^i[0-9] ]]; then
                        CLI_IOS_VERSION="${1#i}"
                    elif [[ $1 =~ ^[0-9]+\.[0-9]+ ]]; then
                        CLI_GENERIC_VERSION="$1"
                    else
                        print_error_card "Invalid Version Format" "Invalid version format '$1'. Expected format: a1.0.0+2 or i1.0.0+9" ""
                        exit 1
                    fi
                    shift
                done
                continue ;;
            -u|--upload) shift
                if [[ -z "$1" || "$1" =~ ^- ]]; then
                    print_error_card "Invalid Argument" "Option -u requires distribution target (playstore, appstore)" ""
                    exit 1
                fi
                while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                    case $1 in
                        playstore|googleplay) UPLOAD_PLAYSTORE=true ;;
                        appstore|testflight) UPLOAD_APPSTORE=true ;;
                        *)
                            print_error_card "Invalid Upload Target" "Unknown target '$1'. Allowed: playstore, appstore" ""
                            exit 1 ;;
                    esac
                    shift
                done
                continue ;;
            -i|--interactive)
                FORCE_INTERACTIVE=true ;;
            --no-clean)
                RUN_CLEAN=false ;;
            --dry-run)
                DRY_RUN=true ;;
            -V|--verbose)
                VERBOSE=true ;;
            -h|--help|help)
                usage ;;
            *)
                print_error_card "Unknown Argument" "Unrecognized command flag '$1'. Use --help for usage instructions." ""
                exit 1 ;;
        esac
        shift
    done

    if [ "$FORCE_INTERACTIVE" = true ]; then
        run_interactive_wizard
    fi
fi

# ========================= 12. PARAMETER & SAFETY VALIDATION =========================
print_welcome_banner

# Validate Platform selection
if [ "$BUILD_APK" = false ] && [ "$BUILD_AAB" = false ] && [ "$BUILD_IPA" = false ]; then
    print_error_card "Missing Platform Target" "You must specify at least one compilation platform (-p apk | appbundle | ipa | nosign)" ""
    exit 1
fi

IS_ANDROID=false
IS_IOS=false
[ "$BUILD_APK" = true ] || [ "$BUILD_AAB" = true ] || [ "$UPLOAD_PLAYSTORE" = true ] && IS_ANDROID=true
[ "$BUILD_IPA" = true ] || [ "$UPLOAD_APPSTORE" = true ] && IS_IOS=true

# Validate Upload Intent Logic Mismatch
if [ "$UPLOAD_PLAYSTORE" = true ] && [ "$BUILD_APK" = false ] && [ "$BUILD_AAB" = false ]; then
    BUILD_AAB=true # Auto-enable AAB for store upload
fi
if [ "$UPLOAD_APPSTORE" = true ] && [ "$BUILD_IPA" = false ]; then
    BUILD_IPA=true # Auto-enable IPA for App Store upload
fi

# Check Credentials & Fallbacks
if [ "$UPLOAD_PLAYSTORE" = true ] && [ ! -f "$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON" ]; then
    print_error_card "Credentials Missing" "Google Play Service Account JSON not found at: $GOOGLE_PLAY_SERVICE_ACCOUNT_JSON" ""
    exit 1
fi

if [ "$UPLOAD_APPSTORE" = true ]; then
    if [ ! -f "$APPLE_API_KEY_PATH" ]; then
        echo -e "  ${WARN} ${YELLOW}iOS .p8 API Key file not found at: ${APPLE_API_KEY_PATH}${NC}"
        echo -e "     ${DIM}Fallback: Disabling TestFlight auto-upload and generating unsigned build archive.${NC}"
        UPLOAD_APPSTORE=false
        NOSIGN=true
    fi
fi

# ========================= 13. SELECTIVE VERSION RESOLUTION =========================
if [ ! -f "$PUBSPEC_FILE" ]; then
    print_error_card "Missing Project File" "'pubspec.yaml' not found in current directory." ""
    exit 1
fi

DEFAULT_PUB_VERSION=$(grep '^version:' "$PUBSPEC_FILE" | head -n 1 | awk '{print $2}')
[ -z "$DEFAULT_PUB_VERSION" ] && DEFAULT_PUB_VERSION="1.0.0+1"

split_version() {
    local full=$1
    if [[ "$full" == *"+"* ]]; then
        echo "${full%+*}" "${full#*+}"
    else
        echo "$full" "1"
    fi
}

# Android Version Handling (DECOUPLED & SELECTIVE)
if [ "$IS_ANDROID" = true ]; then
    ANDROID_RAW=$(grep -E '^# ?(Android version:|version:)' "$PUBSPEC_FILE" | head -n 1 | awk '{print $NF}')
    ANDROID_FINAL=${CLI_ANDROID_VERSION:-${CLI_GENERIC_VERSION:-${ANDROID_RAW:-$DEFAULT_PUB_VERSION}}}
    read ANDROID_NAME ANDROID_CODE <<< $(split_version "$ANDROID_FINAL")
    mkdir -p "${ANDROID_DIR}"
elif [ -n "$CLI_ANDROID_VERSION" ]; then
    echo -e "  ${DIM}ℹ Android version specified (${CLI_ANDROID_VERSION}) but no Android target selected — skipping Android versioning.${NC}"
fi

# iOS Version Handling (DECOUPLED & SELECTIVE)
if [ "$IS_IOS" = true ]; then
    IOS_RAW=$(grep -E '^# ?(iOS version:|version:)' "$PUBSPEC_FILE" | grep -v 'Android' | head -n 1 | awk '{print $NF}')
    IOS_FINAL=${CLI_IOS_VERSION:-${CLI_GENERIC_VERSION:-${IOS_RAW:-$DEFAULT_PUB_VERSION}}}
    read IOS_NAME IOS_CODE <<< $(split_version "$IOS_FINAL")
    mkdir -p "${IOS_DIR}"
elif [ -n "$CLI_IOS_VERSION" ]; then
    echo -e "  ${DIM}ℹ iOS version specified (${CLI_IOS_VERSION}) but no iOS target selected — skipping iOS versioning.${NC}"
fi

# Calculate Total Steps
TOTAL_STEPS=2 # Sanitation (1) + Compilation (2)
[ "$UPLOAD_PLAYSTORE" = true ] || [ "$UPLOAD_APPSTORE" = true ] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
CURRENT_STEP=1

echo -e "  ${TICK} Pre-flight parameters and environment profiles validated successfully."

if [ "$DRY_RUN" = true ]; then
    echo -e "\n${BOLD}${GREEN}✔ DRY RUN COMPLETE${NC} — All flags, version strings, and credentials validated cleanly.\n"
    exit 0
fi

# ========================= 14. PHASE 1: WORKSPACE SANITATION =========================
draw_step_header $CURRENT_STEP $TOTAL_STEPS "Workspace Sanitation & Dependency Sync"

if [ "$RUN_CLEAN" = true ]; then
    $FLUTTER_CMD clean > "$LOG_TEMP" 2>&1 &
    spin_engine $! "Purging build telemetry and project caches (${FLUTTER_CMD} clean)" "$LOG_TEMP"
fi

$FLUTTER_CMD pub get > "$LOG_TEMP" 2>&1 &
spin_engine $! "Resolving remote pub dependency tree mappings (${FLUTTER_CMD} pub get)" "$LOG_TEMP"

CURRENT_STEP=$(( CURRENT_STEP + 1 ))

# ========================= 15. PHASE 2: COMPILATION PIPELINE =========================
draw_step_header $CURRENT_STEP $TOTAL_STEPS "Platform Engine Native Compilation"

build_android_apk() {
    $FLUTTER_CMD build apk --release --build-name=${ANDROID_NAME} --build-number=${ANDROID_CODE} > "$LOG_TEMP" 2>&1 &
    spin_engine $! "Compiling Android Release Package (APK v${ANDROID_NAME}+${ANDROID_CODE})" "$LOG_TEMP"

    local apk_src
    apk_src=$(find build/app/outputs/flutter-apk -name "*.apk" ! -name "*unaligned*" 2>/dev/null | head -n 1)
    if [ -n "$apk_src" ] && [ -f "$apk_src" ]; then
        FINAL_APK_PATH="${ANDROID_DIR}/${PREFIX}_${ANDROID_NAME}_${ANDROID_CODE}_${TIMESTAMP}.apk"
        cp "$apk_src" "$FINAL_APK_PATH" || {
            print_error_card "File Copy Failed" "Failed to copy compiled APK to ${FINAL_APK_PATH}" ""
            exit 1
        }
        FINAL_APK_SIZE=$(ls -lh "$FINAL_APK_PATH" | awk '{print $5}')
        echo -e "     ${ARROW} APK Saved: ${BOLD}${CYAN}${FINAL_APK_PATH}${NC} ${DIM}(${FINAL_APK_SIZE})${NC}"
    else
        print_error_card "Output Missing" "Build completed but no APK output file found in build/app/outputs/flutter-apk" "$LOG_TEMP"
        exit 1
    fi
}

build_android_aab() {
    $FLUTTER_CMD build appbundle --release --build-name=${ANDROID_NAME} --build-number=${ANDROID_CODE} > "$LOG_TEMP" 2>&1 &
    spin_engine $! "Compiling Production AppBundle Payload (AAB v${ANDROID_NAME}+${ANDROID_CODE})" "$LOG_TEMP"

    local aab_src
    aab_src=$(find build/app/outputs/bundle -name "*.aab" 2>/dev/null | head -n 1)
    if [ -n "$aab_src" ] && [ -f "$aab_src" ]; then
        FINAL_AAB_PATH="${ANDROID_DIR}/${PREFIX}_${ANDROID_NAME}_${ANDROID_CODE}_${TIMESTAMP}.aab"
        cp "$aab_src" "$FINAL_AAB_PATH" || {
            print_error_card "File Copy Failed" "Failed to copy compiled AAB to ${FINAL_AAB_PATH}" ""
            exit 1
        }
        FINAL_AAB_SIZE=$(ls -lh "$FINAL_AAB_PATH" | awk '{print $5}')
        echo -e "     ${ARROW} AAB Saved: ${BOLD}${CYAN}${FINAL_AAB_PATH}${NC} ${DIM}(${FINAL_AAB_SIZE})${NC}"
    else
        print_error_card "Output Missing" "Build completed but no AAB output file found in build/app/outputs/bundle" "$LOG_TEMP"
        exit 1
    fi
}

build_ios_ipa() {
    local extra_flag=""
    [ "$NOSIGN" = true ] && extra_flag="--no-codesign"

    $FLUTTER_CMD build ipa --release $extra_flag --build-name=${IOS_NAME} --build-number=${IOS_CODE} > "$LOG_TEMP" 2>&1 &
    spin_engine $! "Compiling iOS Native Package (IPA v${IOS_NAME}+${IOS_CODE})" "$LOG_TEMP"

    if [ "$NOSIGN" = false ]; then
        local ipa_src
        ipa_src=$(find build/ios/ipa -name "*.ipa" 2>/dev/null | head -n 1)
        if [ -n "$ipa_src" ] && [ -f "$ipa_src" ]; then
            FINAL_IPA_PATH="${IOS_DIR}/${PREFIX}_${IOS_NAME}_${IOS_CODE}_${TIMESTAMP}.ipa"
            cp "$ipa_src" "$FINAL_IPA_PATH" || {
                print_error_card "File Copy Failed" "Failed to copy compiled IPA to ${FINAL_IPA_PATH}" ""
                exit 1
            }
            FINAL_IPA_SIZE=$(ls -lh "$FINAL_IPA_PATH" | awk '{print $5}')
            echo -e "     ${ARROW} IPA Saved: ${BOLD}${CYAN}${FINAL_IPA_PATH}${NC} ${DIM}(${FINAL_IPA_SIZE})${NC}"
        else
            echo -e "     ${WARN} ${YELLOW}No .ipa binary found in build/ios/ipa (Runner.xcarchive generated)${NC}"
        fi
    else
        FINAL_IOS_ARCHIVE="build/ios/archive/Runner.xcarchive"
        if [ -d "$FINAL_IOS_ARCHIVE" ]; then
            echo -e "     ${ARROW} Archive Generated: ${BOLD}${CYAN}${FINAL_IOS_ARCHIVE}${NC}"
        fi
    fi
}

if [ "$IS_ANDROID" = true ]; then
    [ "$BUILD_APK" = true ] && build_android_apk
    [ "$BUILD_AAB" = true ] && build_android_aab
fi

if [ "$IS_IOS" = true ] && [ "$BUILD_IPA" = true ]; then
    build_ios_ipa
fi

# ========================= 16. PHASE 3: STORE DISTRIBUTION GATEWAY =========================
if [ "$UPLOAD_PLAYSTORE" = true ] || [ "$UPLOAD_APPSTORE" = true ] || [ "$UPLOAD_GDRIVE" = true ] || [ "$UPLOAD_DIAWI" = true ]; then
    CURRENT_STEP=$(( CURRENT_STEP + 1 ))
    draw_step_header $CURRENT_STEP $TOTAL_STEPS "Gateway Store Distribution Pipeline"

    # Android Play Store Internal Track Upload
    if [ "$IS_ANDROID" = true ] && [ "$UPLOAD_PLAYSTORE" = true ]; then
        upload_artifact="${FINAL_AAB_PATH:-$FINAL_APK_PATH}"
        if [ -z "$upload_artifact" ] || [ ! -f "$upload_artifact" ]; then
            print_error_card "Missing Artifact" "No Android artifact found to upload to Google Play." ""
            exit 1
        fi
        if command -v fastlane &> /dev/null; then
            flag="--aab"
            [[ "$upload_artifact" == *.apk ]] && flag="--apk"

            fastlane supply --package_name "$ANDROID_PACKAGE_NAME" "$flag" "$upload_artifact" --track "internal" --json_key "$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON" > "$LOG_TEMP" 2>&1 &
            spin_engine $! "Distributing binary artifact to Google Play Internal Track" "$LOG_TEMP"
        else
            print_error_card "Missing Tool" "'fastlane' command not found. Install fastlane via 'brew install fastlane'." ""
            exit 1
        fi
    fi

    # iOS App Store / TestFlight Upload
    if [ "$IS_IOS" = true ] && [ "$UPLOAD_APPSTORE" = true ]; then
        if [ -z "$FINAL_IPA_PATH" ] || [ ! -f "$FINAL_IPA_PATH" ]; then
            print_error_card "Missing Artifact" "No iOS .ipa artifact found to upload to TestFlight." ""
            exit 1
        fi
        if command -v xcrun &> /dev/null; then
            xcrun altool --upload-app --type ios -f "$FINAL_IPA_PATH" --apiKey "$APPLE_API_KEY_ID" --apiIssuer "$APPLE_API_ISSUER_ID" --apiKeyPath "$APPLE_API_KEY_PATH" > "$LOG_TEMP" 2>&1 &
            spin_engine $! "Distributing signed iOS binary payload asset directly to TestFlight" "$LOG_TEMP"
        else
            print_error_card "Missing Tool" "'xcrun' command not found. Xcode command line tools are required for App Store upload." ""
            exit 1
        fi
    fi

    # Google Drive Upload (APK only)
    if [ "$IS_ANDROID" = true ] && [ "$UPLOAD_GDRIVE" = true ]; then
        if [ -z "$FINAL_APK_PATH" ] || [ ! -f "$FINAL_APK_PATH" ]; then
            print_error_card "Missing Artifact" "No Android APK found to upload to Google Drive." ""
            exit 1
        fi
        # Check and Auto-Install GWS
        if ! command -v gws &> /dev/null; then
            echo -e "  ${INFO} 'gws' CLI not found. Installing via npm..."
            if command -v npm &> /dev/null; then
                npm install -g @googleworkspace/cli > "$LOG_TEMP" 2>&1
                if ! command -v gws &> /dev/null; then
                    print_error_card "Installation Failed" "Failed to install @googleworkspace/cli automatically. Please run 'npm install -g @googleworkspace/cli' manually." "$LOG_TEMP"
                    exit 1
                fi
                echo -e "  ${TICK} Successfully installed 'gws' CLI.\n"
            else
                print_error_card "Missing Tool" "'npm' is required to auto-install gws. Please install Node.js/npm or install gws manually." ""
                exit 1
            fi
        fi

        # Verify authentication session before backgrounding
        if ! gws drive about get --params '{"fields":"user"}' > /dev/null 2>&1; then
            echo -e "\n  ${WARN} Google Drive session expired or not configured."
            
            # Check if the OAuth client is configured. If not, run the one-time setup.
            if [ ! -f "$HOME/.config/gws/client_secret.json" ] && [ -z "$GOOGLE_WORKSPACE_CLI_CLIENT_ID" ]; then
                echo -e "  ${INFO} No OAuth client detected. Launching one-time Google Workspace Setup..."
                echo -e "  ${DIM}(Note: This requires the 'gcloud' CLI to be installed)${NC}\n"
                gws auth setup
            else
                echo -e "  ${INFO} Launching interactive authentication... Please complete the login in your browser.\n"
                gws auth login -s drive
            fi
            
            if ! gws drive about get --params '{"fields":"user"}' > /dev/null 2>&1; then
                echo -e "\n  ${CROSS} Authentication Failed: Missing scopes or cancelled consent."
                echo -e "  ${INFO} To reset your Google Workspace CLI configuration and start over, run:"
                echo -e "         ${BOLD}rm -rf ~/.config/gws${NC}"
                print_error_card "Authentication Failed" "Google Drive authentication was not completed successfully (likely missing permissions). Run 'rm -rf ~/.config/gws' to reset." ""
                exit 1
            fi
            echo -e "  ${TICK} Authentication successful. Proceeding with upload...\n"
        fi

        filename=$(basename "$FINAL_APK_PATH")
        gws drive files create --upload "$FINAL_APK_PATH" --json "{\"name\": \"$filename\", \"parents\": [\"$GDRIVE_BASE_FOLDER_ID\"]}" > "/tmp/gdrive_out_$$" 2>&1 &
        spin_engine $! "Uploading APK to Google Drive folder: $GDRIVE_BASE_FOLDER_ID" "/tmp/gdrive_out_$$"
        
        G_ID=$(cat "/tmp/gdrive_out_$$" | grep -o '"id": "[^"]*' | grep -o '[^"]*$' || true)
        if [ -n "$G_ID" ]; then
            echo -e "     ${ARROW} Google Drive Link: ${BOLD}${CYAN}https://drive.google.com/file/d/${G_ID}/view${NC}"
        fi
        rm -f "/tmp/gdrive_out_$$"
    fi

    # Diawi Upload (IPA only)
    if [ "$UPLOAD_DIAWI" = true ]; then
        UPLOAD_FILE_PATH=""
        if [ "$IS_IOS" = true ] && [ -n "$FINAL_IPA_PATH" ] && [ -f "$FINAL_IPA_PATH" ]; then
            UPLOAD_FILE_PATH="$FINAL_IPA_PATH"
        fi
        
        if [ -z "$UPLOAD_FILE_PATH" ]; then
            print_error_card "Missing Artifact" "No artifact found to upload to Diawi." ""
            exit 1
        fi
        echo -e "  ${INFO} Uploading binary to Diawi..."
        
        UPLOAD_RESPONSE=""
        UPLOAD_RESPONSE=$(curl -s -X POST https://upload.diawi.com/ \
            -F token="${DIAWI_TOKEN}" \
            -F file=@"${UPLOAD_FILE_PATH}" \
            -F comment="Automated Build Release")
        JOB_TOKEN=$(echo "$UPLOAD_RESPONSE" | grep -o '"job":"[^"]*' | grep -o '[^"]*$')
        if [ -z "$JOB_TOKEN" ]; then
            echo ""
            echo -e "  ${WARN} ${YELLOW}Diawi Upload Skipped:${NC} ${DIM}$UPLOAD_RESPONSE${NC}"
            echo -e "  ${INFO} The APK/IPA is likely too large for Diawi's free tier (50MB limit)."
            echo -e "  ${INFO} Your build was successfully created and saved locally."
            
            # Skip the rest of Diawi logic but don't crash the pipeline
            UPLOAD_DIAWI=false
        else
        
        echo -e "  ${INFO} Upload initiated. Job Token: $JOB_TOKEN"
        
        (
            ATTEMPT=1
            while [ $ATTEMPT -le 30 ]; do
                STATUS_RESPONSE=$(curl -s -G https://upload.diawi.com/status -d token="${DIAWI_TOKEN}" -d job="${JOB_TOKEN}")
                STATUS_CODE=$(echo "$STATUS_RESPONSE" | grep -o '"status":[0-9]*' | grep -o '[0-9]*')
                case "$STATUS_CODE" in
                    1) sleep 5; ((ATTEMPT++));;
                    2) 
                        FINAL_LINK=$(echo "$STATUS_RESPONSE" | grep -o '"link":"[^"]*' | grep -o '[^"]*$' | sed 's/\\//g')
                        echo "$FINAL_LINK" > "/tmp/diawi_link_$$"
                        exit 0;;
                    *) exit 1;;
                esac
            done
            exit 1
        ) > "$LOG_TEMP" 2>&1 &
        spin_engine $! "Processing Diawi App deployment" "$LOG_TEMP"
        
        if [ -f "/tmp/diawi_link_$$" ]; then
            DIAWI_LINK=$(cat "/tmp/diawi_link_$$")
            echo -e "     ${ARROW} Diawi Link: ${BOLD}${CYAN}${DIAWI_LINK}${NC}"
            rm -f "/tmp/diawi_link_$$"
        fi
        fi
    fi


fi

# ========================= 17. FINAL EXECUTION SUMMARY =========================
END_TOTAL_TIME=$(date +%s)
TOTAL_DIFF=$(( END_TOTAL_TIME - START_TOTAL_TIME ))
TOTAL_MINS=$(( TOTAL_DIFF / 60 ))
TOTAL_SECS=$(( TOTAL_DIFF % 60 ))
TOTAL_DURATION=$(printf "%02dm %02ds" "$TOTAL_MINS" "$TOTAL_SECS")

echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║${NC}   ${BOLD}${WHITE}🎉 PIPELINE SUITE EXECUTED SUCCESSFULLY${NC}                         ${BOLD}${GREEN}║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
draw_line
echo -e "  ${DOT} ${BOLD}Total Pipeline Duration:${NC}  ${YELLOW}${TOTAL_DURATION}${NC}"

if [ -n "$FINAL_APK_PATH" ] && [ -f "$FINAL_APK_PATH" ]; then
    echo -e "  ${DOT} ${BOLD}Android APK:${NC}              ${GREEN}${FINAL_APK_PATH}${NC} ${DIM}(${FINAL_APK_SIZE})${NC}"
fi

if [ -n "$FINAL_AAB_PATH" ] && [ -f "$FINAL_AAB_PATH" ]; then
    echo -e "  ${DOT} ${BOLD}Android AppBundle:${NC}        ${GREEN}${FINAL_AAB_PATH}${NC} ${DIM}(${FINAL_AAB_SIZE})${NC}"
fi

if [ -n "$FINAL_IPA_PATH" ] && [ -f "$FINAL_IPA_PATH" ]; then
    echo -e "  ${DOT} ${BOLD}iOS Signed IPA:${NC}           ${GREEN}${FINAL_IPA_PATH}${NC} ${DIM}(${FINAL_IPA_SIZE})${NC}"
fi

if [ -n "$FINAL_IOS_ARCHIVE" ] && [ -d "$FINAL_IOS_ARCHIVE" ]; then
    echo -e "  ${DOT} ${BOLD}iOS Unsigned Archive:${NC}     ${GREEN}${FINAL_IOS_ARCHIVE}${NC}"
fi

if [ "$IS_IOS" = true ] && [ "$BUILD_IPA" = true ] && [ "$NOSIGN" = true ]; then
    if [ -d "build/ios/archive/Runner.xcarchive" ]; then
        echo -e "\n  ${INFO} Launching Xcode Organizer for manual archive distribution..."
        open "build/ios/archive/Runner.xcarchive"
    fi
fi

draw_line
echo ""

rm -f "$LOG_TEMP"
show_cursor