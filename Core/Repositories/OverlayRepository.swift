import Foundation

final class OverlayRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchOverlays() async throws -> [OverlayItem] {
        let response: PaginatedResponse<OverlayItem> = try await apiClient.request(.overlays)
        return response.data
    }
}
