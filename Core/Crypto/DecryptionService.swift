import CryptoKit
import Foundation

@MainActor
final class DecryptionService {
    private var dek: SymmetricKey?

    var isUnlocked: Bool { dek != nil }

    func setDEK(_ key: SymmetricKey) {
        dek = key
    }

    func clearDEK() {
        dek = nil
    }

    func getDEK() throws -> SymmetricKey {
        guard let dek else { throw CryptoError.noDEK }
        return dek
    }

    func dekBase64() throws -> String {
        let key = try getDEK()
        return key.withUnsafeBytes { Data($0).base64EncodedString() }
    }

    // MARK: - Account decryption

    func decrypt(_ encrypted: EncryptedAccount) throws -> AccountListItem {
        let key = try getDEK()
        return AccountListItem(
            id: encrypted.id,
            name: try CryptoManager.decryptString(encrypted.nameEnc, using: key),
            color: try CryptoManager.decryptString(encrypted.colorEnc, using: key),
            icon: try CryptoManager.decryptStringOptional(encrypted.iconEnc, using: key) ?? "💰",
            type: encrypted.accountType,
            status: encrypted.status,
            currentBalance: try CryptoManager.decryptInt64(encrypted.currentBalanceEnc, using: key),
            spendLimit: try CryptoManager.decryptInt32Optional(encrypted.spendLimitEnc, using: key)
        )
    }

    func decrypt(_ accounts: [EncryptedAccount]) throws -> [AccountListItem] {
        accounts.compactMap { try? decrypt($0) }
    }

    // MARK: - Category decryption

    func decrypt(_ encrypted: EncryptedCategory) throws -> CategoryListItem {
        let key = try getDEK()
        return CategoryListItem(
            id: encrypted.id,
            name: CryptoManager.decryptStringOrPlaintext(encrypted.nameEnc, using: key),
            color: encrypted.colorEnc.map { CryptoManager.decryptStringOrPlaintext($0, using: key) } ?? "#888888",
            icon: encrypted.iconEnc.map { CryptoManager.decryptStringOrPlaintext($0, using: key) } ?? "📁",
            type: encrypted.type,
            status: encrypted.status,
            parentId: encrypted.parentId,
            behavior: encrypted.behavior
        )
    }

    func decrypt(_ categories: [EncryptedCategory]) throws -> [CategoryListItem] {
        categories.compactMap { try? decrypt($0) }
    }

    // MARK: - Vendor decryption

    func decrypt(_ encrypted: EncryptedVendor) throws -> VendorListItem {
        let key = try getDEK()
        return VendorListItem(
            id: encrypted.id,
            name: try CryptoManager.decryptString(encrypted.nameEnc, using: key),
            description: try CryptoManager.decryptStringOptional(encrypted.descriptionEnc, using: key),
            status: encrypted.status
        )
    }

    func decrypt(_ vendors: [EncryptedVendor]) throws -> [VendorListItem] {
        vendors.compactMap { try? decrypt($0) }
    }

    // MARK: - Subscription decryption

    func decrypt(_ encrypted: EncryptedSubscription) throws -> Subscription {
        let key = try getDEK()
        return Subscription(
            id: encrypted.id,
            name: try CryptoManager.decryptString(encrypted.nameEnc, using: key),
            categoryId: encrypted.categoryId,
            vendorId: encrypted.vendorId,
            billingAmount: try CryptoManager.decryptInt64(encrypted.billingAmountEnc, using: key),
            billingCycle: encrypted.billingCycle,
            billingDay: encrypted.billingDay,
            nextChargeDate: encrypted.nextChargeDate,
            status: encrypted.status,
            cancelledAt: encrypted.cancelledAt,
            createdAt: encrypted.createdAt,
            updatedAt: encrypted.updatedAt
        )
    }

    func decrypt(_ subscriptions: [EncryptedSubscription]) throws -> [Subscription] {
        subscriptions.compactMap { try? decrypt($0) }
    }

    // MARK: - Target decryption

    func decrypt(_ encrypted: EncryptedTarget, categories: [CategoryListItem]) throws -> CategoryTarget {
        let key = try getDEK()
        let category = categories.first { $0.id == encrypted.categoryId }
        let budgeted = try CryptoManager.decryptInt64(encrypted.budgetedValueEnc, using: key)
        return CategoryTarget(
            id: encrypted.id,
            categoryId: encrypted.categoryId,
            name: category?.name ?? "",
            type: category?.type ?? "expense",
            parentId: category?.parentId,
            budgetedValue: Int32(clamping: budgeted),
            isExcluded: encrypted.isExcluded
        )
    }

    // MARK: - Transaction decryption

    func decrypt(_ encrypted: EncryptedTransaction, accounts: [AccountListItem], categories: [CategoryListItem], vendors: [VendorListItem]) throws -> Transaction {
        let key = try getDEK()
        let amount = try CryptoManager.decryptInt64(encrypted.amountEnc, using: key)
        let description = try CryptoManager.decryptString(encrypted.descriptionEnc, using: key)

        let fromAccount = accounts.first { $0.id == encrypted.fromAccountId }
        let toAccount = encrypted.toAccountId.flatMap { toId in accounts.first { $0.id == toId } }
        let category = encrypted.categoryId.flatMap { catId in categories.first { $0.id == catId } }
        let vendor = encrypted.vendorId.flatMap { vendId in vendors.first { $0.id == vendId } }

        return Transaction(
            id: encrypted.id,
            amount: amount,
            description: description,
            date: encrypted.date,
            transactionType: toAccount != nil ? "transfer" : "regular",
            category: TransactionCategory(
                id: category?.id ?? UUID(),
                name: category?.name ?? "Unknown",
                color: category?.color ?? "#888888",
                icon: category?.icon ?? "❓",
                type: category?.type ?? "expense"
            ),
            fromAccount: TransactionAccount(
                id: fromAccount?.id ?? encrypted.fromAccountId,
                name: fromAccount?.name ?? "Unknown",
                color: fromAccount?.color ?? "#888888"
            ),
            toAccount: toAccount.map {
                TransactionAccount(id: $0.id, name: $0.name, color: $0.color)
            },
            vendor: vendor.map {
                TransactionVendor(id: $0.id, name: $0.name)
            }
        )
    }

    func decryptTransactions(_ encrypted: [EncryptedTransaction], accounts: [AccountListItem], categories: [CategoryListItem], vendors: [VendorListItem]) throws -> [Transaction] {
        encrypted.compactMap { try? decrypt($0, accounts: accounts, categories: categories, vendors: vendors) }
    }
}
