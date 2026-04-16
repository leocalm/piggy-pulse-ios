import Foundation

final class SubscriptionRepository {
    private let apiClient: APIClient
    private let decryptionService: DecryptionService

    init(apiClient: APIClient, decryptionService: DecryptionService) {
        self.apiClient = apiClient
        self.decryptionService = decryptionService
    }

    @MainActor
    func fetchSubscriptions() async throws -> [Subscription] {
        let encrypted: [EncryptedSubscription] = try await apiClient.request(.subscriptions)
        return try decryptionService.decrypt(encrypted)
    }

    @MainActor
    func fetchSubscriptions(categoryId: UUID) async throws -> [Subscription] {
        let encrypted: [EncryptedSubscription] = try await apiClient.request(.subscriptions, queryItems: [
            URLQueryItem(name: "categoryId", value: categoryId.uuidString)
        ])
        return try decryptionService.decrypt(encrypted)
    }

    func createSubscription(body: CreateSubscriptionRequest) async throws {
        try await apiClient.request(.createSubscription, body: body) as Subscription
    }

    func updateSubscription(id: UUID, body: UpdateSubscriptionRequest) async throws {
        try await apiClient.request(.updateSubscription(id), body: body) as Subscription
    }

    func deleteSubscription(id: UUID) async throws {
        try await apiClient.requestVoid(.deleteSubscription(id))
    }

    func cancelSubscription(id: UUID, body: CancelSubscriptionRequest) async throws {
        try await apiClient.request(.cancelSubscription(id), body: body) as Subscription
    }
}
