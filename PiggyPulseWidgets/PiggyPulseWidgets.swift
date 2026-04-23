import SwiftUI
import WidgetKit

@main
struct PiggyPulseWidgets: WidgetBundle {
    var body: some Widget {
        DisabledWidget()
    }
}

struct DisabledWidget: Widget {
    let kind = "com.piggypulse.disabled"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DisabledProvider()) { _ in
            VStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Open PiggyPulse")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("PiggyPulse")
        .description("Widgets are temporarily unavailable while encryption is being set up.")
        .supportedFamilies([.systemSmall])
    }
}

struct DisabledEntry: TimelineEntry {
    let date: Date
}

struct DisabledProvider: TimelineProvider {
    func placeholder(in context: Context) -> DisabledEntry {
        DisabledEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (DisabledEntry) -> Void) {
        completion(DisabledEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DisabledEntry>) -> Void) {
        let entry = DisabledEntry(date: .now)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 24, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}
