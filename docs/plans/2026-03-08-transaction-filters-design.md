# Transaction Filters Design

Date: 2026-03-08

## Summary

Add server-side filtering to the Transactions list by account, category, and vendor. Filters are applied as repeated query params to the existing `/transactions` API endpoint, which already supports `account_id[]`, `category_id[]`, and `vendor_id[]`.

## Architecture

### ViewModel (`TransactionsViewModel`)

- Add `selectedAccountIds: Set<UUID>`, `selectedCategoryIds: Set<UUID>`, `selectedVendorIds: Set<UUID>`
- Add `filterOptions: FilterOptions?` struct holding `[AccountOption]`, `[CategoryOption]`, `[VendorOption]`
- Add `isLoadingFilterOptions: Bool`
- Add `loadFilterOptions()` — fetches from `/accounts/options`, `/categories/options`, `/vendors` concurrently; called lazily on filter sheet open
- `load()` passes filter ID arrays to the repository
- Computed `activeFilterCount: Int` — sum of selected IDs across all three sets

### Repository (`TransactionRepository`)

- `fetchTransactions` gains optional `accountIds: [UUID]`, `categoryIds: [UUID]`, `vendorIds: [UUID]` parameters
- Each ID appended as a repeated query item: `account_id=<uuid>`, `category_id=<uuid>`, `vendor_id=<uuid>`

### New View (`TransactionFilterSheet`)

- Presented as a sheet from `TransactionsView`
- Receives bindings to the three `Set<UUID>` filter states and the loaded `filterOptions`
- Sections: Accounts, Categories, Vendors — each a scrollable multi-select list with checkmarks
- Toolbar: "Clear All" button (resets all sets) + "Apply" button (dismisses and triggers reload)
- Shows a `ProgressView` while options are loading

### `TransactionsView` changes

- Add filter toolbar button (`.filter` system image) with badge showing `activeFilterCount` when > 0
- Add `@State var showFilterSheet = false`
- On sheet dismiss with changes: call `viewModel.applyFilters(periodId:)`

## Data Flow

1. User taps filter icon → `showFilterSheet = true`
2. Sheet appears → `viewModel.loadFilterOptions()` called if not already loaded
3. User selects items → local `Set<UUID>` bindings update
4. "Apply" → sheet dismisses → `TransactionsView` calls `viewModel.applyFilters(periodId:)` which resets cursor and calls `load()`
5. "Clear All" → resets all three sets (Apply still required to reload)

## Filter Options Source

Fetched from existing options endpoints:
- Accounts: `GET /accounts/options`
- Categories: `GET /categories/options`
- Vendors: `GET /vendors` (full list, reuse `VendorOption`)

## Non-Goals

- Date range filtering (backend supports it but out of scope)
- Single-select mode
- Persisting filter state across app launches
