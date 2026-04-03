import SwiftUI

/// Environment key that indicates whether the current view has enough width for a multi-column layout.
/// Set by the sidebar's detail area GeometryReader based on actual available width.
private struct IsWideLayoutKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isWideLayout: Bool {
        get { self[IsWideLayoutKey.self] }
        set { self[IsWideLayoutKey.self] = newValue }
    }
}
