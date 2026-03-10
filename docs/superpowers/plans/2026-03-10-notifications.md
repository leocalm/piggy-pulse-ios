# Notifications Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add calm, local push notifications to PiggyPulse iOS for period lifecycle and overlay lifecycle events, with per-type toggles in Settings.

**Architecture:** A `NotificationScheduler` actor owns all scheduling logic. `NotificationPreferences` wraps `UserDefaults`. Scheduling runs on app foreground and via a registered `BGAppRefreshTask`. Settings UI adds a NOTIFICATIONS card to `SettingsView`.

**Tech Stack:** Swift, UserNotifications framework, BackgroundTasks framework, XCTest

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `Core/Notifications/NotificationPreferences.swift` | Create | UserDefaults-backed preferences (master + 3 toggles) |
| `Core/Notifications/NotificationScheduler.swift` | Create | Actor: clear, fetch, schedule all notification types |
| `Core/Repositories/OverlayRepository.swift` | Create | Fetch overlays from API (mirrors PeriodRepository pattern) |
| `App/AppState.swift` | Modify | Add `NotificationScheduler` instance; call on auth check |
| `App/PiggyPulseApp.swift` | Modify | Register BGTask identifier; submit background task after foreground schedule |
| `Features/Settings/Views/SettingsView.swift` | Modify | Add NOTIFICATIONS card with master toggle + 3 sub-toggles |
| `PiggyPulse-Info.plist` | Modify | Add `BGTaskSchedulerPermittedIdentifiers` |
| `PiggyPulseTests/NotificationPreferencesTests.swift` | Create | Unit tests for preferences read/write |
| `PiggyPulseTests/NotificationSchedulerTests.swift` | Create | Unit tests for scheduling logic (mock notification center) |

---

## Chunk 1: NotificationPreferences + OverlayRepository

### Task 1: NotificationPreferences

**Files:**
- Create: `Core/Notifications/NotificationPreferences.swift`
- Create: `PiggyPulseTests/NotificationPreferencesTests.swift`

- [ ] **Step 1: Create the test file**

```swift
// PiggyPulseTests/NotificationPreferencesTests.swift
import XCTest
@testable import PiggyPulse

final class NotificationPreferencesTests: XCTestCase {
    var defaults: UserDefaults!
    var prefs: NotificationPreferences!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test-notifications")!
        defaults.removePersistentDomain(forName: "test-notifications")
        prefs = NotificationPreferences(defaults: defaults)
    }

    func testDefaultsAreAllEnabled() {
        XCTAssertTrue(prefs.isEnabled)
        XCTAssertTrue(prefs.periodStarting)
        XCTAssertTrue(prefs.periodSummary)
        XCTAssertTrue(prefs.overlayLifecycle)
    }

    func testToggleMaster() {
        prefs.isEnabled = false
        let prefs2 = NotificationPreferences(defaults: defaults)
        XCTAssertFalse(prefs2.isEnabled)
    }

    func testToggleIndividual() {
        prefs.periodStarting = false
        prefs.overlayLifecycle = false
        let prefs2 = NotificationPreferences(defaults: defaults)
        XCTAssertFalse(prefs2.periodStarting)
        XCTAssertTrue(prefs2.periodSummary)
        XCTAssertFalse(prefs2.overlayLifecycle)
    }
}
```

- [ ] **Step 2: Run tests — expect compile failure (type not defined yet)**

```bash
xcodebuild test -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing PiggyPulseTests/NotificationPreferencesTests 2>&1 | tail -20
```

- [ ] **Step 3: Create NotificationPreferences**

```swift
// Core/Notifications/NotificationPreferences.swift
import Foundation

struct NotificationPreferences {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isEnabled: Bool {
        get { defaults.object(forKey: Key.enabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    var periodStarting: Bool {
        get { defaults.object(forKey: Key.periodStarting) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.periodStarting) }
    }

    var periodSummary: Bool {
        get { defaults.object(forKey: Key.periodSummary) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.periodSummary) }
    }

    var overlayLifecycle: Bool {
        get { defaults.object(forKey: Key.overlayLifecycle) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.overlayLifecycle) }
    }

    private enum Key {
        static let enabled = "notifications.enabled"
        static let periodStarting = "notifications.periodStarting"
        static let periodSummary = "notifications.periodSummary"
        static let overlayLifecycle = "notifications.overlayLifecycle"
    }
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
xcodebuild test -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing PiggyPulseTests/NotificationPreferencesTests 2>&1 | grep -E "PASS|FAIL|error:"
```

- [ ] **Step 5: Add to Xcode project**

Open `PiggyPulse.xcodeproj` in Xcode. Add `Core/Notifications/NotificationPreferences.swift` to the PiggyPulse target. Add `PiggyPulseTests/NotificationPreferencesTests.swift` to the PiggyPulseTests target. If PiggyPulseTests target doesn't exist, create it.

- [ ] **Step 6: Commit**

```bash
git add Core/Notifications/NotificationPreferences.swift PiggyPulseTests/NotificationPreferencesTests.swift
git commit -m "feat(notifications): NotificationPreferences with UserDefaults backing"
```

---

### Task 2: OverlayRepository

**Files:**
- Create: `Core/Repositories/OverlayRepository.swift`

- [ ] **Step 1: Confirm prerequisites exist**

Run both checks — both must return results before proceeding:

```bash
# Confirm .overlays endpoint exists
grep "overlays" /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios/Core/Network/APIEndpoints.swift

# Confirm OverlayItem model exists
grep "struct OverlayItem" /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios/Core/Models/Overlays.swift
```

Expected output for first command: a line containing `static let overlays`.
Expected output for second command: `struct OverlayItem`.
If either is missing, do not proceed — the endpoint or model needs to be added first.

- [ ] **Step 2: Confirm PeriodRepository has fetchPeriods()**

```bash
grep "func fetchPeriods" /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios/Core/Repositories/PeriodRepository.swift
```

Expected: `func fetchPeriods() async throws -> [BudgetPeriod]`. This is a dependency of Task 4.

- [ ] **Step 3: Create OverlayRepository**

```swift
// Core/Repositories/OverlayRepository.swift
import Foundation

final class OverlayRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchOverlays() async throws -> [OverlayItem] {
        let response: PaginatedResponse<OverlayItem> = try await apiClient.request(.overlays)
        return response.data
    }
}
```

- [ ] **Step 4: Add to Xcode project and build**

Add `Core/Repositories/OverlayRepository.swift` to the PiggyPulse target, then verify it compiles:

```bash
xcodebuild build -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5: Commit**

```bash
git add Core/Repositories/OverlayRepository.swift
git commit -m "feat(notifications): OverlayRepository"
```

---

## Chunk 2: NotificationScheduler

### Task 3: NotificationScheduler

**Files:**
- Create: `Core/Notifications/NotificationScheduler.swift`
- Create: `PiggyPulseTests/NotificationSchedulerTests.swift`

The scheduler is an `actor` so callers from both main actor and background tasks are safe. It takes a `UNUserNotificationCenter` and the two repositories as dependencies — this makes it testable.

- [ ] **Step 1: Create the test file**

```swift
// PiggyPulseTests/NotificationSchedulerTests.swift
import XCTest
import UserNotifications
@testable import PiggyPulse

// MARK: - Mock

final class MockNotificationCenter: NotificationCenterProtocol {
    var requestedAuthorization: UNAuthorizationOptions?
    var authorizationGranted = true
    var systemAuthorizationStatus: UNAuthorizationStatus = .authorized
    var removedIdentifiers: [String] = []
    var addedRequests: [UNNotificationRequest] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestedAuthorization = options
        return authorizationGranted
    }

    func notificationSettings() async -> UNNotificationSettings {
        // UNNotificationSettings cannot be instantiated directly; use a subclass for testing
        return MockNotificationSettings(authorizationStatus: systemAuthorizationStatus)
    }

    func removeAllPendingNotificationRequests() {
        removedIdentifiers.append("all")
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }
}

// UNNotificationSettings is not directly instantiable; subclass to override authorizationStatus
final class MockNotificationSettings: UNNotificationSettings {
    private let _authorizationStatus: UNAuthorizationStatus
    override var authorizationStatus: UNAuthorizationStatus { _authorizationStatus }
    init(authorizationStatus: UNAuthorizationStatus) {
        self._authorizationStatus = authorizationStatus
        // Note: UNNotificationSettings has no public init — if this causes issues at runtime,
        // use a wrapper protocol instead (see advisory in plan review notes).
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Tests

final class NotificationSchedulerTests: XCTestCase {
    var center: MockNotificationCenter!
    var scheduler: NotificationScheduler!
    var prefs: NotificationPreferences!

    override func setUp() {
        super.setUp()
        center = MockNotificationCenter()
        let defaults = UserDefaults(suiteName: "test-scheduler")!
        defaults.removePersistentDomain(forName: "test-scheduler")
        prefs = NotificationPreferences(defaults: defaults)
        scheduler = NotificationScheduler(center: center, prefs: prefs)
    }

    func testRequestsAuthorizationOnEnable() async throws {
        try await scheduler.requestAuthorization()
        XCTAssertEqual(center.requestedAuthorization, [.alert, .sound])
    }

    func testScheduleAllClearsPendingFirst() async throws {
        let period = makePeriod(start: daysFromNow(1), end: daysFromNow(30))
        try await scheduler.scheduleAll(periods: [period], overlays: [])
        XCTAssertTrue(center.removedIdentifiers.contains("all"))
    }

    func testSchedulesPeriodStartingNotification() async throws {
        let period = makePeriod(start: daysFromNow(2), end: daysFromNow(30))
        try await scheduler.scheduleAll(periods: [period], overlays: [])
        let ids = center.addedRequests.map(\.identifier)
        XCTAssertTrue(ids.contains(where: { $0.hasPrefix("piggy-pulse.period.start.") }))
    }

    func testSchedulesPeriodSummaryNotification() async throws {
        let period = makePeriod(start: daysFromNow(1), end: daysFromNow(5))
        try await scheduler.scheduleAll(periods: [period], overlays: [])
        let ids = center.addedRequests.map(\.identifier)
        XCTAssertTrue(ids.contains(where: { $0.hasPrefix("piggy-pulse.period.summary.") }))
    }

    func testSkipsPeriodStartingWhenDisabled() async throws {
        prefs.periodStarting = false
        let period = makePeriod(start: daysFromNow(2), end: daysFromNow(30))
        try await scheduler.scheduleAll(periods: [period], overlays: [])
        let ids = center.addedRequests.map(\.identifier)
        XCTAssertFalse(ids.contains(where: { $0.hasPrefix("piggy-pulse.period.start.") }))
    }

    func testSkipsAllWhenMasterDisabled() async throws {
        prefs.isEnabled = false
        let period = makePeriod(start: daysFromNow(2), end: daysFromNow(30))
        try await scheduler.scheduleAll(periods: [period], overlays: [])
        XCTAssertTrue(center.addedRequests.isEmpty)
    }

    func testSkipsAllWhenSystemAuthorizationDenied() async throws {
        center.systemAuthorizationStatus = .denied
        let period = makePeriod(start: daysFromNow(2), end: daysFromNow(30))
        try await scheduler.scheduleAll(periods: [period], overlays: [])
        XCTAssertTrue(center.addedRequests.isEmpty)
    }

    func testSchedulesOverlayStartingAndEnding() async throws {
        let overlay = makeOverlay(start: daysFromNow(3), end: daysFromNow(10))
        try await scheduler.scheduleAll(periods: [], overlays: [overlay])
        let ids = center.addedRequests.map(\.identifier)
        XCTAssertTrue(ids.contains(where: { $0.hasPrefix("piggy-pulse.overlay.start.") }))
        XCTAssertTrue(ids.contains(where: { $0.hasPrefix("piggy-pulse.overlay.end.") }))
    }

    func testSkipsPastDates() async throws {
        let period = makePeriod(start: daysFromNow(-5), end: daysFromNow(-1))
        try await scheduler.scheduleAll(periods: [period], overlays: [])
        XCTAssertTrue(center.addedRequests.isEmpty)
    }

    // MARK: - Helpers

    private func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date())!
    }

    private func makePeriod(start: Date, end: Date) -> BudgetPeriod {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return BudgetPeriod(
            id: UUID(),
            name: "Test Period",
            startDate: fmt.string(from: start),
            endDate: fmt.string(from: end),
            isAutoGenerated: false,
            transactionCount: 0,
            budgetUsedPercentage: 0
        )
    }

    private func makeOverlay(start: Date, end: Date) -> OverlayItem {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return OverlayItem(
            id: UUID(),
            name: "Test Overlay",
            icon: nil,
            startDate: fmt.string(from: start),
            endDate: fmt.string(from: end),
            inclusionMode: "all",
            totalCapAmount: nil,
            spentAmount: 0,
            transactionCount: 0,
            rules: nil,
            categoryCaps: nil
        )
    }
}
```

- [ ] **Step 2: Run — expect compile failure**

```bash
xcodebuild test -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing PiggyPulseTests/NotificationSchedulerTests 2>&1 | tail -20
```

- [ ] **Step 2b: Confirm BudgetPeriod computed date properties exist**

```bash
grep "startDateFormatted\|endDateFormatted" /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios/Core/Models/BudgetPeriod.swift
```

Expected: two computed properties returning `Date?`. The scheduler uses these. If they are missing, add them to `BudgetPeriod.swift` before creating the scheduler.

- [ ] **Step 3: Create NotificationCenterProtocol**

Add to top of `Core/Notifications/NotificationScheduler.swift`:

```swift
// Core/Notifications/NotificationScheduler.swift
import Foundation
import UserNotifications

// MARK: - Protocol (enables testing)

protocol NotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func notificationSettings() async -> UNNotificationSettings
    func removeAllPendingNotificationRequests()
    func add(_ request: UNNotificationRequest) async throws
}

extension UNUserNotificationCenter: NotificationCenterProtocol {}
```

- [ ] **Step 4: Create NotificationScheduler actor**

Append to same file:

```swift
// MARK: - Scheduler

actor NotificationScheduler {
    private let center: NotificationCenterProtocol
    private var prefs: NotificationPreferences

    static let prefix = "piggy-pulse."
    private static let horizonDays = 30

    init(
        center: NotificationCenterProtocol = UNUserNotificationCenter.current(),
        prefs: NotificationPreferences = NotificationPreferences()
    ) {
        self.center = center
        self.prefs = prefs
    }

    func requestAuthorization() async throws {
        _ = try await center.requestAuthorization(options: [.alert, .sound])
    }

    func scheduleAll(periods: [BudgetPeriod], overlays: [OverlayItem]) async throws {
        guard prefs.isEnabled else { return }

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        center.removeAllPendingNotificationRequests()

        let horizon = Calendar.current.date(byAdding: .day, value: Self.horizonDays, to: Date())!

        for period in periods {
            try await schedulePeriod(period, horizon: horizon)
        }
        for overlay in overlays {
            try await scheduleOverlay(overlay, horizon: horizon)
        }
    }

    // MARK: - Private

    private func schedulePeriod(_ period: BudgetPeriod, horizon: Date) async throws {
        guard let start = period.startDateFormatted, let end = period.endDateFormatted else { return }
        let now = Date()

        if prefs.periodStarting, start > now, start <= horizon {
            let content = makeContent(
                title: "New period starting",
                body: "\(period.name) begins today. Time to reflect."
            )
            try await center.add(request(id: "piggy-pulse.period.start.\(period.id)", date: start, content: content))
        }

        if prefs.periodSummary, end > now, end <= horizon {
            let content = makeContent(
                title: "Period wrapped up",
                body: "\(period.name) has ended. Tap to reflect on your spending."
            )
            try await center.add(request(id: "piggy-pulse.period.summary.\(period.id)", date: end, content: content))
        }
    }

    private func scheduleOverlay(_ overlay: OverlayItem, horizon: Date) async throws {
        guard prefs.overlayLifecycle else { return }
        guard let start = DateFormatter.apiDate.date(from: overlay.startDate),
              let end = DateFormatter.apiDate.date(from: overlay.endDate) else { return }
        let now = Date()

        if start > now, start <= horizon {
            let content = makeContent(
                title: "Overlay starting",
                body: "\(overlay.name) begins today."
            )
            try await center.add(request(id: "piggy-pulse.overlay.start.\(overlay.id)", date: start, content: content))
        }

        if end > now, end <= horizon {
            let content = makeContent(
                title: "Overlay ending",
                body: "\(overlay.name) ends today."
            )
            try await center.add(request(id: "piggy-pulse.overlay.end.\(overlay.id)", date: end, content: content))
        }
    }

    private func makeContent(title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return content
    }

    private func request(id: String, date: Date, content: UNMutableNotificationContent) -> UNNotificationRequest {
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }
}
```

- [ ] **Step 5: Check DateFormatter.apiDate exists**

Search for `apiDate` in the codebase:

```bash
grep -r "apiDate" /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios --include="*.swift"
```

If it doesn't exist as a static extension on `DateFormatter`, add it to `Core/Utilities/`:

```swift
// Core/Utilities/DateFormatter+API.swift (create if missing)
import Foundation

extension DateFormatter {
    static let apiDate: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt
    }()
}
```

- [ ] **Step 6: Run tests — expect PASS**

```bash
xcodebuild test -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing PiggyPulseTests/NotificationSchedulerTests 2>&1 | grep -E "PASS|FAIL|error:"
```

- [ ] **Step 7: Add files to Xcode project**

Add `Core/Notifications/NotificationScheduler.swift` to PiggyPulse target. Add test file to PiggyPulseTests target.

- [ ] **Step 8: Commit**

```bash
git add Core/Notifications/NotificationScheduler.swift PiggyPulseTests/NotificationSchedulerTests.swift
git commit -m "feat(notifications): NotificationScheduler actor with UNUserNotificationCenter"
```

---

## Chunk 3: AppState + PiggyPulseApp wiring

### Task 4: Wire scheduler into AppState

**Files:**
- Modify: `App/AppState.swift`

The scheduler needs the two repositories to fetch data. Add both repos and scheduler as properties.

- [ ] **Step 1: Add scheduler and repositories to AppState**

In `App/AppState.swift`, add these properties after `apiClient`:

```swift
let periodRepository: PeriodRepository
let overlayRepository: OverlayRepository
let notificationScheduler: NotificationScheduler
```

In `init()`, after `self.apiClient = APIClient(tokenManager: tm)`, add:

```swift
self.periodRepository = PeriodRepository(apiClient: apiClient)
self.overlayRepository = OverlayRepository(apiClient: apiClient)
self.notificationScheduler = NotificationScheduler()
```

- [ ] **Step 2: Call scheduler after successful auth**

In `checkAuth()`, after `await loadUserCurrency()`, add:

```swift
await scheduleNotifications()
```

Add the method to `AppState`:

```swift
func scheduleNotifications() async {
    do {
        async let periodsTask = periodRepository.fetchPeriods()
        async let overlaysTask = overlayRepository.fetchOverlays()
        let (periods, overlays) = try await (periodsTask, overlaysTask)
        try await notificationScheduler.scheduleAll(periods: periods, overlays: overlays)
    } catch {
        // Notifications are best-effort; do not surface errors to user
    }
}
```

- [ ] **Step 3: Build — expect success**

```bash
xcodebuild build -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

- [ ] **Step 4: Commit**

```bash
git add App/AppState.swift
git commit -m "feat(notifications): wire NotificationScheduler into AppState"
```

---

### Task 5: Background refresh in PiggyPulseApp

**Files:**
- Modify: `App/PiggyPulseApp.swift`
- Modify: `PiggyPulse-Info.plist`

- [ ] **Step 1: Read existing PiggyPulseApp.swift**

```bash
cat /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios/App/PiggyPulseApp.swift
```

Note any existing `init()`, scene modifiers, or environment setup that must be preserved in Step 2.

- [ ] **Step 2: Add BGTaskSchedulerPermittedIdentifiers to Info.plist**

Open `PiggyPulse-Info.plist`. Add key `BGTaskSchedulerPermittedIdentifiers` (Array) with one String item: `com.piggypulse.notifications.refresh`.

Or via Xcode: Project → PiggyPulse target → Info tab → add the key.

- [ ] **Step 3: Update PiggyPulseApp.swift**

Preserve any existing environment setup from Step 1. Add the BGTask registration, background handler, and `scheduleNextBackgroundRefresh` helper. The background handler re-submits the next refresh so the chain continues after each background execution.

```swift
import SwiftUI
import BackgroundTasks

@main
struct PiggyPulseApp: App {
    @StateObject private var appState = AppState()

    private static let bgTaskIdentifier = "com.piggypulse.notifications.refresh"

    init() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.bgTaskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Self.handleBackgroundRefresh(task: refreshTask)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.appColorScheme)
                .task {
                    await appState.checkAuth()
                    scheduleNextBackgroundRefresh()
                }
        }
    }

    private func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour minimum
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // A fresh AppState is created intentionally — background tasks run in a separate
        // execution context and cannot access the live appState from the main scene.
        // This instance reads auth tokens from Keychain independently.
        let appState = AppState()
        let taskHandle = Task {
            await appState.scheduleNotifications()
            // Re-submit so the background refresh chain continues
            let request = BGAppRefreshTaskRequest(identifier: bgTaskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
            try? BGTaskScheduler.shared.submit(request)
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            taskHandle.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
```

- [ ] **Step 4: Build — expect success**

```bash
xcodebuild build -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

- [ ] **Step 5: Commit**

```bash
git add App/PiggyPulseApp.swift PiggyPulse-Info.plist
git commit -m "feat(notifications): register BGAppRefreshTask for background scheduling"
```

---

## Chunk 4: Settings UI

### Task 6: NOTIFICATIONS card in SettingsView

**Files:**
- Modify: `Features/Settings/Views/SettingsView.swift`

- [ ] **Step 1: Confirm appState is accessible in SettingsView**

```bash
grep "appState" /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios/Features/Settings/Views/SettingsView.swift | head -5
```

Expected: `@EnvironmentObject var appState: AppState`. If missing, add this property to `SettingsView` before proceeding.

- [ ] **Step 2: Add @State properties for notification toggles**

In `SettingsView`, add after `@State private var isSavingPreferences`:

```swift
@State private var notificationsEnabled = true
@State private var notificationPeriodStarting = true
@State private var notificationPeriodSummary = true
@State private var notificationOverlayLifecycle = true
```

- [ ] **Step 3: Add notificationsCard view**

Sub-toggles are **disabled** (not hidden) when master is off — per HIG, users can see what options exist even when unavailable. Toggling any sub-preference immediately reschedules so the change takes effect without requiring an app restart.

Add the private computed property inside `SettingsView`:

```swift
private var notificationsCard: some View {
    VStack(alignment: .leading, spacing: PPSpacing.lg) {
        Text("NOTIFICATIONS")
            .font(.ppOverline)
            .foregroundColor(.ppTextSecondary)
            .tracking(1)

        Toggle(isOn: $notificationsEnabled) {
            Text("Notifications")
                .font(.ppBody)
                .foregroundColor(.ppTextPrimary)
        }
        .tint(.ppPrimary)
        .onChange(of: notificationsEnabled) { _, enabled in
            handleNotificationMasterToggle(enabled)
        }

        Divider().background(Color.ppBorder)

        Toggle(isOn: $notificationPeriodStarting) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Period starting")
                    .font(.ppBody)
                    .foregroundColor(.ppTextPrimary)
                Text("When a new period begins")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
        }
        .tint(.ppPrimary)
        .disabled(!notificationsEnabled)
        .onChange(of: notificationPeriodStarting) { _, v in
            var prefs = NotificationPreferences()
            prefs.periodStarting = v
            Task { await appState.scheduleNotifications() }
        }

        Toggle(isOn: $notificationPeriodSummary) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Period summary")
                    .font(.ppBody)
                    .foregroundColor(.ppTextPrimary)
                Text("When a period ends")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
        }
        .tint(.ppPrimary)
        .disabled(!notificationsEnabled)
        .onChange(of: notificationPeriodSummary) { _, v in
            var prefs = NotificationPreferences()
            prefs.periodSummary = v
            Task { await appState.scheduleNotifications() }
        }

        Toggle(isOn: $notificationOverlayLifecycle) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Overlay lifecycle")
                    .font(.ppBody)
                    .foregroundColor(.ppTextPrimary)
                Text("When an overlay starts or ends")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
        }
        .tint(.ppPrimary)
        .disabled(!notificationsEnabled)
        .onChange(of: notificationOverlayLifecycle) { _, v in
            var prefs = NotificationPreferences()
            prefs.overlayLifecycle = v
            Task { await appState.scheduleNotifications() }
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(PPSpacing.xl)
    .background(Color.ppCard)
    .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
    .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
}
```

- [ ] **Step 4: Add the master toggle handler**

When enabling, request system authorization. If denied, snap the toggle back to `false` and update `UserDefaults` — the toggle must reflect the real system state. Also re-sync all sub-toggle `@State` values from `UserDefaults` when re-enabling so they're consistent.

```swift
private func handleNotificationMasterToggle(_ enabled: Bool) {
    var prefs = NotificationPreferences()
    prefs.isEnabled = enabled
    if enabled {
        Task {
            try? await appState.notificationScheduler.requestAuthorization()
            // Check actual system authorization after requesting
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .denied {
                // System blocked — snap toggle back to off
                var p = NotificationPreferences()
                p.isEnabled = false
                notificationsEnabled = false
            } else {
                // Re-sync sub-toggles from UserDefaults in case they changed
                let p = NotificationPreferences()
                notificationPeriodStarting = p.periodStarting
                notificationPeriodSummary = p.periodSummary
                notificationOverlayLifecycle = p.overlayLifecycle
                await appState.scheduleNotifications()
            }
        }
    } else {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
```

- [ ] **Step 5: Load notification preferences on appear**

In the `load()` function, after setting `selectedNumberFormat`, add:

```swift
let prefs = NotificationPreferences()
notificationsEnabled = prefs.isEnabled
notificationPeriodStarting = prefs.periodStarting
notificationPeriodSummary = prefs.periodSummary
notificationOverlayLifecycle = prefs.overlayLifecycle
```

- [ ] **Step 6: Insert notificationsCard into view body**

In `body`, after `preferencesCard` and before `appInfoCard`:

```swift
notificationsCard
```

- [ ] **Step 7: Add UserNotifications import**

At the top of `SettingsView.swift`, add:

```swift
import UserNotifications
```

- [ ] **Step 8: Build — expect success**

```bash
xcodebuild build -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

- [ ] **Step 9: Commit**

```bash
git add Features/Settings/Views/SettingsView.swift
git commit -m "feat(notifications): add NOTIFICATIONS card to SettingsView"
```

---

## Chunk 5: Final verification

### Task 7: Full test run + manual checklist

- [ ] **Step 1: Run all tests**

```bash
xcodebuild test -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "PASS|FAIL|error:|Test Suite"
```

Expected: all tests pass, no errors.

- [ ] **Step 2: Manual smoke test on simulator**

1. Launch app on iOS Simulator (16+) — reset notification permissions first via Settings > General > Transfer or Reset iPhone > Reset > Reset Location & Privacy
2. Log in — system notification permission prompt should appear **exactly once**
3. Force-quit and relaunch the app — the system prompt must NOT appear again
4. Open Settings → confirm NOTIFICATIONS card is present with 3 sub-toggles
5. Toggle master off → confirm sub-toggles are **visible but greyed out** (disabled, not hidden), and pending notifications are cleared
6. Toggle "Period starting" off → confirm `UserDefaults` key `notifications.periodStarting` is `false` (Xcode debugger: `po UserDefaults.standard.bool(forKey: "notifications.periodStarting")`)
7. Toggle master back on → confirm sub-toggles become enabled again
8. Deny system permissions (via Simulator Settings), re-enable master toggle → confirm toggle snaps back to off

- [ ] **Step 3: Final commit + push**

```bash
git push origin feat/notifications
```
