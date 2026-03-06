import Foundation

struct Transaction: Codable, Identifiable {
    let id: UUID
    let amount: Int64
    let description: String
    let occurredAt: String
    let category: TransactionCategory
    let fromAccount: TransactionAccount
    let toAccount: TransactionAccount?
    let vendor: TransactionVendor?

    var isTransfer: Bool {
        toAccount != nil
    }

    var isIncoming: Bool {
        category.categoryType == "incoming"
    }

    var formattedDate: String {
        guard let date = DateFormatter.apiDate.date(from: occurredAt) else { return occurredAt }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        return fmt.string(from: date)
    }
}

struct TransactionCategory: Codable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
    let categoryType: String
}

struct TransactionAccount: Codable, Identifiable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
    let accountType: String
}

struct TransactionVendor: Codable, Identifiable {
    let id: UUID
    let name: String
}

// Cursor-paginated response for transactions
struct CursorPaginatedTransactions: Codable {
    let data: [Transaction]
    let nextCursor: UUID?
}

// Reusable date formatter
extension DateFormatter {
    static let apiDate: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt
    }()
}

enum TransactionDirection: String, CaseIterable {
    case all = "All"
    case incoming = "Incoming"
    case outgoing = "Outgoing"
    case transfers = "Transfers"

    var queryValue: String? {
        switch self {
        case .all: return nil
        case .incoming: return "Incoming"
        case .outgoing: return "Outgoing"
        case .transfers: return "Transfer"
        }
    }
}
