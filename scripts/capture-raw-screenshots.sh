#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

OUTPUT_DIR="$PROJECT_DIR/app-store/raw-screenshots"
RESULT_DIR="$PROJECT_DIR/test-results/screenshots"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/PiggyPulseScreenshotDerivedData}"
CAPTURE_CONFIG_PATH="${CAPTURE_CONFIG_PATH:-/tmp/piggypulse-screenshot-capture.env}"
CONFIGURATION="${CONFIGURATION:-Debug}"
SCHEME="${SCHEME:-PiggyPulse}"
SMOKE=0
REQUESTED_DEVICE_FAMILY=""
REQUESTED_LOCALE=""
REQUESTED_STATE=""
STATUS_BAR_OVERRIDDEN=0

ALL_LOCALES=("en-US" "en-GB" "pt-BR" "pt-PT" "es-ES" "fr-FR" "nl-NL" "de-DE")
ALL_STATES=(
    "01-dashboard-nebula"
    "02-dashboard-electric-neon"
    "03-dashboard-tropical"
    "04-transactions"
    "05-period-configuration"
    "06-categories"
)
ALL_DEVICE_FAMILIES=("iphone" "ipad")
SMOKE_LOCALES=("en-US" "pt-PT" "de-DE")
SMOKE_STATES=("01-dashboard-nebula" "04-transactions" "06-categories")

usage() {
    cat <<USAGE
Usage: scripts/capture-raw-screenshots.sh [options]

Options:
  --smoke                   Capture the smoke subset: iPhone, en-US/pt-PT/de-DE, states 01/04/06.
  --device-family FAMILY    Capture only iphone or ipad.
  --locale LOCALE           Capture only one locale.
  --state STATE             Capture only one screenshot state.
  --output-dir DIR          Override output directory. Default: app-store/raw-screenshots.
  --derived-data DIR        Override DerivedData path. Default: /tmp/PiggyPulseScreenshotDerivedData.
  -h, --help                Show this help.

Environment overrides:
  SCREENSHOT_IPHONE_DEVICE  Preferred iPhone simulator name.
  SCREENSHOT_IPAD_DEVICE    Preferred iPad simulator name.
  CONFIGURATION             Xcode configuration. Default: Debug.
  SCHEME                    Xcode scheme. Default: PiggyPulse.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --smoke)
            SMOKE=1
            shift
            ;;
        --device-family)
            REQUESTED_DEVICE_FAMILY="${2:-}"
            shift 2
            ;;
        --locale)
            REQUESTED_LOCALE="${2:-}"
            shift 2
            ;;
        --state)
            REQUESTED_STATE="${2:-}"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="${2:-}"
            shift 2
            ;;
        --derived-data)
            DERIVED_DATA_PATH="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

validate_requested() {
    local requested="$1"
    shift
    if [[ -n "$requested" ]] && ! contains "$requested" "$@"; then
        echo "Unsupported value: $requested" >&2
        exit 2
    fi
}

device_is_available() {
    local device_name="$1"
    xcrun simctl list devices available | grep -Fq "$device_name ("
}

first_available_matching() {
    local pattern="$1"
    xcrun simctl list devices available \
        | awk -v pattern="$pattern" '
            index($0, pattern) {
                line=$0
                sub(/^[ \t]*/, "", line)
                sub(/[ \t]*\(.*/, "", line)
                print line
                exit
            }
        '
}

pick_device() {
    local family="$1"
    local override=""
    local candidates=()

    if [[ "$family" == "iphone" ]]; then
        override="${SCREENSHOT_IPHONE_DEVICE:-}"
        candidates=(
            "iPhone 17 Pro Max"
            "iPhone 16 Pro Max"
            "iPhone 15 Pro Max"
            "iPhone 17 Pro"
            "iPhone 16 Pro"
            "iPhone 15 Pro"
        )
    else
        override="${SCREENSHOT_IPAD_DEVICE:-}"
        candidates=(
            "iPad Pro 13-inch (M5)"
            "iPad Pro 13-inch (M4)"
            "iPad Pro 13-inch"
            "iPad Pro 12.9-inch (6th generation)"
            "iPad Air 13-inch (M4)"
            "iPad Air 13-inch (M3)"
            "iPad Air 13-inch"
            "iPad Pro 11-inch (M4)"
        )
    fi

    if [[ -n "$override" ]]; then
        if device_is_available "$override"; then
            echo "$override"
            return
        fi
        echo "Requested $family simulator is not available: $override" >&2
        exit 1
    fi

    local candidate
    for candidate in "${candidates[@]}"; do
        if device_is_available "$candidate"; then
            echo "$candidate"
            return
        fi
    done

    local fallback_pattern="iPhone"
    [[ "$family" == "ipad" ]] && fallback_pattern="iPad"
    local fallback
    fallback="$(first_available_matching "$fallback_pattern")"
    if [[ -n "$fallback" ]]; then
        echo "$fallback"
        return
    fi

    echo "No available $family simulator found." >&2
    exit 1
}

boot_device() {
    local device_name="$1"
    echo "Booting simulator: $device_name"
    xcrun simctl shutdown all >/dev/null 2>&1 || true
    xcrun simctl boot "$device_name" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$device_name" -b >/dev/null
}

override_status_bar() {
    xcrun simctl status_bar booted clear >/dev/null 2>&1 || true
    STATUS_BAR_OVERRIDDEN=0

    if xcrun simctl status_bar booted override --time "09:41" --batteryState charged --batteryLevel 100 >/dev/null 2>&1; then
        STATUS_BAR_OVERRIDDEN=1
    else
        STATUS_BAR_OVERRIDDEN=0
        echo "Warning: simctl status_bar override failed or is unavailable; continuing without status bar override." >&2
    fi
}

clear_status_bar() {
    if [[ "$STATUS_BAR_OVERRIDDEN" == "1" ]]; then
        xcrun simctl status_bar booted clear >/dev/null 2>&1 || true
        STATUS_BAR_OVERRIDDEN=0
    fi
}

trap clear_status_bar EXIT

capture_one() {
    local family="$1"
    local device_name="$2"
    local locale="$3"
    local state="$4"
    local output_family_dir="$OUTPUT_DIR/$family/$locale"
    local result_bundle="$RESULT_DIR/$family-$locale-$state.xcresult"

    mkdir -p "$output_family_dir" "$RESULT_DIR"
    rm -rf "$result_bundle"
    {
        printf 'SCREENSHOT_LOCALE=%s\n' "$locale"
        printf 'SCREENSHOT_STATE=%s\n' "$state"
        printf 'SCREENSHOT_CAPTURE_OUTPUT_DIR=%s\n' "$output_family_dir"
        printf 'SCREENSHOT_CAPTURE_FILENAME=%s\n' "$state.png"
    } > "$CAPTURE_CONFIG_PATH"

    echo "Capturing $family / $locale / $state on $device_name"
    override_status_bar

    if SCREENSHOT_CAPTURE_CONFIG="$CAPTURE_CONFIG_PATH" xcodebuild test \
        -project "$PROJECT_DIR/PiggyPulse.xcodeproj" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$device_name,OS=latest" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -resultBundlePath "$result_bundle" \
        -only-testing:PiggyPulseUITests/ScreenshotCaptureUITests/testCaptureRawScreenshot \
        CODE_SIGNING_ALLOWED=NO; then
        clear_status_bar
    else
        local status=$?
        clear_status_bar
        return "$status"
    fi
}

if [[ "$SMOKE" == "1" ]]; then
    LOCALES=("${SMOKE_LOCALES[@]}")
    STATES=("${SMOKE_STATES[@]}")
    DEVICE_FAMILIES=("iphone")
else
    validate_requested "$REQUESTED_LOCALE" "${ALL_LOCALES[@]}"
    validate_requested "$REQUESTED_STATE" "${ALL_STATES[@]}"
    validate_requested "$REQUESTED_DEVICE_FAMILY" "${ALL_DEVICE_FAMILIES[@]}"
    LOCALES=("${ALL_LOCALES[@]}")
    STATES=("${ALL_STATES[@]}")
    DEVICE_FAMILIES=("${ALL_DEVICE_FAMILIES[@]}")
fi

if [[ "$SMOKE" == "1" && -n "$REQUESTED_DEVICE_FAMILY" ]]; then
    validate_requested "$REQUESTED_DEVICE_FAMILY" "${ALL_DEVICE_FAMILIES[@]}"
    DEVICE_FAMILIES=("$REQUESTED_DEVICE_FAMILY")
fi
if [[ "$SMOKE" == "1" && -n "$REQUESTED_LOCALE" ]]; then
    validate_requested "$REQUESTED_LOCALE" "${ALL_LOCALES[@]}"
    LOCALES=("$REQUESTED_LOCALE")
fi
if [[ "$SMOKE" == "1" && -n "$REQUESTED_STATE" ]]; then
    validate_requested "$REQUESTED_STATE" "${ALL_STATES[@]}"
    STATES=("$REQUESTED_STATE")
fi

if [[ "$SMOKE" != "1" && -n "$REQUESTED_DEVICE_FAMILY" ]]; then
    DEVICE_FAMILIES=("$REQUESTED_DEVICE_FAMILY")
fi
if [[ "$SMOKE" != "1" && -n "$REQUESTED_LOCALE" ]]; then
    LOCALES=("$REQUESTED_LOCALE")
fi
if [[ "$SMOKE" != "1" && -n "$REQUESTED_STATE" ]]; then
    STATES=("$REQUESTED_STATE")
fi

mkdir -p "$OUTPUT_DIR"
: > "$OUTPUT_DIR/devices-used.txt"

for family in "${DEVICE_FAMILIES[@]}"; do
    device_name="$(pick_device "$family")"
    echo "$family: $device_name" | tee -a "$OUTPUT_DIR/devices-used.txt"
    boot_device "$device_name"

    for locale in "${LOCALES[@]}"; do
        for state in "${STATES[@]}"; do
            capture_one "$family" "$device_name" "$locale" "$state"
        done
    done

    clear_status_bar
done

echo "Raw screenshots written to: $OUTPUT_DIR"
