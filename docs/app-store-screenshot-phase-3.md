# App Store Screenshot Automation Phase 3

Phase 3 generates final PiggyPulse App Store framed screenshots directly in code from the validated raw simulator screenshots captured in Phase 2.

This workflow does not open Figma, require a Figma token, upload to App Store Connect, or change production app behavior.

## Workflow Chosen

The primary workflow is a local Python/Pillow frame generator:

```bash
./scripts/capture-raw-screenshots.sh
./scripts/validate-raw-screenshots.sh
./scripts/generate-app-store-frames.sh
./scripts/validate-final-screenshots.sh
```

The previous Figma payload workflow is no longer the primary Phase 3 path. `scripts/prepare-figma-screenshot-payload.sh` and `app-store/figma-frame-map.json` may remain useful as a legacy/manual reference, but final App Store frames are generated locally by `scripts/generate-app-store-frames.sh`.

## Inputs

Raw screenshots must exist under:

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

Required raw states:

- `01-dashboard-nebula`
- `02-dashboard-electric-neon`
- `03-dashboard-tropical`
- `04-transactions`
- `05-period-configuration`
- `06-categories`

Localized title/subtitle copy is read from the centralized Phase 1 source:

```text
Core/Screenshot/ScreenshotSupport.swift
```

The generator reads `ScreenshotDemoBuilder.frameCopy`; it does not duplicate localized frame copy.

## Output

Final screenshots are written to:

```text
app-store/final-screenshots/
  iphone/
    en-US/
      01-dashboard.png
      02-themes.png
      03-transactions.png
      04-periods.png
      05-categories.png
    ...
  ipad/
    en-US/
      01-dashboard.png
      02-themes.png
      03-transactions.png
      04-periods.png
      05-categories.png
    ...
```

Generated final screenshots are ignored by Git.

## Frame Mapping

There are six raw states and five final frames:

- `01-dashboard.png` uses `01-dashboard-nebula`
- `02-themes.png` uses `01-dashboard-nebula`, `02-dashboard-electric-neon`, and `03-dashboard-tropical`
- `03-transactions.png` uses `04-transactions`
- `04-periods.png` uses `05-period-configuration`
- `05-categories.png` uses `06-categories`

Frame copy mapping:

- `01-dashboard.png` uses copy from `01-dashboard-nebula`
- `02-themes.png` uses copy from `02-dashboard-electric-neon`
- `03-transactions.png` uses copy from `04-transactions`
- `04-periods.png` uses copy from `05-period-configuration`
- `05-categories.png` uses copy from `06-categories`

## Visual Design

The generated frames use a polished dark PiggyPulse layout:

- background: `#0D1117`
- card: `#161B22`
- primary: `#8B7EC8`
- secondary: `#C48BA0`
- tertiary: `#7CA8C4`

Every final frame includes:

- localized title and subtitle at the top
- rounded screenshot cards
- subtle shadows and accent glows
- responsive text wrapping for longer localized copy
- final output dimensions matching the raw App Store screenshot size for the device family

The Themes frame places all three dashboard theme screenshots in one overlapping composition, with the center screenshot in front and no background card behind the devices.

## Generate Final Frames

Generate all locales and both device families:

```bash
./scripts/generate-app-store-frames.sh
```

Generate the smoke subset:

```bash
./scripts/generate-app-store-frames.sh --smoke
```

Generate one locale/device/frame:

```bash
./scripts/generate-app-store-frames.sh \
  --device-family iphone \
  --locale en-US \
  --frame dashboard
```

Options:

```text
--smoke
--device-family iphone|ipad
--locale en-US|en-GB|pt-BR|pt-PT|es-ES|fr-FR|nl-NL|de-DE
--frame dashboard|themes|transactions|periods|categories
--input-dir app-store/raw-screenshots
--output-dir app-store/final-screenshots
--copy-source Core/Screenshot/ScreenshotSupport.swift
--font-path /path/to/font.ttf
```

## Font Handling

No font files are committed.

By default, the generator uses macOS system fonts in this order:

- SF Pro Display Semibold / SF Pro Text
- SFNS
- Arial fallback

To force a specific local font:

```bash
APPSTORE_FRAME_FONT_PATH="/path/to/font.ttf" ./scripts/generate-app-store-frames.sh
```

The same value can be passed with `--font-path`.

## Validation

Validate final screenshots:

```bash
./scripts/validate-final-screenshots.sh
```

Validate the smoke subset:

```bash
./scripts/validate-final-screenshots.sh --smoke
```

Validation checks:

- every required device folder exists
- every required locale folder exists
- all five final PNG files exist
- PNG files are non-empty
- PNG dimensions are App Store-valid for the device family
- files are under the configured file size limit
- no extra `.png` files exist in expected locale folders during full validation

Default accepted final dimensions:

- iPhone: `1320x2868`, `1290x2796`, `1179x2556`
- iPad: `2064x2752`, `2048x2732`, `1488x2266`, `1668x2420`, `1668x2388`, `1640x2360`

Override dimensions if a future simulator produces another App Store-valid size:

```bash
SCREENSHOT_FINAL_IPHONE_DIMENSIONS="1320x2868,1290x2796" \
  ./scripts/validate-final-screenshots.sh --device-family iphone

SCREENSHOT_FINAL_IPAD_DIMENSIONS="2064x2752,2048x2732" \
  ./scripts/validate-final-screenshots.sh --device-family ipad
```

## Troubleshooting

If generation fails, check:

- Phase 2 raw screenshots exist under `app-store/raw-screenshots/`
- raw screenshot validation passes
- `Core/Screenshot/ScreenshotSupport.swift` still contains `ScreenshotDemoBuilder.frameCopy`
- every locale has title/subtitle copy for the mapped states
- Pillow is available in the Python environment
- the selected font path exists if `APPSTORE_FRAME_FONT_PATH` or `--font-path` is used

If validation fails, check:

- final files are under `app-store/final-screenshots/{device}/{locale}/`
- filenames match exactly and are not localized
- generated dimensions are in the accepted dimension list
- the output directory does not contain stale or extra `.png` files during full validation

## Adding A Locale

1. Add the locale to Phase 1 screenshot data and frame copy.
2. Run Phase 1 screenshot data validation tests.
3. Capture raw screenshots for the locale with Phase 2.
4. Run `./scripts/generate-app-store-frames.sh --locale <locale>`.
5. Run `./scripts/validate-final-screenshots.sh --locale <locale>`.

## Out Of Scope

Phase 3 does not upload to App Store Connect. It also does not open Figma or generate Figma payloads as the primary workflow.
