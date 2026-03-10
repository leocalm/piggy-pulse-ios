# Face ID / Touch ID Support — Design Spec
Date: 2026-03-10

## Overview

Add optional biometric authentication (Face ID / Touch ID) to PiggyPulse iOS. Disabled by default. When enabled, the app locks on background and requires biometric (or passcode fallback) to resume.

## Architecture

### AppState additions
- `biometricEnabled: Bool` — persisted in `UserDefaults`, default `false`
- `isBiometricLocked: Bool` — in-memory, default `false`
- `lastBackgroundedAt: Date?` — in-memory timestamp, set on `.background` scene phase
- `lockIfNeeded()` — called on `.active`; locks if `biometricEnabled && elapsed > 10s`
- `unlockWithBiometrics() async` — calls `BiometricHelper.authenticate()`, sets `isBiometricLocked = false` on success

### Grace period
10 seconds in-memory. Not persisted — app kill always requires unlock on next launch if enabled.

### Scene phase handling
In `PiggyPulseApp`, observe `scenePhase`:
- `.background` → record `lastBackgroundedAt`
- `.active` → call `appState.lockIfNeeded()`

### RootView
Wrap existing content in a `ZStack`. When `appState.isBiometricLocked`, show `BiometricLockView` on top.

## Components

### `BiometricHelper`
Thin wrapper around `LAContext`:
- `authenticate() async throws` — uses `.deviceOwnerAuthentication` (allows passcode fallback)
- `availableBiometryType() -> LABiometryType` — returns `.faceID`, `.touchID`, or `.none`

### `BiometricLockView`
Full-screen overlay:
- App icon / branding
- SF Symbol adapts: `faceid` for Face ID, `touchid` for Touch ID
- "Unlock with Face ID / Touch ID" button — triggers auth on appear and on tap
- "Try Again" shown on failure
- No dismiss without successful auth

### SettingsView — Security card
- New `Toggle` row: "Face ID" / "Touch ID" / "Biometrics" (label from `LABiometryType`)
- Enabling: triggers immediate biometric prompt to confirm enrollment; only enables on success
- Disabling: clears `biometricEnabled`, sets `isBiometricLocked = false`
- If biometrics unavailable/not enrolled: toggle disabled with subtitle explanation

## Error Handling

| Scenario | Behavior |
|---|---|
| Biometrics not enrolled | Toggle disabled, subtitle: "Face ID not set up on this device" |
| Auth failure (wrong face/finger) | Stay locked, show "Try Again" |
| User cancels | Stay locked (finance app — no escape without auth) |
| Passcode fallback | Handled natively by `.deviceOwnerAuthentication` |

## Storage
- `UserDefaults` key: `"biometricEnabled"` (Bool)
- No Keychain involvement — this is an app-level lock, not credential storage

## Testing
- Unit test `BiometricHelper` with mock `LAContext`
- Unit test `AppState.lockIfNeeded()` grace period logic
- Manual: enable toggle, background app, foreground → lock screen appears
- Manual: Face ID/Touch ID success → unlocks; cancel → stays locked
