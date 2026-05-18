#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

OUTPUT_DIR="$PROJECT_DIR/app-store/final-screenshots"
SMOKE=0
REQUESTED_DEVICE_FAMILY=""
REQUESTED_LOCALE=""
REQUESTED_FRAME=""
REQUESTED_IPHONE_DIMENSIONS="${SCREENSHOT_FINAL_IPHONE_DIMENSIONS:-}"
REQUESTED_IPAD_DIMENSIONS="${SCREENSHOT_FINAL_IPAD_DIMENSIONS:-}"
MAX_FILE_BYTES="${SCREENSHOT_FINAL_MAX_FILE_BYTES:-500000000}"
CHECK_EXTRA_FILES=0

ALL_DEVICE_FAMILIES=("iphone" "ipad")
ALL_LOCALES=("en-US" "en-GB" "pt-BR" "pt-PT" "es-ES" "fr-FR" "nl-NL" "de-DE")
ALL_FRAMES=("dashboard" "themes" "transactions" "periods" "categories")
SMOKE_LOCALES=("en-US" "pt-PT" "de-DE")
SMOKE_FRAMES=("dashboard" "transactions" "categories")

FINAL_FILES_dashboard="01-dashboard.png"
FINAL_FILES_themes="02-themes.png"
FINAL_FILES_transactions="03-transactions.png"
FINAL_FILES_periods="04-periods.png"
FINAL_FILES_categories="05-categories.png"
DEFAULT_IPHONE_DIMENSIONS=(
    "1320x2868" # iPhone 17 Pro Max / 16 Pro Max raw capture size
    "1290x2796" # iPhone 15 Pro Max / 15 Plus class, 6.7"
    "1179x2556" # iPhone 17/16/15 Pro class
)
DEFAULT_IPAD_DIMENSIONS=(
    "2064x2752" # iPad Pro/Air 13" raw capture size
    "2048x2732" # iPad Pro 13" / 12.9"
    "1488x2266" # iPad Pro 11" M5/M4
    "1668x2420" # iPad Pro/Air 11"
    "1668x2388" # iPad Pro 11"
    "1640x2360" # iPad Air/mini class
)

usage() {
    cat <<USAGE
Usage: scripts/validate-final-screenshots.sh [options]

Options:
  --smoke                   Validate the representative smoke subset.
  --device-family FAMILY    Validate only iphone or ipad.
  --locale LOCALE           Validate only one locale.
  --frame FRAME             Validate only one final frame: dashboard, themes, transactions, periods, categories.
  --output-dir DIR          Override output directory. Default: app-store/final-screenshots.
  --iphone-dimensions LIST  Override accepted final iPhone dimensions, comma- or space-separated.
  --ipad-dimensions LIST    Override accepted final iPad dimensions, comma- or space-separated.
  -h, --help                Show this help.

Environment overrides:
  SCREENSHOT_FINAL_IPHONE_DIMENSIONS  Accepted final iPhone dimensions, comma- or space-separated.
  SCREENSHOT_FINAL_IPAD_DIMENSIONS    Accepted final iPad dimensions, comma- or space-separated.
  SCREENSHOT_FINAL_MAX_FILE_BYTES     Maximum PNG file size. Default: 500000000.
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
        --frame)
            REQUESTED_FRAME="${2:-}"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="${2:-}"
            shift 2
            ;;
        --iphone-dimensions)
            REQUESTED_IPHONE_DIMENSIONS="${2:-}"
            shift 2
            ;;
        --ipad-dimensions)
            REQUESTED_IPAD_DIMENSIONS="${2:-}"
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

split_dimensions() {
    local values="$1"
    local normalized="${values//,/ }"
    local dimensions=()
    local dimension

    for dimension in $normalized; do
        dimensions+=("$dimension")
    done

    printf '%s\n' "${dimensions[@]}"
}

accepted_dimensions_for_family() {
    local family="$1"

    if [[ "$family" == "iphone" ]]; then
        if [[ -n "$REQUESTED_IPHONE_DIMENSIONS" ]]; then
            split_dimensions "$REQUESTED_IPHONE_DIMENSIONS"
        else
            printf '%s\n' "${DEFAULT_IPHONE_DIMENSIONS[@]}"
        fi
    else
        if [[ -n "$REQUESTED_IPAD_DIMENSIONS" ]]; then
            split_dimensions "$REQUESTED_IPAD_DIMENSIONS"
        else
            printf '%s\n' "${DEFAULT_IPAD_DIMENSIONS[@]}"
        fi
    fi
}

join_dimensions() {
    local separator=""
    local output=""
    local dimension

    for dimension in "$@"; do
        output="$output$separator$dimension"
        separator=", "
    done

    printf '%s' "$output"
}

frame_file_name() {
    local frame="$1"
    local variable="FINAL_FILES_$frame"
    printf '%s' "${!variable}"
}

png_dimensions() {
    local file="$1"
    sips -g pixelWidth -g pixelHeight "$file" 2>/dev/null \
        | awk '
            /pixelWidth:/ { width=$2 }
            /pixelHeight:/ { height=$2 }
            END { if (width != "" && height != "") print width "x" height }
        '
}

png_format() {
    local file="$1"
    sips -g format "$file" 2>/dev/null \
        | awk '/format:/ { print $2; exit }'
}

png_has_alpha() {
    local file="$1"
    python3 - "$file" <<'PY'
from pathlib import Path
import sys
from PIL import Image

path = Path(sys.argv[1])
with Image.open(path) as image:
    has_alpha = image.mode in {"RGBA", "LA", "PA"} or "transparency" in image.info
print("yes" if has_alpha else "no")
PY
}

file_size_bytes() {
    stat -f%z "$1"
}

if [[ "$SMOKE" == "1" ]]; then
    DEVICE_FAMILIES=("iphone")
    LOCALES=("${SMOKE_LOCALES[@]}")
    FRAMES=("${SMOKE_FRAMES[@]}")
else
    validate_requested "$REQUESTED_DEVICE_FAMILY" "${ALL_DEVICE_FAMILIES[@]}"
    validate_requested "$REQUESTED_LOCALE" "${ALL_LOCALES[@]}"
    validate_requested "$REQUESTED_FRAME" "${ALL_FRAMES[@]}"
    DEVICE_FAMILIES=("${ALL_DEVICE_FAMILIES[@]}")
    LOCALES=("${ALL_LOCALES[@]}")
    FRAMES=("${ALL_FRAMES[@]}")
fi

if [[ -n "$REQUESTED_DEVICE_FAMILY" ]]; then
    validate_requested "$REQUESTED_DEVICE_FAMILY" "${ALL_DEVICE_FAMILIES[@]}"
    DEVICE_FAMILIES=("$REQUESTED_DEVICE_FAMILY")
fi
if [[ -n "$REQUESTED_LOCALE" ]]; then
    validate_requested "$REQUESTED_LOCALE" "${ALL_LOCALES[@]}"
    LOCALES=("$REQUESTED_LOCALE")
fi
if [[ -n "$REQUESTED_FRAME" ]]; then
    validate_requested "$REQUESTED_FRAME" "${ALL_FRAMES[@]}"
    FRAMES=("$REQUESTED_FRAME")
fi

if [[ "$SMOKE" != "1" && -z "$REQUESTED_FRAME" ]]; then
    CHECK_EXTRA_FILES=1
fi

if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "Missing final screenshot directory: $OUTPUT_DIR" >&2
    exit 1
fi

ERRORS=0
TOTAL=0

for family in "${DEVICE_FAMILIES[@]}"; do
    family_dir="$OUTPUT_DIR/$family"
    accepted_dimensions=()
    while IFS= read -r dimension; do
        [[ -n "$dimension" ]] && accepted_dimensions+=("$dimension")
    done < <(accepted_dimensions_for_family "$family")
    accepted_dimensions_text="$(join_dimensions "${accepted_dimensions[@]}")"

    if [[ ! -d "$family_dir" ]]; then
        echo "Missing device folder: $family_dir" >&2
        ERRORS=$((ERRORS + 1))
        continue
    fi

    for locale in "${LOCALES[@]}"; do
        locale_dir="$family_dir/$locale"
        expected_files=()

        if [[ ! -d "$locale_dir" ]]; then
            echo "Missing locale folder: $locale_dir" >&2
            ERRORS=$((ERRORS + 1))
            continue
        fi

        for frame in "${FRAMES[@]}"; do
            file_name="$(frame_file_name "$frame")"
            expected_files+=("$file_name")
            file="$locale_dir/$file_name"
            TOTAL=$((TOTAL + 1))

            if [[ ! -f "$file" ]]; then
                echo "Missing final screenshot: $file" >&2
                ERRORS=$((ERRORS + 1))
                continue
            fi

            if [[ ! -s "$file" ]]; then
                echo "Empty final screenshot: $file" >&2
                ERRORS=$((ERRORS + 1))
                continue
            fi

            format="$(png_format "$file")"
            if [[ "$format" != "png" ]]; then
                echo "Final screenshot is not PNG: $file (format: ${format:-unknown})" >&2
                ERRORS=$((ERRORS + 1))
                continue
            fi

            if [[ "$(png_has_alpha "$file")" == "yes" ]]; then
                echo "Final screenshot has an alpha channel, which App Store Connect rejects: $file" >&2
                ERRORS=$((ERRORS + 1))
            fi

            dimensions="$(png_dimensions "$file")"
            if [[ -z "$dimensions" ]]; then
                echo "Could not read final PNG dimensions: $file" >&2
                ERRORS=$((ERRORS + 1))
                continue
            fi

            if ! contains "$dimensions" "${accepted_dimensions[@]}"; then
                echo "Unsupported dimensions for final $family screenshot: $file got $dimensions; expected one of: $accepted_dimensions_text" >&2
                ERRORS=$((ERRORS + 1))
            fi

            size_bytes="$(file_size_bytes "$file")"
            if [[ "$size_bytes" -gt "$MAX_FILE_BYTES" ]]; then
                echo "Final screenshot exceeds size limit: $file is $size_bytes bytes; max is $MAX_FILE_BYTES" >&2
                ERRORS=$((ERRORS + 1))
            fi
        done

        if [[ "$CHECK_EXTRA_FILES" == "1" ]]; then
            while IFS= read -r actual_file; do
                actual_name="$(basename "$actual_file")"
                if ! contains "$actual_name" "${expected_files[@]}"; then
                    echo "Unexpected final screenshot file: $actual_file" >&2
                    ERRORS=$((ERRORS + 1))
                fi
            done < <(find "$locale_dir" -maxdepth 1 -type f -name '*.png' -print)
        fi
    done
done

if [[ "$ERRORS" -gt 0 ]]; then
    echo "Final screenshot validation failed: $ERRORS issue(s), $TOTAL expected screenshot(s)." >&2
    exit 1
fi

echo "Final screenshot validation passed: $TOTAL screenshot(s)."
