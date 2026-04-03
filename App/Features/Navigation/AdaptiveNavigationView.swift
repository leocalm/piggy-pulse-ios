import SwiftUI

/// Adaptive navigation that uses tab bar on iPhone and sidebar on iPad.
struct AdaptiveNavigationView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            SidebarNavigationView()
        } else {
            MainTabView()
        }
    }
}
