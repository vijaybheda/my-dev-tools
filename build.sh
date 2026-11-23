#!/bin/bash

# ==============================================================================
#  WASHY — MOBILE BUILD & RELEASE ENGINE
#  A unified, interactive, and automated compilation & distribution CLI tool.
#  Inspired by MiMoCode CLI UI/UX with Session Memory & Smart Prefilled Versions.
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
FLASH="${YELLOW}⚡${NC}"
BOX_CHECK="${GREEN}[✔]${NC}"
BOX_UNCHECK="${GRAY}[ ]${NC}"

# ========================= 2. CORE CONFIGURATION & STATE =========================
APP_TITLE="Washy"
PREFIX="WASHY"
OUTPUT_DIR="output"
IOS_DIR="${OUTPUT_DIR}/ios"
ANDROID_DIR="${OUTPUT_DIR}/android"
TIMESTAMP=$(date +"%I-%M_%p_%d_%b")
SESSION_FILE=".build_last_session.conf"

# Flavor Matrix Configuration
HAS_FLAVORS=true
VALID_FLAVORS=("dev" "staging" "prod" "ngrok")
FLAVOR="dev"

# Active Execution Flags & Defaults
FLAVOR_SET_VIA_CLI=false
IS_WIZARD_RUN=false

BUILD_APK=false
BUILD_AAB=false
BUILD_IPA=false
NOSIGN=false
UPLOAD_PLAYSTORE=false
UPLOAD_APPSTORE=false
UPLOAD_GDRIVE=false
UPLOAD_DIAWI=false
RUN_CLEAN=true
DRY_RUN=false
VERBOSE=false
FORCE_INTERACTIVE=false

CLI_ANDROID_VERSION=""
CLI_IOS_VERSION=""
CLI_GENERIC_VERSION=""

# Session Memory Variables
HAS_SAVED_SESSION=false
LAST_FLAVOR=""
LAST_BUILD_APK=false
LAST_BUILD_AAB=false
LAST_BUILD_IPA=false
LAST_NOSIGN=false
LAST_UPLOAD_PLAYSTORE=false
LAST_UPLOAD_GDRIVE=false
LAST_UPLOAD_APPSTORE=false
LAST_UPLOAD_DIAWI=false
LAST_ANDROID_VERSION=""
LAST_IOS_VERSION=""
LAST_SESSION_TIME=""

# ----------------- CREDENTIALS & CONFIG -----------------
CONFIG_FILE=".build-config.env"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${WARN} ${YELLOW}No .build-config.env found! Generating template with project defaults...${NC}"
    cat << 'EOF' > "$CONFIG_FILE"
# ==============================================================================
#  WASHY BUILD ENGINE CONFIGURATION
#  Fill this out with your project-specific credentials before running release builds.
# ==============================================================================

# App Identifiers
IOS_BUNDLE_ID="com.washy.app"
ANDROID_PACKAGE_NAME="com.washy.app"

# Apple App Store Connect API Key (.p8)
APPLE_API_KEY_ID="H695N6SGJB"
APPLE_API_ISSUER_ID="YOUR_ISSUER_UUID"

# Google Play Service Account (Place JSON in output/secret/ or private_keys/)
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="output/secret/google-play-service-account.json"

# Distribution Gateways
GDRIVE_BASE_FOLDER_ID="1V1K_A5xqq_d8hKd6du7_g9dbZsdD-qm-"
DIAWI_TOKEN="QvbO1Z7iOng4yO43gaRuvW8PUTBifZ6KPoLo5FCtp2"
EOF
    echo -e "${INFO} Generated ${BOLD}${CONFIG_FILE}${NC}.\n"
fi

# Load Config
set -a
source "$CONFIG_FILE"
set +a

# Auto-detect keys in private_keys/ or output/secret/ if missing
APPLE_API_KEY_PATH="output/secret/AuthKey_${APPLE_API_KEY_ID}.p8"
if [ ! -f "$APPLE_API_KEY_PATH" ]; then
    DETECTED_P8=$(find private_keys output/secret . -maxdepth 2 -name "AuthKey_*.p8" 2>/dev/null | head -n 1)
    [ -n "$DETECTED_P8" ] && APPLE_API_KEY_PATH="$DETECTED_P8"
fi

if [ ! -f "$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON" ]; then
    DETECTED_JSON=$(find private_keys output/secret . -maxdepth 2 -name "*service-account*.json" -o -name "google-play*.json" 2>/dev/null | head -n 1)
    [ -n "$DETECTED_JSON" ] && GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="$DETECTED_JSON"
fi

# Artifact Tracking
FINAL_APK_PATH=""
FINAL_APK_SIZE=""
FINAL_AAB_PATH=""
FINAL_AAB_SIZE=""
FINAL_IPA_PATH=""
FINAL_IPA_SIZE=""
FINAL_IOS_ARCHIVE=""

# Toolchain Detection (FVM priority per SOP)
FLUTTER_CMD="flutter"
if command -v fvm &> /dev/null; then
    FLUTTER_CMD="fvm flutter"
fi

PUBSPEC_FILE="pubspec.yaml"
LOG_TEMP="/tmp/washy_build_$(date +%s)_$$.log"
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
    echo -e "\n\n  ${WARN} ${YELLOW}Deployment process cancelled by operator.${NC}\n"
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

# ========================= 4. SESSION MEMORY PERSISTENCE ENGINE =========================
load_session_state() {
    if [ -f "$SESSION_FILE" ]; then
        HAS_SAVED_SESSION=true
        LAST_FLAVOR=$(grep '^LAST_FLAVOR=' "$SESSION_FILE" | cut -d'=' -f2 | tr -d '"')
        LAST_BUILD_APK=$(grep '^LAST_BUILD_APK=' "$SESSION_FILE" | cut -d'=' -f2 | tr -d '"')
        LAST_BUILD_AAB=$(grep '^LAST_BUILD_AAB=' "$SESSION_FILE" | cut -d'=' -f2 | tr -d '"')
        LAST_BUILD_IPA=$(grep '^LAST_BUILD_IPA=' "$SESSION_FILE" | cut -d'=' -f2 | tr -d '"')
        LAST_NOSIGN=$(grep '^LAST_NOSIGN=' "$SESSION_FILE" | cut -d'=' -f2 | tr -d '"')
        LAST_UPLOAD_PLAYSTORE=$(grep '^LAST_UPLOAD_PLAYSTORE=' "$SESSION_FILE" | cut -d'=' -f2 | tr -d '"')
        LAST_UPLOAD_GDRIVE=$(grep '^LAST_UPLOAD_GDRIVE=' "$SESSION_FILE" | cut -d'=' -f2 | tr -d '"')
        LAST_UPLOAD_APPSTORE=$(grep '^LAST_UPLOAD_APPSTORE=' "$SESSION_FILE" | cut -d'=' -f2 | tr -d '"')
        LAST_UPLOAD_DIAWI=$(grep '^LAST_UPLOAD_DIAWI=' "$SESSION_FILE" | cut -d'=' -f2 | tr -d '"')
        LAST_ANDROID_VERSION=$(grep '^LAST_ANDROID_VERSION=' "$SESSION_FILE" | cut -d'=' -f2 | tr -d '"')
        LAST_IOS_VERSION=$(grep '^LAST_IOS_VERSION=' "$SESSION_FILE" | cut -d'=' -f2 | tr -d '"')
        LAST_SESSION_TIME=$(grep '^LAST_SESSION_TIME=' "$SESSION_FILE" | cut -d'=' -f2 | tr -d '"')
    fi
}

save_session_state() {
    cat << EOF > "$SESSION_FILE"
# Saved Deployment Engine State
LAST_FLAVOR="${FLAVOR}"
LAST_BUILD_APK="${BUILD_APK}"
LAST_BUILD_AAB="${BUILD_AAB}"
LAST_BUILD_IPA="${BUILD_IPA}"
LAST_NOSIGN="${NOSIGN}"
LAST_UPLOAD_PLAYSTORE="${UPLOAD_PLAYSTORE}"
LAST_UPLOAD_GDRIVE="${UPLOAD_GDRIVE}"
LAST_UPLOAD_APPSTORE="${UPLOAD_APPSTORE}"
LAST_UPLOAD_DIAWI="${UPLOAD_DIAWI}"
LAST_ANDROID_VERSION="${CLI_ANDROID_VERSION}"
LAST_IOS_VERSION="${CLI_IOS_VERSION}"
LAST_SESSION_TIME="$(date +'%Y-%m-%d %H:%M:%S')"
EOF
}

load_session_state

# ========================= 5. WELCOME BANNER =========================
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
    echo -e "${DIM}  ❖ Washy — Mobile Compilation & Release CLI Engine${NC}"
    echo -e "  ${DIM}Branch:${NC} ${CYAN}${git_branch:-main}${NC}  ${DIM}•${NC}  ${DIM}Toolchain:${NC} ${GREEN}${FLUTTER_CMD} (${flutter_ver})${NC}  ${DIM}•${NC}  ${DIM}Time:${NC} ${YELLOW}${TIMESTAMP}${NC}"
    draw_line
    echo ""
}

# ========================= 6. STEP PROGRESS HEADER =========================
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

# ========================= 7. ANIMATED SPINNER ENGINE =========================
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

# ========================= 8. HUMAN DIAGNOSTIC ERROR CARDS =========================
print_error_card() {
    local title=$1
    local cause=$2
    local logfile=$3

    show_cursor
    [ -t 0 ] && stty echo 2>/dev/null
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}${RED}✘ PIPELINE EXECUTION ERROR: ${title}${NC}"
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

        if grep -qi "pod" "$logfile" 2>/dev/null || grep -qi "CocoaPods" "$logfile" 2>/dev/null; then
            quick_fix="Run 'cd ios && pod install --repo-update && cd ..' to refresh CocoaPods."
        elif grep -qi "keystore" "$logfile" 2>/dev/null || grep -qi "signing" "$logfile" 2>/dev/null; then
            quick_fix="Check android/key.properties or signing configuration in android/app/build.gradle.kts."
        elif grep -qi "AuthKey" "$logfile" 2>/dev/null || grep -qi "altool" "$logfile" 2>/dev/null; then
            quick_fix="Verify Apple API Key ID, Issuer ID, and .p8 file path in .build-config.env or private_keys/."
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

# ========================= 9. INTERACTIVE MENU ENGINES =========================
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

# ========================= 10. PREFILLED & EDITABLE VERSION PROMPT =========================
read_editable_line() {
    local prompt_text="$1"
    local initial_val="$2"
    local result_var="$3"

    local buffer="$initial_val"
    local pos=${#buffer}

    show_cursor
    printf "%b" "$prompt_text"
    printf "%s" "$buffer"

    while true; do
        local char=""
        local rest=""
        IFS= read -r -s -n 1 char 2>/dev/null
        if [[ "$char" == $'\033' ]]; then
            read -r -s -n 2 -t 1 rest 2>/dev/null
            case "$rest" in
                "[D")
                    if [ $pos -gt 0 ]; then
                        pos=$((pos - 1))
                        printf "\033[D"
                    fi
                    ;;
                "[C")
                    if [ $pos -lt ${#buffer} ]; then
                        pos=$((pos + 1))
                        printf "\033[C"
                    fi
                    ;;
            esac
        elif [[ -z "$char" || "$char" == $'\n' || "$char" == $'\r' ]]; then
            echo ""
            break
        elif [[ "$char" == $'\177' || "$char" == $'\b' ]]; then
            if [ $pos -gt 0 ]; then
                local left="${buffer:0:$((pos-1))}"
                local right="${buffer:$pos}"
                buffer="${left}${right}"
                pos=$((pos - 1))
                printf "\033[D\033[K%s" "$right"
                local right_len=${#right}
                if [ $right_len -gt 0 ]; then
                    printf "\033[%dD" "$right_len"
                fi
            fi
        else
            local left="${buffer:0:$pos}"
            local right="${buffer:$pos}"
            buffer="${left}${char}${right}"
            pos=$((pos + 1))
            printf "%s%s" "$char" "$right"
            local right_len=${#right}
            if [ $right_len -gt 0 ]; then
                printf "\033[%dD" "$right_len"
            fi
        fi
    done
    eval "$result_var=\"$buffer\""
    hide_cursor
}

increment_build_number() {
    local v_str="$1"
    if [[ "$v_str" == *"+"* ]]; then
        local name="${v_str%+*}"
        local code="${v_str#*+}"
        if [[ "$code" =~ ^[0-9]+$ ]]; then
            local next_code=$((code + 1))
            echo "${name}+${next_code}"
            return
        fi
    fi
    echo "$v_str"
}

prompt_editable_version() {
    local label=$1
    local default_val=$2
    local target_var=$3

    local inc_val
    inc_val=$(increment_build_number "$default_val")

    echo -e "  ${INFO} ${BOLD}${label}${NC} ${DIM}(Detected baseline: ${CYAN}${default_val}${DIM})${NC}\n"

    local version_action_opts=(
        "Keep current baseline version (${default_val})"
        "Auto-increment build number (${inc_val})"
        "Edit custom version string"
    )

    menu_single_select "Choose version configuration for ${label}:" 0 "${version_action_opts[@]}"

    case "$MENU_RESULT" in
        0)
            eval "$target_var=\"$default_val\""
            echo -e "     ${TICK} Selected version: ${BOLD}${CYAN}${default_val}${NC}\n"
            ;;
        1)
            eval "$target_var=\"$inc_val\""
            echo -e "     ${FLASH} ${GREEN}Auto-incremented version: ${BOLD}${inc_val}${NC}\n"
            ;;
        2)
            while true; do
                local custom_val=""
                read_editable_line "     ${ARROW} Enter custom version: " "$default_val" custom_val
                if [[ "$custom_val" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?\+[0-9]+$ ]]; then
                    eval "$target_var=\"$custom_val\""
                    echo -e "     ${TICK} Selected version: ${BOLD}${CYAN}${custom_val}${NC}\n"
                    break
                else
                    echo -e "     ${CROSS} ${RED}Invalid format '${custom_val}'. Expected: <version>+<build> (e.g. 1.0.0+2)${NC}"
                fi
            done
            ;;
    esac
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

# ========================= 11. INTERACTIVE WIZARD & FAST-TRACK FLOW =========================
run_interactive_wizard() {
    IS_WIZARD_RUN=true
    print_welcome_banner

    if [ "$HAS_SAVED_SESSION" = true ]; then
        echo -e "${BOLD}${YELLOW}⚡ LAST BUILD SESSION DETECTED (${LAST_SESSION_TIME})${NC}"
        draw_line
        echo -e "  ${DOT} ${BOLD}Environment Flavor:${NC}  ${CYAN}${LAST_FLAVOR}${NC}"

        local saved_plats=""
        [ "$LAST_BUILD_APK" = true ] && saved_plats="${saved_plats}APK "
        [ "$LAST_BUILD_AAB" = true ] && saved_plats="${saved_plats}AAB "
        [ "$LAST_BUILD_IPA" = true ] && [ "$LAST_NOSIGN" = false ] && saved_plats="${saved_plats}IPA "
        [ "$LAST_BUILD_IPA" = true ] && [ "$LAST_NOSIGN" = true ] && saved_plats="${saved_plats}IPA(Unsigned) "
        echo -e "  ${DOT} ${BOLD}Platforms:${NC}           ${GREEN}${saved_plats:-None}${NC}"

        local saved_uploads=""
        [ "$LAST_UPLOAD_PLAYSTORE" = true ] && saved_uploads="${saved_uploads}Google Play Store, "
        [ "$LAST_UPLOAD_GDRIVE" = true ] && saved_uploads="${saved_uploads}Google Drive, "
        [ "$LAST_UPLOAD_APPSTORE" = true ] && saved_uploads="${saved_uploads}TestFlight, "
        [ "$LAST_UPLOAD_DIAWI" = true ] && saved_uploads="${saved_uploads}Diawi, "
        saved_uploads="${saved_uploads%, }"
        [ -z "$saved_uploads" ] && saved_uploads="Local Build Only"
        echo -e "  ${DOT} ${BOLD}Distribution:${NC}        ${MAGENTA}${saved_uploads}${NC}"
        draw_line
        echo ""

        local session_mode_opts=(
            "Fast Deploy (Rerun Last Session configuration)"
            "Interactive Wizard (Customize options)"
        )
        menu_single_select "Choose execution mode:" 0 "${session_mode_opts[@]}"

        if [ "$MENU_RESULT" -eq 0 ]; then
            FLAVOR="$LAST_FLAVOR"
            BUILD_APK="$LAST_BUILD_APK"
            BUILD_AAB="$LAST_BUILD_AAB"
            BUILD_IPA="$LAST_BUILD_IPA"
            NOSIGN="$LAST_NOSIGN"
            UPLOAD_PLAYSTORE="$LAST_UPLOAD_PLAYSTORE"
            UPLOAD_GDRIVE="$LAST_UPLOAD_GDRIVE"
            UPLOAD_APPSTORE="$LAST_UPLOAD_APPSTORE"
            UPLOAD_DIAWI="$LAST_UPLOAD_DIAWI"

            local target_android=false
            local target_ios=false
            [ "$BUILD_APK" = true ] || [ "$BUILD_AAB" = true ] && target_android=true
            [ "$BUILD_IPA" = true ] && target_ios=true

            local pub_android_ver=""
            [ -f "$PUBSPEC_FILE" ] && pub_android_ver=$(grep -E '^version:' "$PUBSPEC_FILE" | head -n 1 | awk '{print $NF}')
            local pub_ios_ver=""
            [ -f "$PUBSPEC_FILE" ] && pub_ios_ver=$(grep -E '^version:' "$PUBSPEC_FILE" | head -n 1 | awk '{print $NF}')

            local def_android_ver="${LAST_ANDROID_VERSION:-${pub_android_ver:-1.0.0+1}}"
            local def_ios_ver="${LAST_IOS_VERSION:-${pub_ios_ver:-1.0.0+1}}"

            echo ""
            echo -e "${BOLD}${CYAN}❖ Confirm / Update Platform Versions${NC}\n"
            if [ "$target_android" = true ]; then
                prompt_editable_version "Android Version" "$def_android_ver" CLI_ANDROID_VERSION
            fi
            if [ "$target_ios" = true ]; then
                prompt_editable_version "iOS Version" "$def_ios_ver" CLI_IOS_VERSION
            fi

            save_session_state
            return 0
        fi
    fi

    # Step 1: Select Flavor
    if [ "$HAS_FLAVORS" = true ] && [ ${#VALID_FLAVORS[@]} -gt 0 ]; then
        echo -e "${BOLD}${CYAN}❖ Step 1: Select Environment Flavor Variant${NC}\n"
        local default_flavor_idx=0
        for ((f=0; f<${#VALID_FLAVORS[@]}; f++)); do
            [ "${VALID_FLAVORS[f]}" = "$LAST_FLAVOR" ] && default_flavor_idx=$f
        done

        menu_single_select "Choose target environment flavor:" $default_flavor_idx "${VALID_FLAVORS[@]}"
        FLAVOR="${VALID_FLAVORS[$MENU_RESULT]}"
        echo -e "  ${TICK} Selected Flavor: ${BOLD}${CYAN}${FLAVOR}${NC}\n"
    fi

    # Step 2: Select Platforms
    echo -e "${BOLD}${CYAN}❖ Step 2: Select Compilation Platform Packages (${FLAVOR})${NC}\n"
    local platform_opts=(
        "Android APK (Testing / Direct Device Install)"
        "Android App Bundle (AAB - Google Play Store)"
        "iOS IPA (App Store Connect / TestFlight)"
        "iOS Unsigned Archive (Xcode Organizer / No-codesign)"
    )

    local plat_csv="0,2"
    if [ "$HAS_SAVED_SESSION" = true ]; then
        plat_csv=""
        [ "$LAST_BUILD_APK" = true ] && plat_csv="${plat_csv}0,"
        [ "$LAST_BUILD_AAB" = true ] && plat_csv="${plat_csv}1,"
        [ "$LAST_BUILD_IPA" = true ] && [ "$LAST_NOSIGN" = false ] && plat_csv="${plat_csv}2,"
        [ "$LAST_BUILD_IPA" = true ] && [ "$LAST_NOSIGN" = true ] && plat_csv="${plat_csv}3,"
        plat_csv="${plat_csv%,}"
        [ -z "$plat_csv" ] && plat_csv="0,2"
    fi

    menu_multi_select "Choose platforms to compile:" "$plat_csv" "${platform_opts[@]}"

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

    local target_android=false
    local target_ios=false
    [ "$BUILD_APK" = true ] || [ "$BUILD_AAB" = true ] && target_android=true
    [ "$BUILD_IPA" = true ] && target_ios=true

    local pub_ver=""
    [ -f "$PUBSPEC_FILE" ] && pub_ver=$(grep -E '^version:' "$PUBSPEC_FILE" | head -n 1 | awk '{print $NF}')

    local def_android_ver="${LAST_ANDROID_VERSION:-${pub_ver:-1.0.0+1}}"
    local def_ios_ver="${LAST_IOS_VERSION:-${pub_ver:-1.0.0+1}}"

    echo ""
    echo -e "${BOLD}${CYAN}❖ Step 3: Platform Version Configurations${NC}\n"

    if [ "$target_android" = true ]; then
        prompt_editable_version "Android Version" "$def_android_ver" CLI_ANDROID_VERSION
    else
        echo -e "  ${DIM}ℹ Skipping Android version input (Android platform not selected).${NC}"
    fi

    if [ "$target_ios" = true ]; then
        prompt_editable_version "iOS Version" "$def_ios_ver" CLI_IOS_VERSION
    else
        echo -e "  ${DIM}ℹ Skipping iOS version input (iOS platform not selected).${NC}"
    fi

    # Step 4: Upload Gateways
    echo ""
    echo -e "${BOLD}${CYAN}❖ Step 4: Distribution & Store Gateways${NC}\n"

    local upload_opts=()
    local upload_mappings=()
    local upload_defaults_csv=""

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

    if [ "$HAS_SAVED_SESSION" = true ]; then
        for ((k=0; k<${#upload_mappings[@]}; k++)); do
            m="${upload_mappings[$k]}"
            if [ "$m" = "playstore" ] && [ "$LAST_UPLOAD_PLAYSTORE" = true ]; then upload_defaults_csv="${upload_defaults_csv}${k},"; fi
            if [ "$m" = "gdrive" ] && [ "$LAST_UPLOAD_GDRIVE" = true ]; then upload_defaults_csv="${upload_defaults_csv}${k},"; fi
            if [ "$m" = "appstore" ] && [ "$LAST_UPLOAD_APPSTORE" = true ]; then upload_defaults_csv="${upload_defaults_csv}${k},"; fi
            if [ "$m" = "diawi" ] && [ "$LAST_UPLOAD_DIAWI" = true ]; then upload_defaults_csv="${upload_defaults_csv}${k},"; fi
        done
        upload_defaults_csv="${upload_defaults_csv%,}"
    fi
    [ -z "$upload_defaults_csv" ] && upload_defaults_csv="0"

    UPLOAD_PLAYSTORE=false
    UPLOAD_APPSTORE=false
    UPLOAD_GDRIVE=false
    UPLOAD_DIAWI=false

    if [ ${#upload_opts[@]} -gt 1 ]; then
        menu_multi_select "Select automated release distribution destinations:" "$upload_defaults_csv" "${upload_opts[@]}"

        for ((k=0; k<${#upload_mappings[@]}; k++)); do
            if [ "${MULTI_MENU_RESULTS[k]}" -eq 1 ]; then
                local sel_target="${upload_mappings[$k]}"
                if [ "$sel_target" = "playstore" ]; then
                    UPLOAD_PLAYSTORE=true
                    [ "$BUILD_AAB" = false ] && [ "$BUILD_APK" = false ] && BUILD_AAB=true
                elif [ "$sel_target" = "gdrive" ]; then
                    UPLOAD_GDRIVE=true
                    [ "$BUILD_APK" = false ] && BUILD_APK=true
                elif [ "$sel_target" = "appstore" ]; then
                    UPLOAD_APPSTORE=true
                    [ "$BUILD_IPA" = false ] && BUILD_IPA=true
                elif [ "$sel_target" = "diawi" ]; then
                    UPLOAD_DIAWI=true
                    [ "$BUILD_IPA" = false ] && BUILD_IPA=true
                fi
            fi
        done
    else
        echo -e "  ${INFO} Skipping store gateways (Unsigned / Local build selected)."
    fi

    echo ""
    draw_line
    echo -e "${BOLD}${WHITE}📋 Pre-Flight Deployment Summary${NC}"
    draw_line
    echo -e "  ${DOT} ${BOLD}App:${NC}                 ${WHITE}${APP_TITLE}${NC} (${PREFIX})"
    echo -e "  ${DOT} ${BOLD}Native Flavor:${NC}       ${CYAN}${FLAVOR}${NC}"

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

    local upload_summary_arr=()
    [ "$UPLOAD_PLAYSTORE" = true ] && upload_summary_arr+=("Google Play Console")
    [ "$UPLOAD_GDRIVE" = true ] && upload_summary_arr+=("Google Drive")
    [ "$UPLOAD_APPSTORE" = true ] && upload_summary_arr+=("TestFlight")
    [ "$UPLOAD_DIAWI" = true ] && upload_summary_arr+=("Diawi")

    local upload_summary="Local Only"
    if [ ${#upload_summary_arr[@]} -gt 0 ]; then
        upload_summary=$(IFS=', '; echo "${upload_summary_arr[*]}")
    fi
    echo -e "  ${DOT} ${BOLD}Distribution:${NC}      ${MAGENTA}${upload_summary}${NC}"
    echo -e "  ${DOT} ${BOLD}Sanitation:${NC}        ${WHITE}Clean & Pub Get${NC}"
    draw_line
    echo ""

    local confirm_run=true
    prompt_confirm_yn "Ready to proceed with deployment pipeline?" "y" confirm_run
    if [ "$confirm_run" = false ]; then
        echo -e "\n  ${WARN} ${YELLOW}Deployment cancelled by operator.${NC}\n"
        exit 0
    fi

    save_session_state
}

# ========================= 12. HELP MANUAL =========================
usage() {
    show_cursor
    print_welcome_banner
    echo -e "${BOLD}${WHITE}USAGE:${NC}"
    echo -e "  ${CYAN}./build.sh${NC}                    Launch interactive wizard / session fast-track ${DIM}(Default)${NC}"
    echo -e "  ${CYAN}./build.sh [options]${NC}          Execute in headless / CI/CD mode\n"

    echo -e "${BOLD}${WHITE}OPTIONS:${NC}"
    echo -e "  ${CYAN}-f, --flavor${NC} <flavor>     Target flavor: ${BOLD}dev, staging, prod, ngrok${NC}"
    echo -e "  ${CYAN}-p, --platform${NC} <targets> Target packages: ${BOLD}apk, appbundle, ipa, nosign${NC}"
    echo -e "  ${CYAN}-v, --version${NC} <versions>   Explicit versions: ${BOLD}a1.0.0+2${NC} (Android), ${BOLD}i1.0.0+9${NC} (iOS)"
    echo -e "  ${CYAN}-u, --upload${NC} <targets>    Distribution: ${BOLD}playstore, gdrive, appstore, diawi, none${NC}"
    echo -e "  ${CYAN}-i, --interactive${NC}         Force interactive wizard"
    echo -e "  ${CYAN}--no-clean${NC}                Skip workspace cleaning step (${FLUTTER_CMD} clean)"
    echo -e "  ${CYAN}--dry-run${NC}                 Validate configurations and paths without executing build"
    echo -e "  ${CYAN}-V, --verbose${NC}             Stream full compilation output directly to terminal"
    echo -e "  ${CYAN}-h, --help${NC}                Display this command manual\n"

    echo -e "${BOLD}${WHITE}EXAMPLES:${NC}"
    echo -e "  ${DIM}# Interactive wizard / fast session reload:${NC}"
    echo -e "  ${CYAN}./build.sh${NC}\n"
    echo -e "  ${DIM}# Build Android APK & iOS IPA for dev flavor:${NC}"
    echo -e "  ${CYAN}./build.sh -f dev -p apk ipa${NC}\n"
    echo -e "  ${DIM}# Build Production AAB & IPA and upload to both stores:${NC}"
    echo -e "  ${CYAN}./build.sh -f prod -p appbundle ipa -u playstore appstore -v a1.0.0+2 i1.0.0+9${NC}\n"
    exit 0
}

# ========================= 13. ARGUMENT PARSING =========================
if [ "$#" -eq 0 ]; then
    if [ -t 0 ] && [ -t 1 ]; then
        run_interactive_wizard
    else
        usage
    fi
else
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -f|--flavor|--env) shift
                if [[ -z "$1" || "$1" =~ ^- ]]; then
                    print_error_card "Invalid Argument" "Option -f/--flavor requires dev, staging, prod, or ngrok" ""
                    exit 1
                fi
                case $1 in
                    dev|staging|prod|ngrok)
                        FLAVOR="$1"
                        ;;
                    *)
                        print_error_card "Invalid Flavor" "Unknown flavor '$1'. Allowed: dev, staging, prod, ngrok" ""
                        exit 1 ;;
                esac
                FLAVOR_SET_VIA_CLI=true
                shift
                continue ;;
            -p|--platform) shift
                if [[ -z "$1" || "$1" =~ ^- ]]; then
                    print_error_card "Invalid Argument" "Option -p requires platform target (apk, appbundle, ipa, nosign)" ""
                    exit 1
                fi
                while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                    case $1 in
                        apk) BUILD_APK=true ;;
                        appbundle|aab) BUILD_AAB=true ;;
                        ipa) BUILD_IPA=true ;;
                        nosign) NOSIGN=true ;;
                        *)
                            print_error_card "Invalid Platform" "Unknown platform '$1'. Allowed: apk, appbundle, ipa, nosign" ""
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
                        print_error_card "Invalid Version Format" "Invalid version format '$1'. Expected: a1.0.0+2 or i1.0.0+9" ""
                        exit 1
                    fi
                    shift
                done
                continue ;;
            -u|--upload) shift
                if [[ -z "$1" || "$1" =~ ^- ]]; then
                    print_error_card "Invalid Argument" "Option -u requires distribution target (playstore, gdrive, appstore, diawi, none)" ""
                    exit 1
                fi
                while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                    case $1 in
                        playstore|googleplay) UPLOAD_PLAYSTORE=true ;;
                        gdrive|googledrive) UPLOAD_GDRIVE=true ;;
                        appstore|testflight) UPLOAD_APPSTORE=true ;;
                        diawi) UPLOAD_DIAWI=true ;;
                        none) ;;
                        *)
                            print_error_card "Invalid Upload Target" "Unknown target '$1'. Allowed: playstore, gdrive, appstore, diawi, none" ""
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

# ========================= 14. PARAMETER & SAFETY VALIDATION =========================
print_welcome_banner

if [ "$IS_WIZARD_RUN" = false ]; then
    if [ "$FLAVOR_SET_VIA_CLI" = false ] && [ "$FORCE_INTERACTIVE" = false ] && [ -t 0 ] && [ -t 1 ]; then
        if [ "$HAS_FLAVORS" = true ] && [ ${#VALID_FLAVORS[@]} -gt 0 ]; then
            menu_single_select "Choose target environment flavor:" 0 "${VALID_FLAVORS[@]}"
            FLAVOR="${VALID_FLAVORS[$MENU_RESULT]}"
        fi
    fi
fi

if [ "$BUILD_APK" = false ] && [ "$BUILD_AAB" = false ] && [ "$BUILD_IPA" = false ]; then
    print_error_card "Missing Platform Target" "You must specify at least one compilation platform (-p apk | appbundle | ipa | nosign)" ""
    exit 1
fi

IS_ANDROID=false
IS_IOS=false
[ "$BUILD_APK" = true ] || [ "$BUILD_AAB" = true ] || [ "$UPLOAD_PLAYSTORE" = true ] && IS_ANDROID=true
[ "$BUILD_IPA" = true ] || [ "$UPLOAD_APPSTORE" = true ] && IS_IOS=true

if [ "$UPLOAD_PLAYSTORE" = true ] && [ "$BUILD_APK" = false ] && [ "$BUILD_AAB" = false ]; then
    BUILD_AAB=true
fi
if [ "$UPLOAD_APPSTORE" = true ] && [ "$BUILD_IPA" = false ]; then
    BUILD_IPA=true
fi

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

# ========================= 15. SELECTIVE VERSION RESOLUTION =========================
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

if [ "$IS_ANDROID" = true ]; then
    ANDROID_RAW=$(grep -E '^version:' "$PUBSPEC_FILE" | head -n 1 | awk '{print $NF}')
    [ -z "$ANDROID_RAW" ] && ANDROID_RAW="$DEFAULT_PUB_VERSION"
    ANDROID_FINAL=${CLI_ANDROID_VERSION:-${CLI_GENERIC_VERSION:-${ANDROID_RAW}}}
    read ANDROID_NAME ANDROID_CODE <<< $(split_version "$ANDROID_FINAL")
    mkdir -p "${ANDROID_DIR}"
elif [ -n "$CLI_ANDROID_VERSION" ]; then
    echo -e "  ${DIM}ℹ Android version specified (${CLI_ANDROID_VERSION}) but no Android target selected — skipping Android versioning.${NC}"
fi

if [ "$IS_IOS" = true ]; then
    IOS_RAW=$(grep -E '^version:' "$PUBSPEC_FILE" | head -n 1 | awk '{print $NF}')
    [ -z "$IOS_RAW" ] && IOS_RAW="$DEFAULT_PUB_VERSION"
    IOS_FINAL=${CLI_IOS_VERSION:-${CLI_GENERIC_VERSION:-${IOS_RAW}}}
    read IOS_NAME IOS_CODE <<< $(split_version "$IOS_FINAL")
    mkdir -p "${IOS_DIR}"
elif [ -n "$CLI_IOS_VERSION" ]; then
    echo -e "  ${DIM}ℹ iOS version specified (${CLI_IOS_VERSION}) but no iOS target selected — skipping iOS versioning.${NC}"
fi

TOTAL_STEPS=2
[ "$UPLOAD_PLAYSTORE" = true ] || [ "$UPLOAD_APPSTORE" = true ] || [ "$UPLOAD_GDRIVE" = true ] || [ "$UPLOAD_DIAWI" = true ] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
CURRENT_STEP=1

echo -e "  ${TICK} Pre-flight parameters and environment profiles validated successfully."

save_session_state

if [ "$DRY_RUN" = true ]; then
    echo -e "\n${BOLD}${GREEN}✔ DRY RUN COMPLETE${NC} — All flags, version strings, session memory, and credentials validated cleanly.\n"
    exit 0
fi

# ========================= 16. PHASE 1: WORKSPACE SANITATION =========================
draw_step_header $CURRENT_STEP $TOTAL_STEPS "Workspace Sanitation & Dependency Sync"

if [ "$RUN_CLEAN" = true ]; then
    $FLUTTER_CMD clean > "$LOG_TEMP" 2>&1 &
    spin_engine $! "Purging build telemetry and project caches (${FLUTTER_CMD} clean)" "$LOG_TEMP"
fi

$FLUTTER_CMD pub get > "$LOG_TEMP" 2>&1 &
spin_engine $! "Resolving remote pub dependency tree mappings (${FLUTTER_CMD} pub get)" "$LOG_TEMP"

CURRENT_STEP=$(( CURRENT_STEP + 1 ))

# ========================= 17. PHASE 2: COMPILATION PIPELINE =========================
draw_step_header $CURRENT_STEP $TOTAL_STEPS "Platform Engine Native Compilation"

build_android_apk() {
    $FLUTTER_CMD build apk --release --flavor ${FLAVOR} --dart-define=FLAVOR=${FLAVOR} --build-name=${ANDROID_NAME} --build-number=${ANDROID_CODE} > "$LOG_TEMP" 2>&1 &
    spin_engine $! "Compiling Android Release Package (${FLAVOR} APK v${ANDROID_NAME}+${ANDROID_CODE})" "$LOG_TEMP"

    local apk_src
    apk_src=$(find build/app/outputs/flutter-apk -name "*.apk" ! -name "*unaligned*" 2>/dev/null | head -n 1)
    if [ -n "$apk_src" ] && [ -f "$apk_src" ]; then
        FINAL_APK_PATH="${ANDROID_DIR}/${PREFIX}_${FLAVOR}_${ANDROID_NAME}_${ANDROID_CODE}_${TIMESTAMP}.apk"
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
    $FLUTTER_CMD build appbundle --release --flavor ${FLAVOR} --dart-define=FLAVOR=${FLAVOR} --build-name=${ANDROID_NAME} --build-number=${ANDROID_CODE} > "$LOG_TEMP" 2>&1 &
    spin_engine $! "Compiling Production AppBundle Payload (${FLAVOR} AAB v${ANDROID_NAME}+${ANDROID_CODE})" "$LOG_TEMP"

    local aab_src
    aab_src=$(find build/app/outputs/bundle -name "*.aab" 2>/dev/null | head -n 1)
    if [ -n "$aab_src" ] && [ -f "$aab_src" ]; then
        FINAL_AAB_PATH="${ANDROID_DIR}/${PREFIX}_${FLAVOR}_${ANDROID_NAME}_${ANDROID_CODE}_${TIMESTAMP}.aab"
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

    $FLUTTER_CMD build ipa --release --flavor ${FLAVOR} --dart-define=FLAVOR=${FLAVOR} $extra_flag --build-name=${IOS_NAME} --build-number=${IOS_CODE} > "$LOG_TEMP" 2>&1 &
    spin_engine $! "Compiling iOS Native Package (${FLAVOR} IPA v${IOS_NAME}+${IOS_CODE})" "$LOG_TEMP"

    if [ "$NOSIGN" = false ]; then
        local ipa_src
        ipa_src=$(find build/ios/ipa -name "*.ipa" 2>/dev/null | head -n 1)
        if [ -n "$ipa_src" ] && [ -f "$ipa_src" ]; then
            FINAL_IPA_PATH="${IOS_DIR}/${PREFIX}_${FLAVOR}_${IOS_NAME}_${IOS_CODE}_${TIMESTAMP}.ipa"
            cp "$ipa_src" "$FINAL_IPA_PATH" || {
                print_error_card "File Copy Failed" "Failed to copy compiled IPA to ${FINAL_IPA_PATH}" ""
                exit 1
            }
            FINAL_IPA_SIZE=$(ls -lh "$FINAL_IPA_PATH" | awk '{print $5}')
            echo -e "     ${ARROW} IPA Saved: ${BOLD}${CYAN}${FINAL_IPA_PATH}${NC} ${DIM}(${FINAL_IPA_SIZE})${NC}"
        else
            echo -e "     ${WARN} ${YELLOW}No .ipa binary found in build/ios/ipa [Runner.xcarchive generated]${NC}"
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

# ========================= 18. PHASE 3: STORE DISTRIBUTION GATEWAY =========================
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
        if ! command -v gws &> /dev/null; then
            echo -e "  ${INFO} 'gws' CLI not found. Installing via npm..."
            if command -v npm &> /dev/null; then
                npm install -g @googleworkspace/cli > "$LOG_TEMP" 2>&1
                if ! command -v gws &> /dev/null; then
                    print_error_card "Installation Failed" "Failed to install @googleworkspace/cli automatically." "$LOG_TEMP"
                    exit 1
                fi
                echo -e "  ${TICK} Successfully installed 'gws' CLI.\n"
            else
                print_error_card "Missing Tool" "'npm' is required to auto-install gws." ""
                exit 1
            fi
        fi

        if ! gws drive about get --params '{"fields":"user"}' > /dev/null 2>&1; then
            echo -e "\n  ${WARN} Google Drive session expired or not configured."
            if [ ! -f "$HOME/.config/gws/client_secret.json" ] && [ -z "$GOOGLE_WORKSPACE_CLI_CLIENT_ID" ]; then
                gws auth setup
            else
                gws auth login -s drive
            fi
            if ! gws drive about get --params '{"fields":"user"}' > /dev/null 2>&1; then
                print_error_card "Authentication Failed" "Google Drive authentication was not completed successfully." ""
                exit 1
            fi
            echo -e "  ${TICK} Authentication successful. Proceeding with upload...\n"
        fi

        filename=$(basename "$FINAL_APK_PATH")
        json_payload="{\"name\": \"$filename\"}"
        gdrive_msg="Uploading APK to Google Drive root folder"
        if [ -n "$GDRIVE_BASE_FOLDER_ID" ]; then
            json_payload="{\"name\": \"$filename\", \"parents\": [\"$GDRIVE_BASE_FOLDER_ID\"]}"
            gdrive_msg="Uploading APK to Google Drive folder: $GDRIVE_BASE_FOLDER_ID"
        fi
        gws drive files create --upload "$FINAL_APK_PATH" --json "$json_payload" > "/tmp/gdrive_out_$$" 2>&1 &
        spin_engine $! "$gdrive_msg" "/tmp/gdrive_out_$$"

        G_ID=$(cat "/tmp/gdrive_out_$$" | grep -o '"id": "[^"]*' | grep -o '[^"]*$' || true)
        if [ -n "$G_ID" ]; then
            gws drive permissions create --params "{\"fileId\": \"$G_ID\"}" --json "{\"role\": \"reader\", \"type\": \"anyone\"}" > /dev/null 2>&1 || true
            echo -e "     ${ARROW} Google Drive Public Link: ${BOLD}${CYAN}https://drive.google.com/file/d/${G_ID}/view?usp=sharing${NC}"
            echo -e "     ${ARROW} Direct Download Link:      ${BOLD}${CYAN}https://drive.google.com/uc?export=download&id=${G_ID}${NC}"
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

        UPLOAD_RESPONSE=$(curl -s -X POST https://upload.diawi.com/ \
            -F token="${DIAWI_TOKEN}" \
            -F file=@"${UPLOAD_FILE_PATH}" \
            -F comment="Automated Build Release")
        JOB_TOKEN=$(echo "$UPLOAD_RESPONSE" | grep -o '"job":"[^"]*' | grep -o '[^"]*$')
        if [ -z "$JOB_TOKEN" ]; then
            echo -e "  ${WARN} ${YELLOW}Diawi Upload Skipped:${NC} ${DIM}$UPLOAD_RESPONSE${NC}"
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

# ========================= 19. FINAL EXECUTION SUMMARY =========================
END_TOTAL_TIME=$(date +%s)
TOTAL_DIFF=$(( END_TOTAL_TIME - START_TOTAL_TIME ))
TOTAL_MINS=$(( TOTAL_DIFF / 60 ))
TOTAL_SECS=$(( TOTAL_DIFF % 60 ))
TOTAL_DURATION=$(printf "%02dm %02ds" "$TOTAL_MINS" "$TOTAL_SECS")

echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║${NC}   ${BOLD}${WHITE}🎉 DEPLOYMENT SUITE EXECUTED SUCCESSFULLY${NC}                        ${BOLD}${GREEN}║${NC}"
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
