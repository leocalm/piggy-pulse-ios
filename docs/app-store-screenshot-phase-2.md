# App Store Screenshot Automation Phase 2

Phase 2 captures raw simulator screenshots from the Phase 1 screenshot/demo states. It does not generate App Store frames, export Figma assets, upload to App Store Connect, or change production startup behavior.

## Approach

The capture flow uses a screenshot-only XCUITest:

1. `scripts/capture-raw-screenshots.sh` chooses installed iPhone/iPad simulators.
2. The script boots one simulator family at a time.
3. It applies the simulator status bar override before each capture.
4. It runs `ScreenshotCaptureUITests.testCaptureRawScreenshot` through `xcodebuild test`.
5. The UI test launches PiggyPulse with Phase 1 screenshot launch arguments.
6. The UI test waits for screenshot accessibility markers and writes a PNG to the normalized output path.
7. The script clears the status bar override after each capture and again when the run exits.

## Output

Raw screenshots are written to:

```text
app-store/raw-screenshots/
  iphone/
    en-US/
      01-dashboard-nebula.png
      02-dashboard-electric-neon.png
      03-dashboard-tropical.png
      04-transactions.png
      05-period-configuration.png
      06-categories.png
  ipad/
    en-US/
      01-dashboard-nebula.png
      02-dashboard-electric-neon.png
      03-dashboard-tropical.png
      04-transactions.png
      05-period-configuration.png
      06-categories.png
```

The same locale/state structure is created for all required locales. Files are deterministic and overwritten on rerun.

## Full Capture

Run:

```bash
./scripts/capture-raw-screenshots.sh
```

This captures every required locale and state for one iPhone simulator and one iPad simulator.

Required locales:

- `en-US`
- `en-GB`
- `pt-BR`
- `pt-PT`
- `es-ES`
- `fr-FR`
- `nl-NL`
- `de-DE`

Required states:

- `01-dashboard-nebula`
- `02-dashboard-electric-neon`
- `03-dashboard-tropical`
- `04-transactions`
- `05-period-configuration`
- `06-categories`

## Smoke Capture

For a faster representative run:

```bash
./scripts/capture-raw-screenshots.sh --smoke
```

Smoke mode captures iPhone screenshots for:

- locales: `en-US`, `pt-PT`, `de-DE`
- states: `01-dashboard-nebula`, `04-transactions`, `06-categories`

## Single Locale Or State

Capture one iPhone state:

```bash
./scripts/capture-raw-screenshots.sh \
  --device-family iphone \
  --locale en-US \
  --state 01-dashboard-nebula
```

Capture one iPad state:

```bash
./scripts/capture-raw-screenshots.sh \
  --device-family ipad \
  --locale pt-PT \
  --state 05-period-configuration
```

## Simulator Selection

The script prefers:

- iPhone: `iPhone 17 Pro Max`, then the closest installed large iPhone simulator
- iPad: `iPad Pro 13-inch (M5)`, `iPad Pro 13-inch (M4)`, or `iPad Pro 13-inch`, then the closest installed iPad simulator

If the preferred simulator is missing, the script prints the simulator it selected and writes the chosen devices to:

```text
app-store/raw-screenshots/devices-used.txt
```

To force a specific installed simulator:

```bash
SCREENSHOT_IPHONE_DEVICE="iPhone 17 Pro Max" ./scripts/capture-raw-screenshots.sh --device-family iphone
SCREENSHOT_IPAD_DEVICE="iPad Pro 13-inch (M5)" ./scripts/capture-raw-screenshots.sh --device-family ipad
```

Troubleshoot installed devices with:

```bash
xcrun simctl list devices available
```

## Status Bar

Before each capture, the runner attempts:

```bash
xcrun simctl status_bar booted override \
  --time "09:41" \
  --batteryState charged \
  --batteryLevel 100
```

After each capture and when the run exits, the script clears the override:

```bash
xcrun simctl status_bar booted clear
```

If `status_bar` is unavailable for the local simulator/runtime, the script warns and continues.

## Validation

Validate a full screenshot set:

```bash
./scripts/validate-raw-screenshots.sh
```

Validate the smoke subset:

```bash
./scripts/validate-raw-screenshots.sh --smoke
```

Validation checks:

- required device folders
- required locale folders
- required screenshot filenames
- PNG format
- non-empty files
- consistent image dimensions per device family

## Phase 3 Handoff

Phase 3 should read from `app-store/raw-screenshots/` and place these raw screenshots into the Figma App Store frames. Phase 2 intentionally does not create final framed screenshots, Figma exports, App Store Connect uploads, or external screenshot services.
