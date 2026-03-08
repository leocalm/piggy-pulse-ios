# Overlay Form Sheet Design

**Date:** 2026-03-08
**Feature:** Create/Edit Overlay — 4-step wizard sheet

## Overview

A multi-step sheet for creating and editing overlays. Handles both create (no pre-fill) and edit (pre-filled, warning banner) modes via a single `OverlayFormSheet` view.

## Files

**New:**
- `Features/Overlays/Views/OverlayFormSheet.swift` — 4-step wizard (create + edit)
- `Features/Overlays/Views/EmojiPickerGrid.swift` — reusable inline emoji grid (~48 emojis, 8 columns)

**Modified:**
- `Features/Overlays/Views/OverlaysView.swift` — FAB button + sheet presentation
- `Core/Models/Overlays.swift` — request/response model types

## Architecture

**Mode detection:** `OverlayFormSheet(overlay: OverlayItem?)`. `nil` = create, non-nil = edit.

**Step state:** `@State var currentStep: Int` (0–3). Transitions via `withAnimation(.easeInOut(duration: 0.25))` sliding left on Next, right on Back.

**All form state** lives in one view. Options (accounts, categories, vendors) fetched on appear via existing API endpoints.

## Step Indicator

Horizontal row of 4 labeled dots at the top of content (not toolbar). Labels: "Basics", "Inclusion", "Caps", "Review". Active = filled primary, completed = filled secondary, future = empty ring.

## Step 1 — Basic Information

- Name `TextField`, placeholder "e.g. Italy Trip", required (non-empty)
- Emoji: inline `LazyVGrid` 8 columns, ~48 curated emojis. Tap to select/deselect. Selected = primary color ring. Optional.
- Start date: `DatePicker` compact, default = today
- End date: `DatePicker` compact, default = today + 5 days, min = start + 1 day
- Disclaimer: "Overlays are temporary and always require both start and end dates." `.ppCaption` / `.ppTextSecondary`

**Next enabled when:** name is non-empty.

## Step 2 — Inclusion Rules

Three tappable cards (radio-style):
- **Manual** — "You decide what to include manually." + `(Recommended)` badge. Default.
- **Rules-based** — "Include transactions automatically from category, vendor, or account rules."
- **Include everything** — "Include every transaction inside the date range."

If **Rules-based**: expands multi-select pickers below:
- Accounts (from `accountOptions`)
- Categories (from `categoryOptions`)
- Vendors (from `vendorsForPeriod`)

Each picker shows selected count badge. At least one item across any picker required to advance.

**Next enabled when:** any mode + if rules-based: ≥1 rule item selected.

## Step 3 — Caps

**Toggle: Enable total amount cap**
→ Currency amount field (decimal, prefixed with `appState.currencyCode` symbol)

**Toggle: Enable per-category caps**
→ Multi-select category list; each selected category gets an inline amount field

Both optional. **Next always enabled.**

## Step 4 — Review

Read-only summary:
- Name + emoji
- Date range ("Mar 8 – Mar 13, 2026 · 5 days")
- Inclusion mode + rule summary if rules-based ("2 accounts, 1 category")
- Caps summary ("No cap" or amounts; per-category caps by name + amount)

**Edit mode warning** (top of review, `.ppAmber` + warning icon):
"Changing date range or inclusion mode updates which transactions may belong to this overlay."

**Confirm button:** Full-width primary, "Create Overlay" / "Save Changes". Loading state = `ProgressView`. Error shown inline above button.

## Navigation & Cancel

- Toolbar X (cancellationAction): dismisses immediately, no confirmation
- Step 1 bottom: "Next →" right-aligned primary
- Steps 2–3 bottom: "← Back" secondary + "Next →" primary
- Step 4 bottom: "← Back" secondary + confirm button primary

## FAB Button (OverlaysView)

Matches existing `addTransactionFAB` pattern:

```swift
Image(systemName: "plus")
    .font(.system(size: 22, weight: .semibold))
    .foregroundStyle(Color.ppPrimary)
    .frame(width: 56, height: 56)
    .glassEffect(.regular, in: Circle())
```

`.overlay(alignment: .bottomTrailing)` on the list, same padding as existing FAB.
