import SwiftUI
internal import Combine

@MainActor
final class SubscriptionsViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var upcomingCharges: [Subscription] = []
    @Published var categorySubscriptions: [Subscription] = []
    @Published var isLoading = false
    @Published var isCategoryLoading = false
    @Published var errorMessage: String?

    private var repository: SubscriptionRepository?

    init(apiClient: APIClient, decryptionService: DecryptionService) {
        self.repository = SubscriptionRepository(apiClient: apiClient, decryptionService: decryptionService)
    }

    init() {}

    func configure(apiClient: APIClient, decryptionService: DecryptionService) {
        guard repository == nil else { return }
        repository = SubscriptionRepository(apiClient: apiClient, decryptionService: decryptionService)
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

    var monthlyCost: Int64 {
        activeSubs.reduce(Int64(0)) { total, sub in
            switch sub.billingCycle {
            case .monthly: return total + sub.billingAmount
            case .quarterly: return total + Int64((Double(sub.billingAmount) / 3.0).rounded())
            case .yearly: return total + Int64((Double(sub.billingAmount) / 12.0).rounded())
            }
        }
    }

    var categoryMonthlyCost: Int64 {
        categorySubscriptions.filter { $0.status == .active }.reduce(Int64(0)) { total, sub in
            switch sub.billingCycle {
            case .monthly: return total + sub.billingAmount
            case .quarterly: return total + Int64((Double(sub.billingAmount) / 3.0).rounded())
            case .yearly: return total + Int64((Double(sub.billingAmount) / 12.0).rounded())
            }
        }
    }

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

        do {
            subscriptions = try await repository.fetchSubscriptions()
            upcomingCharges = subscriptions
                .filter { $0.status == .active }
                .sorted { $0.nextChargeDate < $1.nextChargeDate }
                .prefix(5)
                .map { $0 }
        } catch {
            errorMessage = String(localized: "subscription.loadError")
        }

        isLoading = false
    }

    func deleteSubscription(id: UUID, reloadAfter: Bool = true) async {
        guard let repository else { return }
        do {
            try await repository.deleteSubscription(id: id)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if reloadAfter { await load() }
        } catch {
            errorMessage = String(localized: "subscription.deleteFailed")
        }
    }

    func cancelSubscription(id: UUID, date: String) async {
        guard let repository else { return }
        do {
            try await repository.cancelSubscription(id: id, body: CancelSubscriptionRequest(cancellationDate: date))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            await load()
        } catch {
            errorMessage = String(localized: "subscription.cancelFailed")
        }
    }

    func loadForCategory(categoryId: UUID) async {
        guard let repository else { return }
        isCategoryLoading = true
        errorMessage = nil
        do {
            categorySubscriptions = try await repository.fetchSubscriptions(categoryId: categoryId)
        } catch {
            errorMessage = String(localized: "subscription.loadError")
        }
        isCategoryLoading = false
    }
}
