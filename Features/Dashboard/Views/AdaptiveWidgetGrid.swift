import SwiftUI

/// Displays dashboard widgets in a single column on iPhone, 2-column grid on iPad.
/// Hero widgets (getting_started, current_period, net_position) span full width.
struct AdaptiveWidgetGrid<Content: View>: View {
    let widgets: [String]
    let content: (String) -> Content

    @Environment(\.horizontalSizeClass) private var sizeClass

    init(widgets: [String], @ViewBuilder content: @escaping (String) -> Content) {
        self.widgets = widgets
        self.content = content
    }

    var body: some View {
        if sizeClass == .regular {
            iPadGrid
        } else {
            iPhoneStack
        }
    }

    // MARK: - iPhone: single column

    private var iPhoneStack: some View {
        ForEach(widgets, id: \.self) { widgetId in
            content(widgetId)
        }
    }

    // MARK: - iPad: 2-column grid with hero spanning

    private var iPadGrid: some View {
        let heroIds: Set<String> = ["getting_started", "current_period", "net_position"]
        let columns = [
            GridItem(.flexible(), spacing: PPSpacing.lg),
            GridItem(.flexible(), spacing: PPSpacing.lg),
        ]

        return LazyVGrid(columns: columns, spacing: PPSpacing.lg) {
            ForEach(widgets, id: \.self) { widgetId in
                let isHero = heroIds.contains(widgetId)
                content(widgetId)
                    .gridCellColumns(isHero ? 2 : 1)
            }
        }
    }
}
