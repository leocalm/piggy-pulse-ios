import Foundation

enum SubscriptionStatus: String, Codable {
    case active, cancelled, paused
}

enum BillingCycle: String, Codable, CaseIterable {
    case monthly, quarterly, yearly

    var displayName: String {
        switch self {
        case .monthly: return String(localized: "subscription.cycle.monthly")
        case .quarterly: return String(localized: "subscription.cycle.quarterly")
        case .yearly: return String(localized: "subscription.cycle.yearly")
        }
    }

    var monthMultiplier: Int {
        switch self {
        case .monthly: return 1
        case .quarterly: return 3
        case .yearly: return 12
        }
    }
}

struct Subscription: Codable, Identifiable {
    let id: UUID
    let name: String
    let categoryId: UUID
    let vendorId: UUID?
    let billingAmount: Int64
    let billingCycle: BillingCycle
    let billingDay: Int
    let nextChargeDate: String
    let status: SubscriptionStatus
    let cancelledAt: String?
    let createdAt: String
    let updatedAt: String
}

extension Subscription: Hashable {
    static func == (lhs: Subscription, rhs: Subscription) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct SubscriptionDetail: Codable {
    let id: UUID
    let name: String
    let categoryId: UUID
    let vendorId: UUID?
    let billingAmount: Int64
    let billingCycle: BillingCycle
    let billingDay: Int
    let nextChargeDate: String
    let status: SubscriptionStatus
    let cancelledAt: String?
    let createdAt: String
    let updatedAt: String
    let billingHistory: [BillingEvent]
}

struct BillingEvent: Codable, Identifiable {
    let id: UUID
    let subscriptionId: UUID
    let transactionId: UUID?
    let amount: Int64
    let date: String
    let detected: Bool
    let postCancellation: Bool
}

struct UpcomingCharge: Codable, Identifiable {
    var id: UUID { subscriptionId }
    let subscriptionId: UUID
    let name: String
    let billingAmount: Int64
    let billingCycle: BillingCycle
    let nextChargeDate: String
    let vendorId: UUID?
    let vendorName: String?
}

struct CreateSubscriptionRequest: Encodable {
    let name: String
    let categoryId: UUID
    let vendorId: UUID?
    let billingAmount: Int64
    let billingCycle: BillingCycle
    let billingDay: Int
    let nextChargeDate: String
}

struct UpdateSubscriptionRequest: Encodable {
    let name: String?
    let categoryId: UUID?
    let vendorId: UUID?
    let billingAmount: Int64?
    let billingCycle: BillingCycle?
    let billingDay: Int?
    let nextChargeDate: String?
    let status: SubscriptionStatus?
}

struct CancelSubscriptionRequest: Encodable {
    let cancellationDate: String
}
