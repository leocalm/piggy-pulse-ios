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

    override func tearDown() {
        defaults.removePersistentDomain(forName: "test-biometric")
        super.tearDown()
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
