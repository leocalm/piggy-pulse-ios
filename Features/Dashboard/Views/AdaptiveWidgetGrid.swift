import SwiftUI

/// Displays dashboard widgets in a single column when narrow, 2-column grid when wide.
/// Hero widgets always span full width. Non-hero widgets pair up in wide mode.
struct AdaptiveWidgetGrid<Content: View>: View {
    let widgets: [String]
    let content: (String) -> Content
    let useGrid: Bool

    private let heroIds: Set<String> = ["getting_started", "current_period", "net_position"]

    init(widgets: [String], useGrid: Bool, @ViewBuilder content: @escaping (String) -> Content) {
        self.widgets = widgets
        self.useGrid = useGrid
        self.content = content
    }

    var body: some View {
        if useGrid {
            gridLayout
        } else {
            stackLayout
        }
    }

    // MARK: - Single column

    private var stackLayout: some View {
        ForEach(widgets, id: \.self) { widgetId in
            content(widgetId)
        }
    }

    // MARK: - Two-column grid

    private var gridLayout: some View {
        let rows = buildRows()
        return VStack(spacing: PPSpacing.lg) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                if row.count == 1 {
                    content(row[0])
                } else {
                    EqualHeightHStack(spacing: PPSpacing.lg) {
                        content(row[0])
                        content(row[1])
                    }
                }
            }
        }
    }

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

// MARK: - Equal Height HStack

/// An HStack where all children are stretched to the height of the tallest child.
struct EqualHeightHStack: Layout {
    var spacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let resolved = proposal.replacingUnspecifiedDimensions()
        let width = resolved.width
        let childWidth = (width - spacing * CGFloat(max(subviews.count - 1, 0))) / CGFloat(max(subviews.count, 1))
        let maxHeight = subviews.map { $0.sizeThatFits(.init(width: childWidth, height: nil)).height }.max() ?? 0
        return CGSize(width: width, height: maxHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let childWidth = (bounds.width - spacing * CGFloat(max(subviews.count - 1, 0))) / CGFloat(max(subviews.count, 1))
        let maxHeight = subviews.map { $0.sizeThatFits(.init(width: childWidth, height: nil)).height }.max() ?? bounds.height

        var x = bounds.minX
        for subview in subviews {
            subview.place(at: CGPoint(x: x, y: bounds.minY), proposal: .init(width: childWidth, height: maxHeight))
            x += childWidth + spacing
        }
    }
}
