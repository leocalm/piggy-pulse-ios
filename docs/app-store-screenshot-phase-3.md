# App Store Screenshot Automation Phase 3

Phase 3 prepares final App Store screenshot export from the existing PiggyPulse Figma App Store frames. Figma remains the source of truth for layout, typography, spacing, backgrounds, device framing, and visual design.

This phase does not recreate the frame design in code, generate App Store Connect uploads, or change production app behavior.

## Workflow Chosen

This repo implements a Figma plugin payload workflow, not a custom frame renderer.

The base iPhone and iPad Figma template frames have been renamed to stable `appstore.*` role names, so a Figma plugin can safely identify title, subtitle, and screenshot layers. The current Codex/Figma bridge can inspect and rename the file and prepare structured data, but it is not a reliable local-file exporter for final PNGs. The final export step still happens in Figma through a plugin workflow.

The safe Phase 3 workflow is:

```bash
./scripts/prepare-figma-screenshot-payload.sh
# Run/import app-store/figma-export-payload.json in the Figma plugin workflow.
./scripts/validate-final-screenshots.sh
```

For the available Phase 2 smoke screenshots:

```bash
./scripts/prepare-figma-screenshot-payload.sh --smoke
```

## Prerequisites

Generate and validate raw screenshots from Phase 2 first:

```bash
./scripts/capture-raw-screenshots.sh
./scripts/validate-raw-screenshots.sh
```

Expected raw screenshot input:

```text
app-store/raw-screenshots/
  iphone/{locale}/{state}.png
  ipad/{locale}/{state}.png
```

Required locales:

- `en-US`
- `en-GB`
- `pt-BR`
- `pt-PT`
- `es-ES`
- `fr-FR`
- `nl-NL`
- `de-DE`

## Figma File

File key:

```text
J7z9DMAHQ1O7gsUoPt84Vj
```

File URL:

```text
https://www.figma.com/design/J7z9DMAHQ1O7gsUoPt84Vj/PiggyPulse
```

Frame mapping is stored in:

```text
app-store/figma-frame-map.json
```

## Figma Node Mapping

iPhone page:

```text
670:519
```

iPhone template frames:

- Dashboard: `670:540`
- Themes: `670:525`
- Transactions: `670:535`
- Periods: `670:530`
- Categories: `670:520`

iPad page:

```text
687:548
```

iPad template frames:

- Dashboard: `691:2`
- Themes: `691:17`
- Transactions: `691:7`
- Periods: `691:12`
- Categories: `691:24`

## Template Layer Names

The Phase 3 payload targets the base template frames listed above. Those templates now use these stable layer names.

Standard frames:

- `appstore.title`
- `appstore.subtitle`
- `appstore.screenshot`

Themes frame:

- `appstore.title`
- `appstore.subtitle`
- `appstore.screenshot.nebula`
- `appstore.screenshot.electric-neon`
- `appstore.screenshot.tropical`

Localized duplicate rows in the Figma file may still use legacy layer names. They are not used by this workflow unless the frame map is changed to point at them.

## Screenshot State Mapping

There are six raw states and five final frames:

- `01-dashboard-nebula` -> Dashboard frame and Themes Nebula slot
- `02-dashboard-electric-neon` -> Themes Electric Neon slot
- `03-dashboard-tropical` -> Themes Tropical slot
- `04-transactions` -> Transactions frame
- `05-period-configuration` -> Periods frame
- `06-categories` -> Categories frame

Final output names:

- `01-dashboard.png`
- `02-themes.png`
- `03-transactions.png`
- `04-periods.png`
- `05-categories.png`

## Frame Copy Mapping

Localized title/subtitle copy is derived from the centralized Phase 1 Swift source:

```text
Core/Screenshot/ScreenshotSupport.swift
```

The payload generator reads `ScreenshotDemoBuilder.frameCopy`; it does not duplicate localized copy.

Frame copy mapping:

- Dashboard frame -> `01-dashboard-nebula`
- Themes frame -> `02-dashboard-electric-neon`
- Transactions frame -> `04-transactions`
- Periods frame -> `05-period-configuration`
- Categories frame -> `06-categories`

If copy is missing for a locale/state, payload generation fails.

## Payload Generation

Generate the full Figma plugin payload:

```bash
./scripts/prepare-figma-screenshot-payload.sh
```

Generate a single locale/device payload:

```bash
./scripts/prepare-figma-screenshot-payload.sh \
  --device-family iphone \
  --locale en-US
```

Generate a single frame payload:

```bash
./scripts/prepare-figma-screenshot-payload.sh \
  --device-family ipad \
  --locale pt-PT \
  --frame periods
```

Output:

```text
app-store/figma-export-payload.json
```

The payload includes:

- Figma file key
- page and template frame node IDs
- target locale
- localized title/subtitle
- raw screenshot paths
- expected final output path
- expected final export dimensions
- current layer inspection
- required stable layer names

Generated payloads are ignored by Git.

## Plugin Consumption

A Figma plugin should consume `app-store/figma-export-payload.json` and, for each item:

1. Open the file `J7z9DMAHQ1O7gsUoPt84Vj`.
2. Duplicate or target the listed template frame.
3. Find role layers by the stable `appstore.*` names.
4. Replace the screenshot layer fills with the referenced raw PNGs.
5. Update `appstore.title` and `appstore.subtitle` with payload copy.
6. Export the frame as PNG to the listed `outputPath`.

For Themes frames, the plugin must use:

- `appstore.screenshot.nebula` for `01-dashboard-nebula`
- `appstore.screenshot.electric-neon` for `02-dashboard-electric-neon`
- `appstore.screenshot.tropical` for `03-dashboard-tropical`

## Final Output

Expected final screenshot output:

```text
app-store/final-screenshots/
  iphone/
    en-US/
      01-dashboard.png
      02-themes.png
      03-transactions.png
      04-periods.png
      05-categories.png
  ipad/
    en-US/
      01-dashboard.png
      02-themes.png
      03-transactions.png
      04-periods.png
      05-categories.png
```

The same locale structure is expected for every required locale. Generated final screenshots are ignored by Git.

## Validation

Validate final screenshots:

```bash
./scripts/validate-final-screenshots.sh
```

Validate a subset:

```bash
./scripts/validate-final-screenshots.sh \
  --device-family iphone \
  --locale en-US
```

Validation checks:

- every required device folder exists
- every required locale folder exists
- all five final PNG files exist
- PNG files are non-empty
- PNG dimensions match expected Figma/App Store export dimensions
- files are under the configured file size limit
- no extra `.png` files exist in expected locale folders

Default final export dimensions:

- iPhone: `1290x2796`
- iPad: `2048x2732`

Override dimensions for future Figma templates:

```bash
SCREENSHOT_FINAL_IPHONE_DIMENSIONS="1290x2796,1320x2868" \
  ./scripts/validate-final-screenshots.sh --device-family iphone

SCREENSHOT_FINAL_IPAD_DIMENSIONS="2048x2732,2064x2752" \
  ./scripts/validate-final-screenshots.sh --device-family ipad
```

## Troubleshooting

If payload generation fails, check:

- raw screenshots exist under `app-store/raw-screenshots/`
- the requested locale/device/state exists
- `Core/Screenshot/ScreenshotSupport.swift` still contains `ScreenshotDemoBuilder.frameCopy`
- `app-store/figma-frame-map.json` still matches the Figma templates

If plugin export fails, check:

- the Figma frame map still points at the renamed base template frames
- Figma layers still use the required `appstore.*` names
- Themes screenshot layers were assigned explicitly
- the plugin can read local raw PNG paths
- the plugin writes to `app-store/final-screenshots/`

## Adding A Locale

1. Add the locale to Phase 1 screenshot data and frame copy.
2. Run Phase 1 screenshot data validation tests.
3. Capture raw screenshots for the locale with Phase 2.
4. Run `./scripts/prepare-figma-screenshot-payload.sh --locale <locale>`.
5. Export final Figma frames for that locale.
6. Run `./scripts/validate-final-screenshots.sh --locale <locale>`.

## Out Of Scope

Phase 3 does not upload to App Store Connect. It also does not replace the existing Figma frame design with a code renderer.
