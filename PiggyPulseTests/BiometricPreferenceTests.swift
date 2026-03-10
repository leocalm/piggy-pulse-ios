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
