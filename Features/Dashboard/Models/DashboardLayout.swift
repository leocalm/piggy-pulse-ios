import SwiftUI

/// Manages the dashboard widget layout — order, visibility, and persistence.
@Observable
@MainActor
final class DashboardLayout {
    private static let orderKey = "dashboard.widgetOrder"
    private static let hiddenKey = "dashboard.hiddenWidgets"

    var widgetOrder: [String]
    var hiddenWidgets: Set<String>

    var visibleWidgets: [String] {
        widgetOrder.filter { !hiddenWidgets.contains($0) }
    }

    init() {
        if let saved = UserDefaults.standard.stringArray(forKey: Self.orderKey) {
            widgetOrder = saved
        } else {
            widgetOrder = defaultWidgetOrder
        }

        if let saved = UserDefaults.standard.stringArray(forKey: Self.hiddenKey) {
            hiddenWidgets = Set(saved)
        } else {
            hiddenWidgets = defaultHiddenWidgets
        }
    }

    func save() {
        UserDefaults.standard.set(widgetOrder, forKey: Self.orderKey)
        UserDefaults.standard.set(Array(hiddenWidgets), forKey: Self.hiddenKey)
    }

    func moveWidget(from source: IndexSet, to destination: Int) {
        var visible = visibleWidgets
        visible.move(fromOffsets: source, toOffset: destination)
        // Rebuild order preserving hidden widget positions
        var newOrder: [String] = []
        var visibleIndex = 0
        for id in widgetOrder {
            if hiddenWidgets.contains(id) {
                newOrder.append(id)
            } else if visibleIndex < visible.count {
                newOrder.append(visible[visibleIndex])
                visibleIndex += 1
            }
        }
        // Append any remaining visible items (shouldn't happen but be safe)
        while visibleIndex < visible.count {
            newOrder.append(visible[visibleIndex])
            visibleIndex += 1
        }
        widgetOrder = newOrder
        save()
    }

    func removeWidget(_ id: String) {
        hiddenWidgets.insert(id)
        save()
    }

    func addWidget(_ id: String) {
        hiddenWidgets.remove(id)
        if !widgetOrder.contains(id) {
            widgetOrder.append(id)
        }
        save()
    }

    func resetToDefaults() {
        widgetOrder = defaultWidgetOrder
        hiddenWidgets = defaultHiddenWidgets
        save()
    }
}
