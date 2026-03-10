# Notifications — Design Spec

Date: 2026-03-10
Branch: feat/notifications

## Summary

Add local push notifications to PiggyPulse iOS. Notifications are calm, reflective — no budget-overspending alerts. All scheduling is on-device using `UserNotifications` framework, with background refresh to keep notifications up to date without requiring the app to be opened.

## Notification Types

| Type | Trigger | Example copy |
|---|---|---|
| `periodStarting` | At period start date | "A new period has begun. Time to reflect." |
| `periodSummary` | At period end date | "Your March period has wrapped up. Tap to reflect." |
| `overlayStarting` | At overlay start date | "A new overlay has started." |
| `overlayEnding` | At overlay end date | "Your overlay ends today." |

## Architecture

### `NotificationScheduler`

A Swift `actor` responsible for all scheduling. Owned by `AppState`.

**Responsibilities:**
- Request `UNUserNotificationCenter` authorization on first enable
- Clear all pending notifications with the app prefix (`piggy-pulse.`)
- Fetch upcoming periods and overlays (via existing repositories)
- Schedule `UNNotificationRequest`s for each enabled type, up to 30 days ahead

**Called from:**
- App foreground (via `AppState.checkAuth` / `.task`)
- Background refresh task

### `NotificationPreferences`

Lightweight value type backed by `UserDefaults`. Keys:

```
notifications.enabled           Bool  (master toggle)
notifications.periodStarting    Bool
notifications.periodSummary     Bool
notifications.overlayLifecycle  Bool
```

No server persistence — preferences are local only.

## Settings UI

New **NOTIFICATIONS** card in `SettingsView`, following existing card pattern:

```
NOTIFICATIONS
  Notifications          [toggle — master]
  ──────────────────────────────────────
  Period starting        [toggle]
  Period summary         [toggle]
  Overlay lifecycle      [toggle]
```

Individual toggles are disabled when master is off. Enabling master for the first time triggers the system permission prompt. If permission is denied, master toggle reflects system state.

## Background Refresh

Registered via `BGTaskScheduler` with identifier `com.piggypulse.notifications.refresh`.

- Registered in `PiggyPulseApp.init`
- Submitted after each foreground scheduling run
- Task calls `NotificationScheduler.scheduleAll()` and completes

`Info.plist` requires `BGTaskSchedulerPermittedIdentifiers` entry.

## Scheduling Logic

On each scheduling run:
1. Check master `notifications.enabled` — exit early if false
2. Check system authorization — exit early if not authorized
3. Remove all pending requests with prefix `piggy-pulse.`
4. Fetch periods from API (next 30 days)
5. Fetch overlays from API (active + upcoming)
6. For each period, schedule enabled notification types
7. For each overlay, schedule enabled lifecycle notifications
8. Submit next background refresh task

## Files to Create / Modify

- `Core/Notifications/NotificationScheduler.swift` — new
- `Core/Notifications/NotificationPreferences.swift` — new
- `Features/Settings/Views/SettingsView.swift` — add NOTIFICATIONS card
- `App/AppState.swift` — add `NotificationScheduler` instance, call on launch
- `App/PiggyPulseApp.swift` — register BGTask, call scheduler on foreground
- `PiggyPulse-Info.plist` — add `BGTaskSchedulerPermittedIdentifiers`
