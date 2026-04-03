import SwiftUI

/// Displays dashboard widgets in a single column when narrow, 2-column grid when wide.
/// Hero widgets (getting_started, current_period, net_position) always span full width.
/// Non-hero widgets in the grid are height-equalized per row.
struct AdaptiveWidgetGrid<Content: View>: View {
    let widgets: [String]
    let content: (String) -> Content

    /// Minimum width to switch to 2-column grid
    private let twoColumnThreshold: CGFloat = 700

    init(widgets: [String], @ViewBuilder content: @escaping (String) -> Content) {
        self.widgets = widgets
        self.content = content
    }

    private let heroIds: Set<String> = ["getting_started", "current_period", "net_position"]

    var body: some View {
        GeometryReader { geo in
            let useGrid = geo.size.width >= twoColumnThreshold
            if useGrid {
                gridLayout(width: geo.size.width)
            } else {
                stackLayout
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Single column

    private var stackLayout: some View {
        ForEach(widgets, id: \.self) { widgetId in
            content(widgetId)
        }
    }

    // MARK: - Two-column grid

    private func gridLayout(width: CGFloat) -> some View {
        let spacing = PPSpacing.lg
        let columnWidth = (width - spacing) / 2
        let rows = buildRows()

        return VStack(spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                if row.count == 1 {
                    content(row[0])
                } else {
                    HStack(alignment: .top, spacing: spacing) {
                        content(row[0])
                            .frame(maxWidth: .infinity)
                        content(row[1])
                            .frame(maxWidth: .infinity)
                    }
                    // Equal heights: both cards stretch to match the taller one
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// Group widgets into rows: heroes get their own full-width row, non-heroes pair up.
    private func buildRows() -> [[String]] {
        var rows: [[String]] = []
        var pending: String? = nil

        for widgetId in widgets {
            if heroIds.contains(widgetId) {
                if let p = pending {
                    rows.append([p])
                    pending = nil
                }
                rows.append([widgetId])
                continue
            }

            if let p = pending {
                rows.append([p, widgetId])
                pending = nil
            } else {
                pending = widgetId
            }
        }

        if let p = pending {
            rows.append([p])
        }

        return rows
    }
}
