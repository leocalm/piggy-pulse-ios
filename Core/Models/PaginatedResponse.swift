import Foundation

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let totalCount: Int?
    let hasMore: Bool?
    let nextCursor: String?
}
