#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

INPUT_DIR="$PROJECT_DIR/app-store/final-screenshots"
OUTPUT_DIR="$PROJECT_DIR/fastlane/screenshots"
REQUESTED_DEVICE_FAMILY=""
REQUESTED_LOCALE=""
CLEAN=0

ALL_DEVICE_FAMILIES=("iphone" "ipad")
ALL_LOCALES=("en-US" "en-GB" "pt-BR" "pt-PT" "es-ES" "fr-FR" "nl-NL" "de-DE")
FINAL_FILES=(
    "01-dashboard.png"
    "02-themes.png"
    "03-transactions.png"
    "04-periods.png"
    "05-categories.png"
)

usage() {
    cat <<USAGE
Usage: scripts/sync-app-store-assets.sh [options]

Options:
  --device-family FAMILY    Sync only iphone or ipad.
  --locale LOCALE           Sync only one locale.
  --input-dir DIR           Final screenshot directory. Default: app-store/final-screenshots.
  --output-dir DIR          Fastlane screenshot directory. Default: fastlane/screenshots.
  --clean                   Remove generated iphone-/ipad-prefixed PNGs in selected locale folders before copying.
  -h, --help                Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --device-family)
            REQUESTED_DEVICE_FAMILY="${2:-}"
            shift 2
            ;;
        --locale)
            REQUESTED_LOCALE="${2:-}"
            shift 2
            ;;
        --input-dir)
            INPUT_DIR="${2:-}"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="${2:-}"
            shift 2
            ;;
        --clean)
            CLEAN=1
            shift
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

validate_requested "$REQUESTED_DEVICE_FAMILY" "${ALL_DEVICE_FAMILIES[@]}"
validate_requested "$REQUESTED_LOCALE" "${ALL_LOCALES[@]}"

DEVICE_FAMILIES=("${ALL_DEVICE_FAMILIES[@]}")
LOCALES=("${ALL_LOCALES[@]}")

if [[ -n "$REQUESTED_DEVICE_FAMILY" ]]; then
    DEVICE_FAMILIES=("$REQUESTED_DEVICE_FAMILY")
fi
if [[ -n "$REQUESTED_LOCALE" ]]; then
    LOCALES=("$REQUESTED_LOCALE")
fi

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Missing final screenshot directory: $INPUT_DIR" >&2
    exit 1
fi

copied=0

for locale in "${LOCALES[@]}"; do
    locale_output_dir="$OUTPUT_DIR/$locale"
    mkdir -p "$locale_output_dir"

    if [[ "$CLEAN" == "1" ]]; then
        find "$locale_output_dir" -maxdepth 1 -type f \( -name 'iphone-*.png' -o -name 'ipad-*.png' \) -delete
    fi

    for family in "${DEVICE_FAMILIES[@]}"; do
        for file_name in "${FINAL_FILES[@]}"; do
            source_file="$INPUT_DIR/$family/$locale/$file_name"
            destination_file="$locale_output_dir/$family-$file_name"

            if [[ ! -f "$source_file" ]]; then
                echo "Missing final screenshot: $source_file" >&2
                exit 1
            fi
            if [[ ! -s "$source_file" ]]; then
                echo "Empty final screenshot: $source_file" >&2
                exit 1
            fi

            cp "$source_file" "$destination_file"
            copied=$((copied + 1))
        done
    done
done

echo "Synced App Store screenshots: $copied file(s)."
echo "Fastlane screenshots directory: $OUTPUT_DIR"
