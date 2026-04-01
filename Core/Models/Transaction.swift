import Foundation

struct Transaction: Codable, Identifiable {
    let id: UUID
    let amount: Int64
    let description: String
    let date: String               // "2024-01-15"
    let transactionType: String    // "regular" | "transfer"
    let category: TransactionCategory
    let fromAccount: TransactionAccount
    let toAccount: TransactionAccount?
    let vendor: TransactionVendor?

    // MARK: - Backward compatibility

    var occurredAt: String { date }

    var isTransfer: Bool {
        toAccount != nil
    }

    var isIncoming: Bool {
        category.type == "income"
    }

    var formattedDate: String {
        guard let d = DateFormatter.apiDate.date(from: date) else { return date }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        return fmt.string(from: d)
    }
}

extension Transaction: Equatable {
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        lhs.id == rhs.id
    }
}

extension Transaction: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct TransactionCategory: Codable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
    let type: String       // "income" | "expense" | "transfer"

    // MARK: - Backward compatibility
    var categoryType: String { type }
}

struct TransactionAccount: Codable, Identifiable {
    let id: UUID
    let name: String
    let color: String
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
    case all, incoming, outgoing, transfers

    var label: String {
        switch self {
        case .all: return String(localized: "All")
        case .incoming: return String(localized: "Incoming")
        case .outgoing: return String(localized: "Outgoing")
        case .transfers: return String(localized: "Transfers")
        }
    }

    var queryValue: String? {
        switch self {
        case .all: return nil
        case .incoming: return "income"
        case .outgoing: return "expense"
        case .transfers: return "transfer"
        }
    }
}
