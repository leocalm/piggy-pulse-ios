// Core/Notifications/NotificationScheduler.swift
import Foundation
import UserNotifications

// MARK: - Protocol (enables testing)

protocol NotificationSettingsProtocol {
    var authorizationStatus: UNAuthorizationStatus { get }
}

extension UNNotificationSettings: NotificationSettingsProtocol {}

protocol NotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func notificationSettings() async -> any NotificationSettingsProtocol
    func removeAllPendingNotificationRequests()
    func add(_ request: UNNotificationRequest) async throws
}

// MARK: - Live adapter

final class LiveNotificationCenter: NotificationCenterProtocol {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await center.requestAuthorization(options: options)
    }

    func notificationSettings() async -> any NotificationSettingsProtocol {
        await center.notificationSettings()
    }

    func removeAllPendingNotificationRequests() {
        center.removeAllPendingNotificationRequests()
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }
}

// MARK: - Scheduler

actor NotificationScheduler {
    private let center: NotificationCenterProtocol
    private var prefs: NotificationPreferences

    static let prefix = "piggy-pulse."
    private static let horizonDays = 30

    init(
        center: NotificationCenterProtocol = LiveNotificationCenter(),
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
