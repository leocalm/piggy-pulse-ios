import Foundation

// MARK: - Encrypted API response models
// These match the v2 encrypted response shapes. All *Enc fields are base64 AES-GCM envelopes.

struct EncryptedAccount: Codable, Identifiable {
    let id: UUID
    let nameEnc: String
    let colorEnc: String
    let iconEnc: String?
    let accountType: String
    let status: String
    let currencyId: UUID?
    let currentBalanceEnc: String
    let spendLimitEnc: String?
    let nextTransferAmountEnc: String?
    let topUpAmountEnc: String?
    let topUpCycle: String?
    let topUpDay: Int?
    let statementCloseDay: Int?
    let paymentDueDay: Int?
}

struct EncryptedCategory: Codable, Identifiable {
    let id: UUID
    let nameEnc: String
    let colorEnc: String?
    let iconEnc: String?
    let descriptionEnc: String?
    let type: String
    let status: String
    let parentId: UUID?
    let behavior: String?
    let isSystem: Bool?
}

struct EncryptedVendor: Codable, Identifiable {
    let id: UUID
    let nameEnc: String
    let descriptionEnc: String?
    let status: String
}

struct EncryptedSubscription: Codable, Identifiable {
    let id: UUID
    let nameEnc: String
    let categoryId: UUID
    let vendorId: UUID?
    let billingAmountEnc: String
    let billingCycle: BillingCycle
    let billingDay: Int
    let nextChargeDate: String
    let status: SubscriptionStatus
    let cancelledAt: String?
    let createdAt: String
    let updatedAt: String
}

struct EncryptedTarget: Codable, Identifiable {
    let id: UUID
    let categoryId: UUID
    let budgetedValueEnc: String
    let isExcluded: Bool
}

struct EncryptedTransaction: Codable, Identifiable {
    let id: UUID
    let seq: Int64?
    let amountEnc: String
    let descriptionEnc: String
    let date: String
    let firstCreatedAt: String?
    let fromAccountId: UUID
    let toAccountId: UUID?
    let categoryId: UUID?
    let vendorId: UUID?
}

struct EncryptedTransactionsResponse: Codable {
    let data: [EncryptedTransaction]
    let nextCursor: UUID?
}

// MARK: - Auth / Key Management response models

struct WrappedDekResponse: Codable {
    let wrappedDek: String?
    let dekWrapParams: DekWrapParams?
}

struct UnlockRequest: Encodable {
    let dek: String
}
