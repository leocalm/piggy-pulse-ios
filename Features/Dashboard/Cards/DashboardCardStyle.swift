import SwiftUI

/// Shared card styling for dashboard widgets.
struct DashboardCardModifier: ViewModifier {
    var highlighted: Bool = false
    @Environment(\.themeManager) private var theme

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(PPSpacing.xl)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.lg)
                    .stroke(
                        highlighted ? theme.primary.opacity(0.3) : Color.ppBorder,
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func dashboardCard(highlighted: Bool = false) -> some View {
        modifier(DashboardCardModifier(highlighted: highlighted))
    }
}
