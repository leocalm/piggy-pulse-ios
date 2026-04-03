import WidgetKit
import SwiftUI

// MARK: - Net Position Complication

struct NetPositionEntry: TimelineEntry {
    let date: Date
    let total: Int64?
}

struct NetPositionProvider: TimelineProvider {

    func placeholder(in context: Context) -> NetPositionEntry {
        NetPositionEntry(date: .now, total: 1_250_000)
    }

    func getSnapshot(in context: Context, completion: @escaping (NetPositionEntry) -> Void) {
        if context.isPreview {
            completion(NetPositionEntry(date: .now, total: 1_250_000))
            return
        }

        Task {
            do {
                let position = try await WatchAPIClient.shared.fetchNetPosition()
                completion(NetPositionEntry(date: .now, total: position.total))
            } catch {
                completion(NetPositionEntry(date: .now, total: nil))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NetPositionEntry>) -> Void) {
        Task {
            do {
                let position = try await WatchAPIClient.shared.fetchNetPosition()
                let entry = NetPositionEntry(date: .now, total: position.total)
                let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                let entry = NetPositionEntry(date: .now, total: nil)
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }
}

struct NetPositionComplication: Widget {
    let kind = "NetPositionComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NetPositionProvider()) { entry in
            NetPositionComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(String(localized: "Net Position"))
        .description(String(localized: "Shows your total net position."))
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct NetPositionComplicationView: View {
    let entry: NetPositionEntry

    @Environment(\.widgetFamily) var family

    private let accentColor = Color(red: 139.0/255, green: 126.0/255, blue: 200.0/255)

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            Text("--")
        }
    }

    @ViewBuilder
    private var circularView: some View {
        VStack(spacing: 1) {
            Image(systemName: "banknote")
                .font(.caption2)
            if let total = entry.total {
                Text(WatchCurrencyFormatter.formatCompact(total))
                    .font(.system(size: 12, weight: .bold))
                    .minimumScaleFactor(0.6)
            } else {
                Text("--")
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var rectangularView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Net Position"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let total = entry.total {
                    Text(WatchCurrencyFormatter.format(total, compact: true))
                        .font(.headline)
                        .fontWeight(.bold)
                } else {
                    Text("--")
                        .font(.headline)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var inlineView: some View {
        if let total = entry.total {
            Text("Net: \(WatchCurrencyFormatter.formatCompact(total))")
        } else {
            Text(String(localized: "Net Position: --"))
        }
    }
}

// MARK: - Days Remaining Complication

struct DaysRemainingEntry: TimelineEntry {
    let date: Date
    let daysRemaining: Int?
    let daysInPeriod: Int?
}

struct DaysRemainingProvider: TimelineProvider {

    func placeholder(in context: Context) -> DaysRemainingEntry {
        DaysRemainingEntry(date: .now, daysRemaining: 12, daysInPeriod: 30)
    }

    func getSnapshot(in context: Context, completion: @escaping (DaysRemainingEntry) -> Void) {
        if context.isPreview {
            completion(DaysRemainingEntry(date: .now, daysRemaining: 12, daysInPeriod: 30))
            return
        }

        Task {
            do {
                let period = try await WatchAPIClient.shared.fetchCurrentPeriod()
                completion(DaysRemainingEntry(
                    date: .now,
                    daysRemaining: period.daysRemaining,
                    daysInPeriod: period.daysInPeriod
                ))
            } catch {
                completion(DaysRemainingEntry(date: .now, daysRemaining: nil, daysInPeriod: nil))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DaysRemainingEntry>) -> Void) {
        Task {
            do {
                let period = try await WatchAPIClient.shared.fetchCurrentPeriod()
                let entry = DaysRemainingEntry(
                    date: .now,
                    daysRemaining: period.daysRemaining,
                    daysInPeriod: period.daysInPeriod
                )
                // Update at midnight to reflect the new day
                let nextMidnight = Calendar.current.startOfDay(
                    for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
                )
                let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
                completion(timeline)
            } catch {
                let entry = DaysRemainingEntry(date: .now, daysRemaining: nil, daysInPeriod: nil)
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }
}

struct DaysRemainingComplication: Widget {
    let kind = "DaysRemainingComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DaysRemainingProvider()) { entry in
            DaysRemainingComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(String(localized: "Days Remaining"))
        .description(String(localized: "Shows days left in your current budget period."))
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct DaysRemainingComplicationView: View {
    let entry: DaysRemainingEntry

    @Environment(\.widgetFamily) var family

    private let accentColor = Color(red: 139.0/255, green: 126.0/255, blue: 200.0/255)

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            Text("--")
        }
    }

    @ViewBuilder
    private var circularView: some View {
        if let days = entry.daysRemaining, let total = entry.daysInPeriod {
            let progress = total > 0 ? Double(total - days) / Double(total) : 0

            Gauge(value: progress) {
                Text("\(days)")
                    .font(.system(size: 16, weight: .bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(accentColor)
        } else {
            VStack(spacing: 1) {
                Image(systemName: "calendar")
                    .font(.caption2)
                Text("--")
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var rectangularView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Period"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let days = entry.daysRemaining {
                    Text(String(localized: "\(days) days left"))
                        .font(.headline)
                        .fontWeight(.bold)
                } else {
                    Text("--")
                        .font(.headline)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var inlineView: some View {
        if let days = entry.daysRemaining {
            Text(String(localized: "\(days) days remaining"))
        } else {
            Text(String(localized: "Period: --"))
        }
    }
}

// MARK: - Widget Bundle

@main
struct PiggyPulseWatchWidgets: WidgetBundle {
    var body: some Widget {
        NetPositionComplication()
        DaysRemainingComplication()
    }
}
