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

    func notificationSettings() async -> any NotificationSettingsProtocol {
        MockNotificationSettings(authorizationStatus: systemAuthorizationStatus)
    }

    func removeAllPendingNotificationRequests() {
        removedIdentifiers.append("all")
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }
}

struct MockNotificationSettings: NotificationSettingsProtocol {
    var authorizationStatus: UNAuthorizationStatus
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
