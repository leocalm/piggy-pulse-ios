# Light Theme Design

**Date:** 2026-03-09
**Branch:** feat/light-theme

## Summary

Add a light color palette to the design system and wire the user's saved theme preference (system/light/dark) to actually change the app's color scheme at runtime.

## Color System

Extend `Design/Theme.swift` with `ColorScheme`-aware computed properties. Call sites (`Color.ppBackground`, etc.) remain unchanged.

### Light Palette

| Token | Dark | Light |
|-------|------|-------|
| ppBackground | #0a0e14 | #F2F4F7 |
| ppSurface | #0f1319 | #FFFFFF |
| ppCard | #151b26 | #FFFFFF |
| ppTextPrimary | white | black |
| ppTextSecondary | #828c9e | #5A6272 |
| ppTextTertiary | #5a6272 | #828C9E |
| ppBorder | white 6% | black 8% |
| ppBorderHover | white 12% | black 15% |

Brand colors (ppPrimary, ppCyan, ppAmber, ppTeal, ppDestructive) are unchanged — they work on both backgrounds.

## AppState

Add `var appColorScheme: ColorScheme? = nil` (nil = system default).

- On launch: read from `UserDefaults` key `"appTheme"` (`"system"` → nil, `"light"` → `.light`, `"dark"` → `.dark`)
- On settings save: update `appState.appColorScheme` immediately after a successful API call

## App Entry Point

Replace `.preferredColorScheme(.dark)` with `.preferredColorScheme(appState.appColorScheme)`.

## Settings Wiring

After the existing `PUT /settings/preferences` succeeds, set `appState.appColorScheme` and persist to `UserDefaults`. No restart required.
