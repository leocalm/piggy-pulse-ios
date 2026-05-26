# App Store Screenshot Automation Phase 1

Phase 1 adds deterministic screenshot/demo mode data and stable in-app states. It does not capture screenshots, export Figma frames, upload to App Store Connect, or change production startup behavior.

## Enabling Screenshot Mode

Screenshot mode is opt-in. Launch with environment variables:

```bash
SCREENSHOT_MODE=true
SCREENSHOT_LOCALE=en-US
SCREENSHOT_STATE=01-dashboard-nebula
```

Equivalent launch arguments are also supported:

```bash
--screenshot-mode --screenshot-locale en-US --screenshot-state 01-dashboard-nebula
```

When screenshot mode is enabled, the app skips production auth/network startup, seeds deterministic in-memory demo data, selects the active budget period, applies the requested locale and theme, and routes directly to the requested screen. If the locale, state, or demo data validation fails, startup fails instead of guessing.

## Supported Locales

- `en-US`
- `en-GB`
- `pt-BR`
- `pt-PT`
- `es-ES`
- `fr-FR`
- `nl-NL`
- `de-DE`

## Supported Screenshot States

- `01-dashboard-nebula` - Dashboard, nebula theme
- `02-dashboard-electric-neon` - Dashboard, electric neon theme
- `03-dashboard-tropical` - Dashboard, tropical theme
- `04-transactions` - Transactions, newest first
- `05-period-configuration` - Filled automatic period configuration state
- `06-categories` - Categories with active budgets and progress

Example:

```bash
SCREENSHOT_MODE=true SCREENSHOT_LOCALE=pt-BR SCREENSHOT_STATE=04-transactions
```

For local simulator launches, install the app through Xcode, then launch it with the selected state:

```bash
xcrun simctl launch --terminate-running-process \
  --env SCREENSHOT_MODE true \
  --env SCREENSHOT_LOCALE en-US \
  --env SCREENSHOT_STATE 01-dashboard-nebula \
  booted com.piggypulse.ios
```

To switch states, change only `SCREENSHOT_STATE`. To switch locale, change only `SCREENSHOT_LOCALE`.

## Demo Data

The centralized source of truth lives in `Core/Screenshot/ScreenshotSupport.swift`.

It includes:

- localized screenshot data fields
- localized App Store frame copy
- localized vendors and account names
- per-locale opening balances and budget targets
- deterministic bi-weekly periods using reference date `2026-05-15`
- 120+ deterministic transactions per locale across `2026-03-02` to `2026-05-15`
- active-period transactions for `2026-05-11` to `2026-05-24`

The data is applied to the existing decrypted in-memory data store only when screenshot mode is explicitly enabled.

The period configuration screenshot uses the app's existing localized `AutoCreationView` form with deterministic day-of-month settings. The current iOS app does not expose a carry-over category budget setting, so Phase 1 does not add one to the screenshot state.

## Adding A Locale

Add the locale to `ScreenshotLocaleID`, then add matching entries in:

- `localeContent`
- `frameCopy`
- `accountNames`
- `openingBalances`
- `budgetTargets`
- `vendors`
- salary, rent, allowance, and savings amount tables

Run the unit tests. Validation requires every locale to contain the same screenshot states and required data groups.

## Validation

`ScreenshotDemoCatalog.validate()` checks:

- every required locale exists
- every screenshot ID has title and subtitle
- required vendors, account names, categories, and budget targets exist
- currency code exists
- transaction generation produces at least 120 transactions
- transaction IDs are unique
- active period has transactions
- transactions state has at least 8 recent transactions
- dashboard categories have non-zero progress

The unit tests in `PiggyPulseTests/ScreenshotDemoDataTests.swift` cover completeness and generator determinism.

## Status Bar For Phase 2

Before capture in Phase 2, set simulator status bar state:

```bash
xcrun simctl status_bar booted override --time "09:41" --batteryState charged --batteryLevel 100
```

Use clean/default signal and Wi-Fi indicators where possible.

## Out Of Scope

Phase 1 intentionally does not implement raw screenshot capture, Figma export, App Store Connect upload, external screenshot services, or persistent demo data storage.
