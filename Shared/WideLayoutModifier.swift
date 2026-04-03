import SwiftUI

/// Environment key that indicates whether the current view has enough width for a multi-column layout.
/// Set by `WideLayoutReader` based on actual available width, not just size class.
private struct IsWideLayoutKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isWideLayout: Bool {
        get { self[IsWideLayoutKey.self] }
        set { self[IsWideLayoutKey.self] = newValue }
    }
}

/// Measures available width and sets `isWideLayout` in the environment.
/// Use at the top of a screen's body to propagate width info to children.
struct WideLayoutReader<Content: View>: View {
    let threshold: CGFloat
    let content: (Bool) -> Content

    init(threshold: CGFloat = 600, @ViewBuilder content: @escaping (Bool) -> Content) {
        self.threshold = threshold
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            content(geo.size.width >= threshold)
                .environment(\.isWideLayout, geo.size.width >= threshold)
        }
    }
}
