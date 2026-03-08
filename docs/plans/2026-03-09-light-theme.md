# Light Theme Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a light color palette and wire the user's saved theme preference (system/light/dark) to dynamically change the app's color scheme.

**Architecture:** `Theme.swift` colors become `@Environment(\.colorScheme)`-aware computed properties. `AppState` gains a `@Published var appColorScheme: ColorScheme?` backed by `UserDefaults`. `PiggyPulseApp` passes it to `.preferredColorScheme()`. `SettingsView` updates `AppState` immediately after saving.

**Tech Stack:** SwiftUI, `@Environment(\.colorScheme)`, `UserDefaults`, existing `AppState` / `SettingsView`.

---

### Task 1: Make Theme colors ColorScheme-aware

**Files:**
- Modify: `Design/Theme.swift`

**Step 1: Replace static color properties with ColorScheme-aware computed properties**

Replace the entire `// MARK: - Colors` extension with:

```swift
// MARK: - Colors

extension Color {
    // Brand (unchanged — work on both backgrounds)
    static let ppPrimary = Color(red: 0.00, green: 0.48, blue: 1.00)      // #007AFF
    static let ppCyan = Color(red: 0.00, green: 0.83, blue: 1.00)         // #00d4ff
    static let ppAmber = Color(red: 1.00, green: 0.66, blue: 0.25)        // #ffa940
    static let ppTeal = Color(red: 0.00, green: 0.71, blue: 0.78)         // #00b4c8
    static let ppDestructive = Color(red: 0.97, green: 0.32, blue: 0.29)  // #f85149

    // Adaptive backgrounds
    static func ppBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.04, green: 0.05, blue: 0.07)   // #0a0e14
            : Color(red: 0.95, green: 0.96, blue: 0.97)   // #F2F4F7
    }
    static func ppSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.06, green: 0.07, blue: 0.10)   // #0f1319
            : Color.white
    }
    static func ppCard(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.08, green: 0.11, blue: 0.15)   // #151b26
            : Color.white
    }
    static func ppTextPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : Color.black
    }
    static func ppTextSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.51, green: 0.55, blue: 0.62)   // #828c9e
            : Color(red: 0.35, green: 0.38, blue: 0.45)   // #5a6272
    }
    static func ppTextTertiary(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.35, green: 0.38, blue: 0.45)   // #5a6272
            : Color(red: 0.51, green: 0.55, blue: 0.62)   // #828c9e
    }
    static func ppBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.08)
    }
    static func ppBorderHover(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.15)
    }
}
```

**Step 2: Build and note all compiler errors**

In Xcode or via `xcodebuild build`, note every file that now has errors due to the changed API. These are the call sites to fix in Tasks 3+.

Expected: Many errors like `cannot convert value of type '(ColorScheme) -> Color' to expected argument type 'Color'`.

**Step 3: Commit the Theme change**

```bash
git add Design/Theme.swift
git commit -m "feat(theme): adaptive color palette for light/dark modes"
```

---

### Task 2: Add appColorScheme to AppState

**Files:**
- Modify: `App/AppState.swift`

**Step 1: Add the published property and persistence key**

After `@Published var currencyCode: String = "EUR"`, add:

```swift
@Published var appColorScheme: ColorScheme? = nil
```

**Step 2: Add a helper to load theme from UserDefaults**

Add this method to `AppState`:

```swift
func loadTheme() {
    let stored = UserDefaults.standard.string(forKey: "appTheme") ?? "system"
    appColorScheme = colorScheme(from: stored)
}

func applyTheme(_ value: String) {
    UserDefaults.standard.set(value, forKey: "appTheme")
    appColorScheme = colorScheme(from: value)
}

private func colorScheme(from value: String) -> ColorScheme? {
    switch value {
    case "light": return .light
    case "dark":  return .dark
    default:      return nil   // "system" / "auto"
    }
}
```

**Step 3: Call loadTheme() on launch**

In `checkAuth()`, after `isLoading = false` at the end, add:

```swift
loadTheme()
```

Also add `loadTheme()` as the very first line of `init()` so the theme is set instantly before auth check completes.

**Step 4: Commit**

```bash
git add App/AppState.swift
git commit -m "feat(theme): add appColorScheme to AppState with UserDefaults persistence"
```

---

### Task 3: Wire preferredColorScheme in PiggyPulseApp

**Files:**
- Modify: `App/PiggyPulseApp.swift`

**Step 1: Replace the hardcoded dark scheme**

Change line 11 from:
```swift
.preferredColorScheme(.dark)
```
to:
```swift
.preferredColorScheme(appState.appColorScheme)
```

**Step 2: Build and verify no errors in this file**

Run a build. This file should compile cleanly.

**Step 3: Commit**

```bash
git add App/PiggyPulseApp.swift
git commit -m "feat(theme): apply dynamic color scheme from AppState"
```

---

### Task 4: Update SettingsView to apply theme immediately

**Files:**
- Modify: `Features/Settings/Views/SettingsView.swift`

**Step 1: Call applyTheme after successful save**

In `savePreferences()`, after `preferencesDirty = false` (line 276), add:

```swift
appState.applyTheme(themeValue)
```

That's all — the existing `selectedTheme` / API save logic is already correct.

**Step 2: Commit**

```bash
git add Features/Settings/Views/SettingsView.swift
git commit -m "feat(theme): apply theme preference immediately on save"
```

---

### Task 5: Fix all Color call sites

**Context:** After Task 1, `Color.ppBackground`, `Color.ppCard`, etc. are now functions taking a `ColorScheme`. Every SwiftUI view that uses these must inject `@Environment(\.colorScheme) var colorScheme` and call `Color.ppBackground(colorScheme)`.

**Files:** All `.swift` files in `Features/`, `App/`, `Design/` that use the old static properties.

**Step 1: Find all affected files**

```bash
grep -rl "\.ppBackground\|\.ppSurface\|\.ppCard\|\.ppTextPrimary\|\.ppTextSecondary\|\.ppTextTertiary\|\.ppBorder\b\|\.ppBorderHover" --include="*.swift" .
```

**Step 2: For each file, add the environment variable at the top of the view struct**

Add after the existing `@EnvironmentObject` or `@State` declarations:

```swift
@Environment(\.colorScheme) private var colorScheme
```

**Step 3: Update each usage**

Replace every occurrence in the file:
- `.ppBackground` → `.ppBackground(colorScheme)`
- `.ppSurface` → `.ppSurface(colorScheme)`
- `.ppCard` → `.ppCard(colorScheme)`
- `.ppTextPrimary` → `.ppTextPrimary(colorScheme)`
- `.ppTextSecondary` → `.ppTextSecondary(colorScheme)`
- `.ppTextTertiary` → `.ppTextTertiary(colorScheme)`
- `.ppBorder` → `.ppBorder(colorScheme)`  _(careful: only where it's the Color token, not a property name)_
- `.ppBorderHover` → `.ppBorderHover(colorScheme)`

**Step 4: Build after each file to catch errors early**

```bash
xcodebuild build -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|warning:" | head -40
```

**Step 5: Commit when all files compile**

```bash
git add -A
git commit -m "feat(theme): update all color call sites to pass colorScheme"
```

---

### Task 6: Manual smoke test

**Step 1: Run app in simulator**

Launch in iPhone 16 simulator. Default should be "System" (inherits simulator's appearance).

**Step 2: Test theme switching**

1. Go to Settings → Preferences → Theme
2. Select "Light" → tap Save Preferences
3. Verify app immediately switches to light backgrounds, dark text
4. Select "Dark" → Save → verify dark mode returns
5. Select "System" → Save → verify it follows simulator setting

**Step 3: Test persistence**

1. Set theme to "Light" and save
2. Force-quit the app
3. Relaunch — should open in light mode without flicker

**Step 4: Commit nothing** (smoke test only)

---

### Task 7: PR

```bash
git push origin feat/light-theme
gh pr create --draft \
  --title "feat(theme): light theme + user preference" \
  --body "$(cat <<'EOF'
## Summary
- Adds adaptive light/dark color palette to the design system
- Wires the existing theme preference (system/light/dark) from Settings to actually change the app color scheme
- Theme applies immediately on save and persists across launches via UserDefaults

## Test plan
- [ ] Theme picker in Settings switches appearance immediately
- [ ] Preference persists after force-quit
- [ ] System mode follows device appearance setting
- [ ] All screens render correctly in light mode (no invisible text or clipped elements)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
