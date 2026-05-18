#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

SCREENSHOTS_DIR="$PROJECT_DIR/fastlane/screenshots"
METADATA_DIR="$PROJECT_DIR/fastlane/metadata"
REQUESTED_LOCALE=""
REQUESTED_DEVICE_FAMILY=""
MAX_FILE_BYTES="${APP_STORE_SCREENSHOT_MAX_FILE_BYTES:-500000000}"
REQUIRED_METADATA_FILES="${APP_STORE_REQUIRED_METADATA_FILES:-name.txt promotional_text.txt description.txt keywords.txt release_notes.txt}"

ALL_DEVICE_FAMILIES=("iphone" "ipad")
ALL_LOCALES=("en-US" "en-GB" "pt-BR" "pt-PT" "es-ES" "fr-FR" "nl-NL" "de-DE")
FINAL_FILES=(
    "01-dashboard.png"
    "02-themes.png"
    "03-transactions.png"
    "04-periods.png"
    "05-categories.png"
)
DEFAULT_IPHONE_DIMENSIONS=(
    "1320x2868"
    "1290x2796"
    "1179x2556"
)
DEFAULT_IPAD_DIMENSIONS=(
    "2064x2752"
    "2048x2732"
    "1488x2266"
    "1668x2420"
    "1668x2388"
    "1640x2360"
)

usage() {
    cat <<USAGE
Usage: scripts/validate-app-store-upload-package.sh [options]

Options:
  --locale LOCALE              Validate only one locale.
  --device-family FAMILY       Validate only iphone or ipad screenshots.
  --screenshots-dir DIR        Fastlane screenshot directory. Default: fastlane/screenshots.
  --metadata-dir DIR           Fastlane metadata directory. Default: fastlane/metadata.
  -h, --help                   Show this help.

Environment overrides:
  APP_STORE_REQUIRED_METADATA_FILES  Space- or comma-separated required metadata files.
                                     Default: name.txt promotional_text.txt description.txt keywords.txt release_notes.txt.
  APP_STORE_SCREENSHOT_MAX_FILE_BYTES Maximum PNG file size. Default: 500000000.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --locale)
            REQUESTED_LOCALE="${2:-}"
            shift 2
            ;;
        --device-family)
            REQUESTED_DEVICE_FAMILY="${2:-}"
            shift 2
            ;;
        --screenshots-dir)
            SCREENSHOTS_DIR="${2:-}"
            shift 2
            ;;
        --metadata-dir)
            METADATA_DIR="${2:-}"
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

split_values() {
    local values="$1"
    local normalized="${values//,/ }"
    local value
    for value in $normalized; do
        [[ -n "$value" ]] && printf '%s\n' "$value"
    done
}

accepted_dimensions_for_family() {
    local family="$1"
    if [[ "$family" == "iphone" ]]; then
        printf '%s\n' "${DEFAULT_IPHONE_DIMENSIONS[@]}"
    else
        printf '%s\n' "${DEFAULT_IPAD_DIMENSIONS[@]}"
    fi
}

join_by_comma() {
    local separator=""
    local output=""
    local item
    for item in "$@"; do
        output="$output$separator$item"
        separator=", "
    done
    printf '%s' "$output"
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

character_count() {
    python3 - "$1" <<'PY'
from pathlib import Path
import sys
print(len(Path(sys.argv[1]).read_text(encoding="utf-8").rstrip("\n")))
PY
}

validate_metadata_policy() {
    local locale_dir="$1"
    local locale="$2"

    python3 - "$locale_dir" "$locale" <<'PY'
from pathlib import Path
import re
import sys

locale_dir = Path(sys.argv[1])
locale = sys.argv[2]

def read(name):
    path = locale_dir / name
    return path.read_text(encoding="utf-8") if path.exists() else ""

text = "\n".join(
    read(name)
    for name in (
        "promotional_text.txt",
        "description.txt",
        "keywords.txt",
        "release_notes.txt",
    )
)
folded = text.casefold()

checks = {
    "en-US": {
        "encrypted storage": ["your data is encrypted when stored"],
        "no bank connections": ["no bank connections"],
        "no ads": ["no ads"],
        "no analytics/tracking": ["no analytics or tracking"],
        "stored in Europe": ["stored in europe"],
    },
    "en-GB": {
        "encrypted storage": ["your data is encrypted when stored"],
        "no bank connections": ["no bank connections"],
        "no ads": ["no ads"],
        "no analytics/tracking": ["no analytics or tracking"],
        "stored in Europe": ["stored in europe"],
    },
    "pt-BR": {
        "encrypted storage": ["seus dados são criptografados quando armazenados"],
        "no bank connections": ["sem conexão com bancos"],
        "no ads": ["sem anúncios"],
        "no analytics/tracking": ["sem analytics ou rastreamento"],
        "stored in Europe": ["armazenados na europa"],
    },
    "pt-PT": {
        "encrypted storage": ["os seus dados são encriptados quando armazenados"],
        "no bank connections": ["sem ligações a bancos"],
        "no ads": ["sem anúncios"],
        "no analytics/tracking": ["sem analytics ou rastreamento"],
        "stored in Europe": ["armazenados na europa"],
    },
    "es-ES": {
        "encrypted storage": ["tus datos se cifran cuando se almacenan"],
        "no bank connections": ["sin conexiones bancarias"],
        "no ads": ["sin anuncios"],
        "no analytics/tracking": ["sin analíticas ni seguimiento"],
        "stored in Europe": ["almacenan en europa"],
    },
    "fr-FR": {
        "encrypted storage": ["vos données sont chiffrées lorsqu’elles sont stockées"],
        "no bank connections": ["aucune connexion bancaire", "sans connexion bancaire"],
        "no ads": ["aucune publicité", "ni publicité"],
        "no analytics/tracking": ["aucune analyse ni aucun suivi"],
        "stored in Europe": ["stockées en europe"],
    },
    "nl-NL": {
        "encrypted storage": ["je gegevens worden versleuteld opgeslagen"],
        "no bank connections": ["geen bankkoppelingen"],
        "no ads": ["geen advertenties"],
        "no analytics/tracking": ["geen analytics of tracking"],
        "stored in Europe": ["in europa opgeslagen"],
    },
    "de-DE": {
        "encrypted storage": ["deine daten werden verschlüsselt gespeichert"],
        "no bank connections": ["keine bankverbindungen"],
        "no ads": ["keine werbung"],
        "no analytics/tracking": ["keine analysefunktionen oder tracking"],
        "stored in Europe": ["in europa gespeichert"],
    },
}

banned = {
    "Overlay references": [
        "overlay",
        "overlays",
        "sobreposição",
        "sobreposições",
        "superposición",
        "superposiciones",
        "superposition",
        "superpositions",
        "überlagerung",
        "überlagerungen",
    ],
    "future pricing promises": [
        "free forever",
        "always free",
        "forever free",
        "gratuito para sempre",
        "sempre gratuito",
        "gratis para siempre",
        "siempre gratis",
        "gratuit pour toujours",
        "toujours gratuit",
        "altijd gratis",
        "voor altijd gratis",
        "für immer kostenlos",
        "immer kostenlos",
    ],
    "technical encryption wording": [
        "encryption at rest",
    ],
}

errors = []
for label, terms in checks.get(locale, {}).items():
    if not any(term in folded for term in terms):
        errors.append(f"{locale}: missing required metadata claim: {label}")

for label, terms in banned.items():
    for term in terms:
        if re.search(rf"(?<![\w-]){re.escape(term)}(?![\w-])", folded):
            errors.append(f"{locale}: banned {label} term found: {term}")

for error in errors:
    print(error, file=sys.stderr)

raise SystemExit(1 if errors else 0)
PY
}

validate_requested "$REQUESTED_LOCALE" "${ALL_LOCALES[@]}"
validate_requested "$REQUESTED_DEVICE_FAMILY" "${ALL_DEVICE_FAMILIES[@]}"

LOCALES=("${ALL_LOCALES[@]}")
DEVICE_FAMILIES=("${ALL_DEVICE_FAMILIES[@]}")
if [[ -n "$REQUESTED_LOCALE" ]]; then
    LOCALES=("$REQUESTED_LOCALE")
fi
if [[ -n "$REQUESTED_DEVICE_FAMILY" ]]; then
    DEVICE_FAMILIES=("$REQUESTED_DEVICE_FAMILY")
fi

REQUIRED_FILES=()
while IFS= read -r metadata_file; do
    REQUIRED_FILES+=("$metadata_file")
done < <(split_values "$REQUIRED_METADATA_FILES")

if [[ ! -d "$SCREENSHOTS_DIR" ]]; then
    echo "Missing Fastlane screenshots directory: $SCREENSHOTS_DIR" >&2
    exit 1
fi
if [[ ! -d "$METADATA_DIR" ]]; then
    echo "Missing Fastlane metadata directory: $METADATA_DIR" >&2
    exit 1
fi

ERRORS=0
TOTAL_SCREENSHOTS=0

for locale in "${LOCALES[@]}"; do
    locale_metadata_dir="$METADATA_DIR/$locale"
    locale_screenshots_dir="$SCREENSHOTS_DIR/$locale"

    if [[ ! -d "$locale_metadata_dir" ]]; then
        echo "Missing metadata locale folder: $locale_metadata_dir" >&2
        ERRORS=$((ERRORS + 1))
    else
        for metadata_file in "${REQUIRED_FILES[@]}"; do
            path="$locale_metadata_dir/$metadata_file"
            if [[ ! -f "$path" ]]; then
                echo "Missing required metadata file: $path" >&2
                ERRORS=$((ERRORS + 1))
            elif [[ ! -s "$path" ]]; then
                echo "Empty required metadata file: $path" >&2
                ERRORS=$((ERRORS + 1))
            fi
        done

        if [[ -f "$locale_metadata_dir/promotional_text.txt" ]]; then
            count="$(character_count "$locale_metadata_dir/promotional_text.txt")"
            if [[ "$count" -gt 170 ]]; then
                echo "promotional_text.txt is too long for $locale: $count characters; max is 170" >&2
                ERRORS=$((ERRORS + 1))
            fi
        fi

        if [[ -f "$locale_metadata_dir/keywords.txt" ]]; then
            count="$(character_count "$locale_metadata_dir/keywords.txt")"
            if [[ "$count" -gt 100 ]]; then
                echo "keywords.txt is too long for $locale: $count characters; max is 100" >&2
                ERRORS=$((ERRORS + 1))
            fi
        fi

        if ! validate_metadata_policy "$locale_metadata_dir" "$locale"; then
            ERRORS=$((ERRORS + 1))
        fi
    fi

    if [[ ! -d "$locale_screenshots_dir" ]]; then
        echo "Missing screenshots locale folder: $locale_screenshots_dir" >&2
        ERRORS=$((ERRORS + 1))
        continue
    fi

    expected_names=()
    for family in "${DEVICE_FAMILIES[@]}"; do
        accepted_dimensions=()
        while IFS= read -r dimension; do
            accepted_dimensions+=("$dimension")
        done < <(accepted_dimensions_for_family "$family")
        accepted_text="$(join_by_comma "${accepted_dimensions[@]}")"

        for final_file in "${FINAL_FILES[@]}"; do
            expected_name="$family-$final_file"
            expected_names+=("$expected_name")
            file="$locale_screenshots_dir/$expected_name"
            TOTAL_SCREENSHOTS=$((TOTAL_SCREENSHOTS + 1))

            if [[ ! -f "$file" ]]; then
                echo "Missing Fastlane screenshot: $file" >&2
                ERRORS=$((ERRORS + 1))
                continue
            fi
            if [[ ! -s "$file" ]]; then
                echo "Empty Fastlane screenshot: $file" >&2
                ERRORS=$((ERRORS + 1))
                continue
            fi

            format="$(png_format "$file")"
            if [[ "$format" != "png" ]]; then
                echo "Fastlane screenshot is not PNG: $file (format: ${format:-unknown})" >&2
                ERRORS=$((ERRORS + 1))
            fi

            if [[ "$(png_has_alpha "$file")" == "yes" ]]; then
                echo "Fastlane screenshot has an alpha channel, which App Store Connect rejects: $file" >&2
                ERRORS=$((ERRORS + 1))
            fi

            dimensions="$(png_dimensions "$file")"
            if [[ -z "$dimensions" ]]; then
                echo "Could not read Fastlane screenshot dimensions: $file" >&2
                ERRORS=$((ERRORS + 1))
            elif ! contains "$dimensions" "${accepted_dimensions[@]}"; then
                echo "Unsupported dimensions for $family screenshot: $file got $dimensions; expected one of: $accepted_text" >&2
                ERRORS=$((ERRORS + 1))
            fi

            size_bytes="$(file_size_bytes "$file")"
            if [[ "$size_bytes" -gt "$MAX_FILE_BYTES" ]]; then
                echo "Fastlane screenshot exceeds size limit: $file is $size_bytes bytes; max is $MAX_FILE_BYTES" >&2
                ERRORS=$((ERRORS + 1))
            fi
        done
    done

    while IFS= read -r actual_file; do
        actual_name="$(basename "$actual_file")"
        if [[ -z "$REQUESTED_DEVICE_FAMILY" ]] && ! contains "$actual_name" "${expected_names[@]}"; then
            echo "Unexpected Fastlane screenshot file: $actual_file" >&2
            ERRORS=$((ERRORS + 1))
        fi
    done < <(find "$locale_screenshots_dir" -maxdepth 1 -type f -name '*.png' -print)
done

if [[ "$ERRORS" -gt 0 ]]; then
    echo "App Store upload package validation failed: $ERRORS issue(s), $TOTAL_SCREENSHOTS expected screenshot(s)." >&2
    exit 1
fi

echo "App Store upload package validation passed: $TOTAL_SCREENSHOTS screenshot(s), ${#LOCALES[@]} locale(s)."
