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
