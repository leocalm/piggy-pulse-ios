import Foundation

enum AppConstants {
    static let appGroupIdentifier: String = {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
              !id.isEmpty else {
            fatalError("AppGroupIdentifier not set in Info.plist")
        }
        return id
    }()
}
