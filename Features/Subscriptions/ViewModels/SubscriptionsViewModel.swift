import SwiftUI
internal import Combine

@MainActor
final class SubscriptionsViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var upcomingCharges: [UpcomingCharge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var repository: SubscriptionRepository?

    init(apiClient: APIClient) {
        self.repository = SubscriptionRepository(apiClient: apiClient)
    }

    init() {}

    func configure(apiClient: APIClient) {
        guard repository == nil else { return }
        repository = SubscriptionRepository(apiClient: apiClient)
    }

    // MARK: - Computed

    var activeSubs: [Subscription] {
        subscriptions.filter { $0.status == .active }
    }

    var pausedSubs: [Subscription] {
        subscriptions.filter { $0.status == .paused }
    }

    var cancelledSubs: [Subscription] {
        subscriptions.filter { $0.status == .cancelled }
    }

    /// Monthly cost in cents for all active subscriptions.
    var monthlyCost: Int64 {
        activeSubs.reduce(Int64(0)) { total, sub in
            switch sub.billingCycle {
            case .monthly: return total + sub.billingAmount
            case .quarterly: return total + Int64((Double(sub.billingAmount) / 3.0).rounded())
            case .yearly: return total + Int64((Double(sub.billingAmount) / 12.0).rounded())
            }
        }
    }

    /// Yearly cost in cents for all active subscriptions.
    var yearlyCost: Int64 {
        activeSubs.reduce(Int64(0)) { total, sub in
            switch sub.billingCycle {
            case .monthly: return total + sub.billingAmount * 12
            case .quarterly: return total + sub.billingAmount * 4
            case .yearly: return total + sub.billingAmount
            }
        }
    }

    // MARK: - Actions

    func load() async {
        guard let repository else { return }
        isLoading = true
        errorMessage = nil

        async let subsTask = repository.fetchSubscriptions()
        async let upcomingTask: [UpcomingCharge]? = Self.tryFetch { try await repository.fetchUpcomingCharges(limit: 5) }

        do {
            subscriptions = try await subsTask
        } catch {
            errorMessage = String(localized: "subscription.loadError")
        }

        upcomingCharges = await upcomingTask ?? []
        isLoading = false
    }

    func deleteSubscription(id: UUID) async {
        guard let repository else { return }
        do {
            try await repository.deleteSubscription(id: id)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            await load()
        } catch {
            errorMessage = String(localized: "subscription.deleteFailed")
        }
    }

    func cancelSubscription(id: UUID, date: String) async {
        guard let repository else { return }
        do {
            let _ = try await repository.cancelSubscription(id: id, body: CancelSubscriptionRequest(cancellationDate: date))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            await load()
        } catch {
            errorMessage = String(localized: "subscription.cancelFailed")
        }
    }

    private static func tryFetch<T: Sendable>(_ work: @Sendable () async throws -> T) async -> T? {
        try? await work()
    }
}
