# Testing Local Notifications

A quick guide for manually testing the notification feature on a real device.

---

## Prerequisites

- App running on your iPhone via Xcode (USB or wireless)
- At least one budget period in the app

---

## 1. Verify notifications are enabled

1. Open the app and go to **Settings**
2. Confirm the **NOTIFICATIONS** card is present
3. Toggle **Notifications** on — the system permission dialog should appear the first time
4. Tap **Allow**

---

## 2. See a notification fire immediately (recommended for quick testing)

By default notifications fire at midnight on the event date. To test without waiting, make a temporary code change:

**In `Core/Notifications/NotificationScheduler.swift`**, find the `request(id:date:content:)` helper at the bottom of the file and replace:

```swift
// Original — fires at the event date
let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
```

with:

```swift
// TEMPORARY for testing — fires after 5 seconds
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
```

Run the app. Within 5 seconds of launch you'll receive a notification for each upcoming event within the next 30 days.

**Remember to revert this change before committing.**

---

## 3. Test specific notification types

### Period starting
1. Create a new budget period with a start date of **tomorrow**
2. Launch the app (or use Simulate Background Fetch — see section 4)
3. With the 5-second trigger: notification arrives within 5 seconds
4. Expected: *"New period starting — [Period name] begins today. Time to reflect."*

### Period summary
1. Create a period with an end date of **tomorrow**
2. Same as above
3. Expected: *"Period wrapped up — [Period name] has ended. Tap to reflect on your spending."*

### Overlay starting / ending
1. Create an overlay with a start or end date of **tomorrow**
2. Same as above
3. Expected: *"Overlay starting — [Overlay name] begins today."* or *"Overlay ending — [Overlay name] ends today."*

---

## 4. Test background refresh (without the 5-second shortcut)

This simulates the app being woken by iOS in the background and rescheduling notifications without the user opening the app.

1. Create a period starting or ending within the next 30 days
2. Background the app (press Home)
3. In Xcode: **Debug menu → Simulate Background Fetch**
4. The app wakes briefly, fetches data, and schedules notifications
5. Check scheduled notifications in the Xcode debugger:

```
(lldb) po UNUserNotificationCenter.current().pendingNotificationRequests()
```

Or add a temporary debug print in `scheduleAll` to log identifiers.

---

## 5. Test the Settings toggles

### Master toggle off
1. Open Settings → toggle **Notifications** off
2. Relaunch the app
3. No notifications should be scheduled (verify via lldb above)

### Individual toggle off
1. Toggle **Period starting** off, leave others on
2. Relaunch
3. Only period-summary and overlay notifications should be scheduled

### Permission denied snap-back
1. Go to **iOS Settings → PiggyPulse → Notifications → turn off**
2. Back in the app, go to Settings and toggle **Notifications** on
3. The toggle should snap back to off immediately (since system permission is denied)
4. To re-enable: go back to iOS Settings → PiggyPulse → Notifications → Allow

---

## 6. Checklist before shipping

- [ ] Notification permission prompt appears exactly once (on first enable)
- [ ] Force-quit and relaunch — prompt does NOT appear again
- [ ] Period starting notification fires correctly
- [ ] Period summary notification fires correctly
- [ ] Overlay starting notification fires correctly
- [ ] Overlay ending notification fires correctly
- [ ] Master toggle off → no notifications scheduled
- [ ] Individual toggle off → that type not scheduled, others still are
- [ ] Permission denied → master toggle snaps back to off
- [ ] Revert `UNTimeIntervalNotificationTrigger` change if used
