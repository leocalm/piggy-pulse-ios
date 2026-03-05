import Foundation

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let nextCursor: String?
}
