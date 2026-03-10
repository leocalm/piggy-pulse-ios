# Face ID / Touch ID Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add optional, opt-in biometric lock (Face ID / Touch ID) that triggers on app foreground after a 10-second grace period.

**Architecture:** `BiometricHelper` wraps `LAContext`. `AppState` owns lock state and grace period logic. `RootView` overlays `BiometricLockView` when locked. `PiggyPulseApp` observes `scenePhase` to trigger locking. Settings toggle lives in the Security card.

**Tech Stack:** SwiftUI, LocalAuthentication framework, UserDefaults (preference persistence), XCTest

**Spec:** `docs/superpowers/specs/2026-03-10-face-id-touch-id-design.md`

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `Core/Biometrics/BiometricHelper.swift` | LAContext wrapper — authenticate, detect biometry type; `BiometricPreferences` struct |
| Create | `Features/Auth/Views/BiometricLockView.swift` | Full-screen lock overlay UI |
| Modify | `App/AppState.swift` | Add `biometricEnabled`, `isBiometricLocked`, `biometricAuthFailed`, `lastBackgroundedAt`, `lockIfNeeded()`, `unlockWithBiometrics()` |
| Modify | `App/PiggyPulseApp.swift` | Add `scenePhase` observation |
| Modify | `App/Features/Navigation/RootView.swift` | ZStack overlay with `BiometricLockView` |
| Modify | `Features/Settings/Views/SettingsView.swift` | Biometric toggle in Security card |
| Modify | `PiggyPulse/Info.plist` | Add `NSFaceIDUsageDescription` |
| Create | `PiggyPulseTests/BiometricPreferenceTests.swift` | Tests for preference persistence and `lockIfNeeded()` grace period |

---

## Chunk 1: BiometricHelper + Tests

### Task 1: BiometricHelper — write failing tests

**Files:**
- Create: `PiggyPulseTests/BiometricPreferenceTests.swift`

- [ ] **Step 1: Write failing tests for `BiometricPreferences`**

Create `PiggyPulseTests/BiometricPreferenceTests.swift`:

```swift
// PiggyPulseTests/BiometricPreferenceTests.swift
import XCTest
@testable import PiggyPulse

final class BiometricPreferenceTests: XCTestCase {
    var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test-biometric")!
        defaults.removePersistentDomain(forName: "test-biometric")
    }

    func testDefaultIsDisabled() {
        let prefs = BiometricPreferences(defaults: defaults)
        XCTAssertFalse(prefs.isEnabled)
    }

    func testPersistsEnabled() {
        var prefs = BiometricPreferences(defaults: defaults)
        prefs.isEnabled = true
        let prefs2 = BiometricPreferences(defaults: defaults)
        XCTAssertTrue(prefs2.isEnabled)
    }

    func testPersistsDisabled() {
        var prefs = BiometricPreferences(defaults: defaults)
        prefs.isEnabled = true
        prefs.isEnabled = false
        let prefs2 = BiometricPreferences(defaults: defaults)
        XCTAssertFalse(prefs2.isEnabled)
    }
}
```

- [ ] **Step 2: Run tests — expect failure (BiometricPreferences not defined)**

```bash
xcodebuild test -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PiggyPulseTests/BiometricPreferenceTests 2>&1 | grep -E "error:|FAILED|PASSED|Test Suite"
```

Expected: compile error — `BiometricPreferences` not found.

---

### Task 2: Implement `BiometricPreferences` + `BiometricHelper`

**Files:**
- Create: `Core/Biometrics/BiometricHelper.swift`

Note: `LAContext` cannot be easily mocked without dependency injection. `BiometricHelper.authenticate()` is tested manually (see Manual Testing Checklist). The unit tests cover the pure-logic layer (`BiometricPreferences`, grace period).

- [ ] **Step 1: Create the `Core/Biometrics/` directory**

```bash
mkdir -p /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios/Core/Biometrics
```

- [ ] **Step 2: Create `Core/Biometrics/BiometricHelper.swift`**

```swift
// Core/Biometrics/BiometricHelper.swift
import LocalAuthentication

/// Persists the user's biometric lock preference.
struct BiometricPreferences {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isEnabled: Bool {
        get { defaults.object(forKey: "biometricEnabled") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "biometricEnabled") }
    }
}

/// Thin wrapper around LAContext for biometric authentication.
enum BiometricHelper {
    enum BiometricError: Error {
        case notAvailable
        case authFailed
    }

    /// Returns the available biometry type on this device.
    static func availableBiometryType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .none
        }
        return context.biometryType
    }

    /// Authenticates using biometrics with passcode fallback.
    /// Throws `BiometricError.notAvailable` or `BiometricError.authFailed`.
    static func authenticate(reason: String = "Unlock PiggyPulse") async throws {
        let context = LAContext()
        var canEvalError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &canEvalError) else {
            throw BiometricError.notAvailable
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if !success { throw BiometricError.authFailed }
        } catch let error as BiometricError {
            throw error
        } catch {
            throw BiometricError.authFailed
        }
    }
}
```

- [ ] **Step 3: Run tests — expect pass**

```bash
xcodebuild test -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PiggyPulseTests/BiometricPreferenceTests 2>&1 | grep -E "error:|FAILED|PASSED|Test Suite"
```

Expected: 3 tests pass.

- [ ] **Step 4: Add new files to the Xcode target**

Open `piggy-pulse-ios.xcodeproj` in Xcode. For each new file created on disk (`Core/Biometrics/BiometricHelper.swift`), drag it into the Xcode project navigator under the correct group and ensure "Target Membership: PiggyPulse" is checked in the File Inspector. Do the same for `PiggyPulseTests/BiometricPreferenceTests.swift` with target "PiggyPulseTests". Without this, the files compile to disk but are invisible to the build system.

- [ ] **Step 5: Commit**

```bash
git add Core/Biometrics/BiometricHelper.swift PiggyPulseTests/BiometricPreferenceTests.swift piggy-pulse-ios.xcodeproj/project.pbxproj
git commit -m "feat(biometrics): BiometricHelper and BiometricPreferences with tests"
```

---

## Chunk 2: AppState lock logic + Tests

### Task 3: Write failing tests for AppState lock logic

**Files:**
- Modify: `PiggyPulseTests/BiometricPreferenceTests.swift` (append new test class)

- [ ] **Step 1: Add `LockGracePeriodTests` to the test file**

Append to `PiggyPulseTests/BiometricPreferenceTests.swift`:

```swift
final class LockGracePeriodTests: XCTestCase {

    func testNoLockWhenBiometricDisabled() {
        let shouldLock = AppState.shouldLock(
            biometricEnabled: false,
            lastBackgroundedAt: Date(timeIntervalSinceNow: -20),
            gracePeriod: 10
        )
        XCTAssertFalse(shouldLock)
    }

    func testNoLockWithinGracePeriod() {
        let shouldLock = AppState.shouldLock(
            biometricEnabled: true,
            lastBackgroundedAt: Date(timeIntervalSinceNow: -5),
            gracePeriod: 10
        )
        XCTAssertFalse(shouldLock)
    }

    func testLocksAfterGracePeriod() {
        let shouldLock = AppState.shouldLock(
            biometricEnabled: true,
            lastBackgroundedAt: Date(timeIntervalSinceNow: -11),
            gracePeriod: 10
        )
        XCTAssertTrue(shouldLock)
    }

    func testNoLockIfNeverBackgrounded() {
        let shouldLock = AppState.shouldLock(
            biometricEnabled: true,
            lastBackgroundedAt: nil,
            gracePeriod: 10
        )
        XCTAssertFalse(shouldLock)
    }
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
xcodebuild test -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PiggyPulseTests/BiometricPreferenceTests 2>&1 | grep -E "error:|FAILED|PASSED|Test Suite"
```

Expected: compile error — `AppState.shouldLock` not found.

---

### Task 4: Add lock logic to AppState

**Files:**
- Modify: `App/AppState.swift`

- [ ] **Step 1: Add biometric properties to `AppState`**

In `App/AppState.swift`, add after the `@Published var appColorScheme: ColorScheme? = nil` line:

```swift
    @Published var isBiometricLocked = false
    @Published var biometricAuthFailed = false
    var lastBackgroundedAt: Date?

    var biometricEnabled: Bool {
        get { BiometricPreferences().isEnabled }
        set {
            var prefs = BiometricPreferences()
            prefs.isEnabled = newValue
        }
    }
```

- [ ] **Step 2: Add `shouldLock`, `lockIfNeeded`, and `unlockWithBiometrics` to `AppState`**

Add these methods before `init()` in `App/AppState.swift`:

```swift
    /// Pure logic: determines whether the app should lock.
    /// Static for unit-testability without an AppState instance.
    static func shouldLock(
        biometricEnabled: Bool,
        lastBackgroundedAt: Date?,
        gracePeriod: TimeInterval = 10
    ) -> Bool {
        guard biometricEnabled, let backgroundedAt = lastBackgroundedAt else { return false }
        return Date().timeIntervalSince(backgroundedAt) > gracePeriod
    }

    /// Called when the app comes to foreground. Locks if grace period elapsed.
    func lockIfNeeded() {
        guard !isBiometricLocked else { return }
        if Self.shouldLock(biometricEnabled: biometricEnabled, lastBackgroundedAt: lastBackgroundedAt) {
            isBiometricLocked = true
        }
    }

    /// Attempts biometric authentication. Sets `isBiometricLocked = false` on success,
    /// sets `biometricAuthFailed = true` on failure so the UI can show "Try Again".
    func unlockWithBiometrics() async {
        biometricAuthFailed = false
        do {
            try await BiometricHelper.authenticate()
            isBiometricLocked = false
        } catch {
            biometricAuthFailed = true
        }
    }
```

- [ ] **Step 3: Run tests — expect pass**

```bash
xcodebuild test -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PiggyPulseTests/BiometricPreferenceTests 2>&1 | grep -E "error:|FAILED|PASSED|Test Suite"
```

Expected: all 7 tests pass.

- [ ] **Step 4: Commit**

```bash
git add App/AppState.swift PiggyPulseTests/BiometricPreferenceTests.swift
git commit -m "feat(biometrics): add lock logic to AppState with grace period"
```

---

## Chunk 3: UI — LockView + RootView + App scenePhase

### Task 5: `BiometricLockView`

**Files:**
- Create: `Features/Auth/Views/BiometricLockView.swift`

- [ ] **Step 1: Create `Features/Auth/Views/BiometricLockView.swift`**

```swift
// Features/Auth/Views/BiometricLockView.swift
import SwiftUI
import LocalAuthentication

struct BiometricLockView: View {
    @EnvironmentObject var appState: AppState

    private var biometryType: LABiometryType {
        BiometricHelper.availableBiometryType()
    }

    private var iconName: String {
        switch biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }

    private var unlockLabel: String {
        switch biometryType {
        case .faceID: return "Unlock with Face ID"
        case .touchID: return "Unlock with Touch ID"
        default: return "Unlock"
        }
    }

    var body: some View {
        ZStack {
            Color.ppBackground.ignoresSafeArea()

            VStack(spacing: PPSpacing.xl) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.ppPrimary)

                Text("PiggyPulse")
                    .font(.ppLargeTitle)
                    .foregroundColor(.ppTextPrimary)

                Spacer().frame(height: PPSpacing.xxxl)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task { await appState.unlockWithBiometrics() }
                } label: {
                    Label(unlockLabel, systemImage: iconName)
                        .font(.ppHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.lg)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.ppPrimary)

                if appState.biometricAuthFailed {
                    Text("Authentication failed. Try again.")
                        .font(.ppCaption)
                        .foregroundColor(.ppAmber)
                        .transition(.opacity)
                }
            }
            .padding(PPSpacing.xxxl)
        }
        .task { await appState.unlockWithBiometrics() }
        .animation(.easeInOut(duration: 0.2), value: appState.biometricAuthFailed)
    }
}
```

- [ ] **Step 2: Add `BiometricLockView.swift` to the Xcode target**

Open Xcode, drag `Features/Auth/Views/BiometricLockView.swift` into the project navigator under `Features/Auth/Views/`, and confirm target membership: PiggyPulse.

- [ ] **Step 3: Build to verify no compile errors**

```bash
xcodebuild build -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

---

### Task 6: Wire `RootView`, `PiggyPulseApp`, and `Info.plist`

**Files:**
- Modify: `App/Features/Navigation/RootView.swift`
- Modify: `App/PiggyPulseApp.swift`
- Modify: `PiggyPulse/Info.plist` (or project's Info.plist location)

- [ ] **Step 1: Update `RootView` to overlay `BiometricLockView`**

Replace the entire `body` in `App/Features/Navigation/RootView.swift`:

```swift
    var body: some View {
        ZStack {
            Group {
                if appState.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.ppBackground)
                } else if appState.isAuthenticated {
                    if appState.currentUser?.onboardingStatus == "completed" {
                        MainTabView()
                    } else {
                        OnboardingView(apiClient: appState.apiClient)
                    }
                } else {
                    NavigationStack {
                        LoginView()
                    }
                }
            }

            if appState.isBiometricLocked {
                BiometricLockView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.isBiometricLocked)
    }
```

- [ ] **Step 2: Add `scenePhase` observation to `PiggyPulseApp`**

In `App/PiggyPulseApp.swift`, add `@Environment(\.scenePhase) private var scenePhase` as a new property (the `@StateObject var appState` line already exists — do not duplicate it):

```swift
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase   // ADD THIS LINE
```

Then update `body` to add `.onChange(of: scenePhase)` on `RootView()` inside the `WindowGroup` (not on the `WindowGroup` scene itself — scene-level modifiers don't support `.onChange`):

```swift
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.appColorScheme)
                .task {
                    await appState.checkAuth()
                    scheduleNextBackgroundRefresh()
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .background:
                        appState.lastBackgroundedAt = Date()
                    case .active:
                        appState.lockIfNeeded()
                    default:
                        break
                    }
                }
        }
    }
```

- [ ] **Step 3: Add `NSFaceIDUsageDescription` to Info.plist**

Find the project's `Info.plist` (check Xcode project navigator or run `find . -name "Info.plist" -not -path "*/Pods/*"`). Add the key:

```xml
<key>NSFaceIDUsageDescription</key>
<string>PiggyPulse uses Face ID to keep your financial data secure.</string>
```

If the project uses the Xcode 13+ `Info.plist`-less approach, add it via the target's Build Settings → Info → Custom iOS Target Properties instead.

- [ ] **Step 4: Build to verify no compile errors**

```bash
xcodebuild build -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add Features/Auth/Views/BiometricLockView.swift App/Features/Navigation/RootView.swift App/PiggyPulseApp.swift piggy-pulse-ios/Info.plist
git commit -m "feat(biometrics): add BiometricLockView, wire scene phase locking, add NSFaceIDUsageDescription"
```

---

## Chunk 4: Settings toggle

### Task 7: Add biometric toggle to SettingsView Security card

**Files:**
- Modify: `Features/Settings/Views/SettingsView.swift`

- [ ] **Step 1: Add state variables to `SettingsView`**

In `Features/Settings/Views/SettingsView.swift`, add to the `@State` block at the top:

```swift
    @State private var biometricEnabled = false
    @State private var biometricAvailable = false
    @State private var biometricUnavailableReason = ""
    @State private var biometricLabel = "Biometrics"
```

- [ ] **Step 2: Load biometric state inside `load()`**

Inside the `load()` function, inside the `do` block, after the notification preferences lines (i.e., after `notificationOverlayLifecycle = prefs.overlayLifecycle`) and before the `catch`, add:

```swift
            let biometryType = BiometricHelper.availableBiometryType()
            switch biometryType {
            case .faceID:
                biometricLabel = "Face ID"
                biometricAvailable = true
                biometricUnavailableReason = ""
            case .touchID:
                biometricLabel = "Touch ID"
                biometricAvailable = true
                biometricUnavailableReason = ""
            default:
                biometricLabel = "Biometrics"
                biometricAvailable = false
                biometricUnavailableReason = "Biometric authentication is not available on this device"
            }
            biometricEnabled = appState.biometricEnabled
```

- [ ] **Step 3: Replace `securityCard` with updated version**

Replace the entire `securityCard` computed property in `Features/Settings/Views/SettingsView.swift`:

```swift
    private var securityCard: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("SECURITY")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showChangePassword = true
            } label: {
                HStack {
                    Label("Change Password", systemImage: "key")
                        .font(.ppBody)
                        .foregroundColor(.ppTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.ppTextTertiary)
                }
            }

            Divider().background(Color.ppBorder)

            VStack(alignment: .leading, spacing: PPSpacing.xs) {
                Toggle(isOn: $biometricEnabled) {
                    Text(biometricLabel)
                        .font(.ppBody)
                        .foregroundColor(biometricAvailable ? .ppTextPrimary : .ppTextTertiary)
                }
                .tint(.ppPrimary)
                .disabled(!biometricAvailable)
                .onChange(of: biometricEnabled) { _, enabled in
                    handleBiometricToggle(enabled)
                }

                if !biometricAvailable {
                    Text(biometricUnavailableReason)
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }
```

- [ ] **Step 4: Add `handleBiometricToggle` helper**

Add to `SettingsView`, alongside `handleNotificationMasterToggle`:

```swift
    private func handleBiometricToggle(_ enabled: Bool) {
        if enabled {
            // Require a successful auth before persisting — confirms enrollment
            Task {
                do {
                    try await BiometricHelper.authenticate(reason: "Confirm to enable biometric unlock")
                    appState.biometricEnabled = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } catch {
                    // Revert toggle if auth failed or was cancelled
                    biometricEnabled = false
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        } else {
            appState.biometricEnabled = false
            appState.isBiometricLocked = false
        }
    }
```

- [ ] **Step 5: Build and run all tests**

```bash
xcodebuild build -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD"
xcodebuild test -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|FAILED|PASSED|Test Suite"
```

Expected: `BUILD SUCCEEDED`, all tests pass.

- [ ] **Step 6: Commit**

```bash
git add Features/Settings/Views/SettingsView.swift
git commit -m "feat(biometrics): add Face ID / Touch ID toggle to Settings security card"
```

---

## Manual Testing Checklist

- [ ] Fresh install → biometric toggle is OFF in Settings
- [ ] Enable toggle → biometric prompt appears immediately; success enables it; cancel/fail reverts to OFF
- [ ] Background app for >10s → foreground → lock screen appears
- [ ] Background app for <10s → foreground → no lock screen
- [ ] On lock screen: tap "Unlock with Face ID/Touch ID" → success → app unlocks
- [ ] On lock screen: fail auth → "Authentication failed. Try again." message appears
- [ ] Logout → re-login → if biometric was enabled, foreground after 10s shows lock screen
- [ ] Device with no biometrics enrolled → toggle is disabled with subtitle
- [ ] Face ID unavailable (simulator) → toggle shows "Biometrics" label, disabled

---

## Notes

- `LAContext.evaluatePolicy(.deviceOwnerAuthentication, ...)` allows passcode fallback automatically.
- `isBiometricLocked` is only set when `biometricEnabled` is true, so unauthenticated users never see the lock screen.
- The background task handler in `PiggyPulseApp` creates a fresh `AppState` — `lockIfNeeded()` is never called in that path, so background notification refreshes are unaffected.
- `NSFaceIDUsageDescription` is required for App Store submission and runtime on real devices; missing it causes a crash when Face ID is invoked.
