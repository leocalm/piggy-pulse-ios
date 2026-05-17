#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

OUTPUT_DIR="$PROJECT_DIR/app-store/raw-screenshots"
SMOKE=0
REQUESTED_DEVICE_FAMILY=""
REQUESTED_LOCALE=""
REQUESTED_STATE=""

ALL_DEVICE_FAMILIES=("iphone" "ipad")
ALL_LOCALES=("en-US" "en-GB" "pt-BR" "pt-PT" "es-ES" "fr-FR" "nl-NL" "de-DE")
ALL_STATES=(
    "01-dashboard-nebula"
    "02-dashboard-electric-neon"
    "03-dashboard-tropical"
    "04-transactions"
    "05-period-configuration"
    "06-categories"
)
SMOKE_LOCALES=("en-US" "pt-PT" "de-DE")
SMOKE_STATES=("01-dashboard-nebula" "04-transactions" "06-categories")

usage() {
    cat <<USAGE
Usage: scripts/validate-raw-screenshots.sh [options]

Options:
  --smoke                   Validate the smoke subset: iPhone, en-US/pt-PT/de-DE, states 01/04/06.
  --device-family FAMILY    Validate only iphone or ipad.
  --locale LOCALE           Validate only one locale.
  --state STATE             Validate only one screenshot state.
  --output-dir DIR          Override output directory. Default: app-store/raw-screenshots.
  -h, --help                Show this help.
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

if [[ "$SMOKE" == "1" ]]; then
    DEVICE_FAMILIES=("iphone")
    LOCALES=("${SMOKE_LOCALES[@]}")
    STATES=("${SMOKE_STATES[@]}")
else
    validate_requested "$REQUESTED_DEVICE_FAMILY" "${ALL_DEVICE_FAMILIES[@]}"
    validate_requested "$REQUESTED_LOCALE" "${ALL_LOCALES[@]}"
    validate_requested "$REQUESTED_STATE" "${ALL_STATES[@]}"
    DEVICE_FAMILIES=("${ALL_DEVICE_FAMILIES[@]}")
    LOCALES=("${ALL_LOCALES[@]}")
    STATES=("${ALL_STATES[@]}")
fi

if [[ -n "$REQUESTED_DEVICE_FAMILY" ]]; then
    validate_requested "$REQUESTED_DEVICE_FAMILY" "${ALL_DEVICE_FAMILIES[@]}"
    DEVICE_FAMILIES=("$REQUESTED_DEVICE_FAMILY")
fi
if [[ -n "$REQUESTED_LOCALE" ]]; then
    validate_requested "$REQUESTED_LOCALE" "${ALL_LOCALES[@]}"
    LOCALES=("$REQUESTED_LOCALE")
fi
if [[ -n "$REQUESTED_STATE" ]]; then
    validate_requested "$REQUESTED_STATE" "${ALL_STATES[@]}"
    STATES=("$REQUESTED_STATE")
fi

if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "Missing output directory: $OUTPUT_DIR" >&2
    exit 1
fi

ERRORS=0
TOTAL=0

for family in "${DEVICE_FAMILIES[@]}"; do
    family_dir="$OUTPUT_DIR/$family"
    expected_dimensions=""

    if [[ ! -d "$family_dir" ]]; then
        echo "Missing device folder: $family_dir" >&2
        ERRORS=$((ERRORS + 1))
        continue
    fi

    for locale in "${LOCALES[@]}"; do
        locale_dir="$family_dir/$locale"
        if [[ ! -d "$locale_dir" ]]; then
            echo "Missing locale folder: $locale_dir" >&2
            ERRORS=$((ERRORS + 1))
            continue
        fi

        for state in "${STATES[@]}"; do
            file="$locale_dir/$state.png"
            TOTAL=$((TOTAL + 1))

            if [[ ! -f "$file" ]]; then
                echo "Missing screenshot: $file" >&2
                ERRORS=$((ERRORS + 1))
                continue
            fi

            if [[ ! -s "$file" ]]; then
                echo "Empty screenshot: $file" >&2
                ERRORS=$((ERRORS + 1))
                continue
            fi

            format="$(png_format "$file")"
            if [[ "$format" != "png" ]]; then
                echo "Screenshot is not PNG: $file (format: ${format:-unknown})" >&2
                ERRORS=$((ERRORS + 1))
                continue
            fi

            dimensions="$(png_dimensions "$file")"
            if [[ -z "$dimensions" ]]; then
                echo "Could not read PNG dimensions: $file" >&2
                ERRORS=$((ERRORS + 1))
                continue
            fi

            if [[ -z "$expected_dimensions" ]]; then
                expected_dimensions="$dimensions"
                echo "$family dimensions: $expected_dimensions"
            elif [[ "$dimensions" != "$expected_dimensions" ]]; then
                echo "Dimension mismatch for $file: expected $expected_dimensions, got $dimensions" >&2
                ERRORS=$((ERRORS + 1))
            fi
        done
    done
done

if [[ "$ERRORS" -gt 0 ]]; then
    echo "Raw screenshot validation failed: $ERRORS issue(s), $TOTAL expected screenshot(s)." >&2
    exit 1
fi

echo "Raw screenshot validation passed: $TOTAL screenshot(s)."
