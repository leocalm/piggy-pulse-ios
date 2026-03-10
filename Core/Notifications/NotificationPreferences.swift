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
