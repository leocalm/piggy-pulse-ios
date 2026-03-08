# Category Targets — Design Document

**Date:** 2026-03-09
**Feature:** Category target management in BudgetPlanView

## Overview

Add the ability for users to set budget targets per category and mark categories as excluded from tracking, directly within the iOS app's "Category targets" screen.

## API

All operations use the `/category-targets/` endpoints:

| Action | Endpoint |
|--------|----------|
| Load targets | `GET /category-targets/?period_id=<id>` |
| Set/update target | `POST /category-targets/` (batch upsert: `{period_id, targets: [{category_id, target_value}]}`) |
| Exclude category | `POST /category-targets/{id}/exclude` |
| Re-include category | `POST /category-targets/{id}/include` |

**Response schema (`CategoryTargetItem`):**
```
id: UUID
category_id: UUID
category_name: String
target_value: Int32  (cents)
excluded: Bool
```

Since `CategoryTargetItem` lacks icon/color, the categories list (`GET /categories/?period_id=<id>`) is also fetched in parallel to enrich the display.

## Data Model

New model `CategoryTarget` (replaces use of `BudgetCategoryItem` in this view):
```swift
struct CategoryTarget: Codable, Identifiable {
    let id: UUID
    let categoryId: UUID
    let categoryName: String
    let targetValue: Int32
    let excluded: Bool
}
```

Category detail (icon/color) merged from `CategoryListItem` by `categoryId`.

## View States

Each category row has one of three states:

1. **Has target** (`excluded == false`, `targetValue > 0`) — card with icon, name, target amount
2. **Excluded** (`excluded == true`) — greyed-out card with "Excluded" badge, strikethrough on name
3. **No target** (`excluded == false`, `targetValue == 0`) — muted card with "No target" label and a `+` add button

## Edit Sheet

Tapping any row opens a bottom sheet (`EditCategoryTargetSheet`) with:
- Category icon + name header
- Currency amount input field (pre-filled if target exists)
- "Exclude this category" toggle
- "Save" button — calls batch upsert or exclude/include as appropriate
- "Remove target" button (only shown if a target exists) — sets target_value to 0

## Swipe Actions

- Row with target: swipe left → "Exclude" action
- Excluded row: swipe left → "Include" action

## ViewModel Changes

`BudgetViewModel` is updated to:
- Replace `categories: [BudgetCategoryItem]` with `targets: [CategoryTarget]`
- Add `allCategories: [CategoryListItem]` for icon/color enrichment
- Fetch both in parallel alongside `monthlyBurnIn`
- Add `setTarget(categoryId:value:periodId:)` async method
- Add `excludeTarget(id:)` async method
- Add `includeTarget(id:)` async method

## New Files

- `Core/Models/CategoryTarget.swift` — new model
- `Features/Budget/Views/EditCategoryTargetSheet.swift` — edit bottom sheet

## Modified Files

- `Core/Network/APIEndpoints.swift` — add `/category-targets/` endpoints
- `Core/Models/Category.swift` — ensure `CategoryListItem` is accessible
- `Features/Budget/ViewModels/BudgetViewModel.swift` — replace data fetching and add mutation methods
- `Features/Budget/Views/BudgetPlanView.swift` — update list rendering and add swipe actions
