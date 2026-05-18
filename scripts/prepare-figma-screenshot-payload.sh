#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

INPUT_DIR="$PROJECT_DIR/app-store/raw-screenshots"
OUTPUT_DIR="$PROJECT_DIR/app-store/final-screenshots"
PAYLOAD_PATH="$PROJECT_DIR/app-store/figma-export-payload.json"
FRAME_MAP_PATH="$PROJECT_DIR/app-store/figma-frame-map.json"
COPY_SOURCE_PATH="$PROJECT_DIR/Core/Screenshot/ScreenshotSupport.swift"
SMOKE=0
REQUESTED_DEVICE_FAMILY=""
REQUESTED_LOCALE=""
REQUESTED_FRAME=""

ALL_DEVICE_FAMILIES=("iphone" "ipad")
ALL_LOCALES=("en-US" "en-GB" "pt-BR" "pt-PT" "es-ES" "fr-FR" "nl-NL" "de-DE")
ALL_FRAMES=("dashboard" "themes" "transactions" "periods" "categories")
SMOKE_LOCALES=("en-US" "pt-PT" "de-DE")
SMOKE_FRAMES=("dashboard" "transactions" "categories")

usage() {
    cat <<USAGE
Usage: scripts/prepare-figma-screenshot-payload.sh [options]

Options:
  --smoke                   Build a payload for the available Phase 2 smoke subset.
  --device-family FAMILY    Include only iphone or ipad.
  --locale LOCALE           Include only one locale.
  --frame FRAME             Include only one final frame: dashboard, themes, transactions, periods, categories.
  --input-dir DIR           Raw screenshot directory. Default: app-store/raw-screenshots.
  --output-dir DIR          Final screenshot directory referenced in the payload. Default: app-store/final-screenshots.
  --payload PATH            Output payload path. Default: app-store/figma-export-payload.json.
  --frame-map PATH          Figma frame map path. Default: app-store/figma-frame-map.json.
  --copy-source PATH        Swift screenshot copy source. Default: Core/Screenshot/ScreenshotSupport.swift.
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
        --frame)
            REQUESTED_FRAME="${2:-}"
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
        --payload)
            PAYLOAD_PATH="${2:-}"
            shift 2
            ;;
        --frame-map)
            FRAME_MAP_PATH="${2:-}"
            shift 2
            ;;
        --copy-source)
            COPY_SOURCE_PATH="${2:-}"
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

join_by_comma() {
    local separator=""
    local output=""
    local item
    for item in "$@"; do
        output="$output$separator$item"
        separator=","
    done
    printf '%s' "$output"
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

DEVICE_FAMILIES_CSV="$(join_by_comma "${DEVICE_FAMILIES[@]}")"
LOCALES_CSV="$(join_by_comma "${LOCALES[@]}")"
FRAMES_CSV="$(join_by_comma "${FRAMES[@]}")"

python3 - "$FRAME_MAP_PATH" "$COPY_SOURCE_PATH" "$INPUT_DIR" "$OUTPUT_DIR" "$PAYLOAD_PATH" "$DEVICE_FAMILIES_CSV" "$LOCALES_CSV" "$FRAMES_CSV" <<'PY'
import json
import os
import re
import sys
from datetime import datetime, timezone

frame_map_path, copy_source_path, input_dir, output_dir, payload_path, devices_csv, locales_csv, frames_csv = sys.argv[1:9]
devices = [item for item in devices_csv.split(",") if item]
locales = [item for item in locales_csv.split(",") if item]
frames = [item for item in frames_csv.split(",") if item]

locale_tokens = {
    "enUS": "en-US",
    "enGB": "en-GB",
    "ptBR": "pt-BR",
    "ptPT": "pt-PT",
    "esES": "es-ES",
    "frFR": "fr-FR",
    "nlNL": "nl-NL",
    "deDE": "de-DE",
}
state_tokens = {
    "dashboardNebula": "01-dashboard-nebula",
    "dashboardElectricNeon": "02-dashboard-electric-neon",
    "dashboardTropical": "03-dashboard-tropical",
    "transactions": "04-transactions",
    "periodConfiguration": "05-period-configuration",
    "categories": "06-categories",
}

def read_json(path):
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)

def parse_frame_copy(path):
    with open(path, "r", encoding="utf-8") as handle:
        source = handle.read()

    match = re.search(
        r"static let frameCopy:\s*\[ScreenshotLocaleID:\s*\[ScreenshotStateID:\s*ScreenshotFrameCopy\]\]\s*=\s*\[(.*?)\n\s*\]",
        source,
        re.DOTALL,
    )
    if not match:
        raise ValueError("Could not find ScreenshotDemoBuilder.frameCopy in Swift source.")

    copy = {}
    for locale_token, body in re.findall(r"\.(\w+):\s*\[(.*?)\](?:,|$)", match.group(1), re.DOTALL):
        locale = locale_tokens.get(locale_token)
        if not locale:
            continue
        copy[locale] = {}
        for state_token, title, subtitle in re.findall(
            r"\.(\w+):\s*\.init\(title:\s*\"((?:[^\"\\]|\\.)*)\",\s*subtitle:\s*\"((?:[^\"\\]|\\.)*)\"\)",
            body,
        ):
            state = state_tokens.get(state_token)
            if state:
                copy[locale][state] = {"title": title, "subtitle": subtitle}
    return copy

errors = []

if not os.path.isfile(frame_map_path):
    errors.append(f"Missing Figma frame map: {frame_map_path}")
if not os.path.isfile(copy_source_path):
    errors.append(f"Missing screenshot copy source: {copy_source_path}")
if not os.path.isdir(input_dir):
    errors.append(f"Missing raw screenshot directory: {input_dir}")

if errors:
    for error in errors:
        print(error, file=sys.stderr)
    sys.exit(1)

frame_map = read_json(frame_map_path)
frame_copy = parse_frame_copy(copy_source_path)
payload_items = []

for device in devices:
    device_map = frame_map.get("deviceFamilies", {}).get(device)
    if not device_map:
        errors.append(f"Missing Figma device map: {device}")
        continue

    for locale in locales:
        locale_copy = frame_copy.get(locale)
        if not locale_copy:
            errors.append(f"Missing localized frame copy for {locale}")
            continue

        for frame_key in frames:
            final_frame = frame_map.get("finalFrames", {}).get(frame_key)
            figma_frame = device_map.get("frames", {}).get(frame_key)
            if not final_frame:
                errors.append(f"Missing final frame mapping: {frame_key}")
                continue
            if not figma_frame:
                errors.append(f"Missing Figma node mapping for {device}/{frame_key}")
                continue

            copy_state = final_frame["copyState"]
            copy = locale_copy.get(copy_state)
            if not copy or not copy.get("title") or not copy.get("subtitle"):
                errors.append(f"Missing title/subtitle for {locale}/{copy_state}")
                continue

            raw_screenshots = {}
            for raw_state in final_frame["rawStates"]:
                raw_path = os.path.join(input_dir, device, locale, f"{raw_state}.png")
                raw_screenshots[raw_state] = raw_path
                if not os.path.isfile(raw_path):
                    errors.append(f"Missing raw screenshot for {device}/{locale}/{frame_key}: {raw_path}")

            payload_items.append(
                {
                    "deviceFamily": device,
                    "locale": locale,
                    "frame": frame_key,
                    "templateNodeId": figma_frame["templateNodeId"],
                    "templateName": figma_frame["templateName"],
                    "copy": copy,
                    "copyState": copy_state,
                    "rawScreenshots": raw_screenshots,
                    "outputFile": final_frame["outputFile"],
                    "outputPath": os.path.join(output_dir, device, locale, final_frame["outputFile"]),
                    "expectedFinalDimensions": device_map["finalExportDimensions"],
                    "layerRequirements": frame_map["requiredLayerNames"]["themes" if frame_key == "themes" else "standard"],
                    "currentLayerInspection": figma_frame["currentLayers"],
                }
            )

if errors:
    for error in errors:
        print(error, file=sys.stderr)
    sys.exit(1)

safe_to_auto_apply = frame_map.get("layerNamingStatus") in {
    "base-templates-renamed",
    "ready-for-plugin",
}
safe_to_auto_apply_reason = (
    "Base Figma template frames use stable appstore.* role names for plugin updates."
    if safe_to_auto_apply
    else "Figma layers do not use stable appstore.* role names; rename template layers before plugin updates."
)

payload = {
    "schemaVersion": 1,
    "generatedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "workflow": "figma-plugin-payload",
    "safeToAutoApply": safe_to_auto_apply,
    "safeToAutoApplyReason": safe_to_auto_apply_reason,
    "figma": {
        "fileKey": frame_map["fileKey"],
        "iphonePageNodeId": frame_map["deviceFamilies"]["iphone"]["pageNodeId"],
        "ipadPageNodeId": frame_map["deviceFamilies"]["ipad"]["pageNodeId"],
    },
    "requiredLayerNames": frame_map["requiredLayerNames"],
    "selected": {
        "deviceFamilies": devices,
        "locales": locales,
        "frames": frames,
    },
    "inputs": {
        "rawScreenshotDirectory": input_dir,
        "frameCopySource": copy_source_path,
        "frameMap": frame_map_path,
    },
    "outputs": {
        "finalScreenshotDirectory": output_dir,
    },
    "items": payload_items,
}

os.makedirs(os.path.dirname(payload_path), exist_ok=True)
with open(payload_path, "w", encoding="utf-8") as handle:
    json.dump(payload, handle, ensure_ascii=False, indent=2)
    handle.write("\n")

print(f"Wrote Figma screenshot payload: {payload_path}")
print(f"Payload items: {len(payload_items)}")
PY
