import Foundation

final class SubscriptionRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchSubscriptions() async throws -> [Subscription] {
        try await apiClient.request(.subscriptions)
    }

    func fetchSubscriptions(categoryId: UUID) async throws -> [Subscription] {
        try await apiClient.request(.subscriptions, queryItems: [
            URLQueryItem(name: "categoryId", value: categoryId.uuidString)
        ])
    }

    func fetchSubscription(id: UUID) async throws -> SubscriptionDetail {
        try await apiClient.request(.subscription(id))
    }

    func createSubscription(body: CreateSubscriptionRequest) async throws -> Subscription {
        try await apiClient.request(.createSubscription, body: body)
    }

    func updateSubscription(id: UUID, body: UpdateSubscriptionRequest) async throws -> Subscription {
        try await apiClient.request(.updateSubscription(id), body: body)
    }

    func deleteSubscription(id: UUID) async throws {
        try await apiClient.requestVoid(.deleteSubscription(id))
    }

    func cancelSubscription(id: UUID, body: CancelSubscriptionRequest) async throws -> Subscription {
        try await apiClient.request(.cancelSubscription(id), body: body)
    }

    func fetchUpcomingCharges(limit: Int = 5) async throws -> [UpcomingCharge] {
        try await apiClient.request(.upcomingCharges, queryItems: [
            URLQueryItem(name: "limit", value: String(limit))
        ])
    }
}
