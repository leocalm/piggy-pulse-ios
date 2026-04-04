import SwiftUI
import WidgetKit

// MARK: - Helper to get active period

private func fetchActivePeriodId() async throws -> UUID {
    let periods = try await WatchAPIClient.shared.fetchPeriods()
    guard let id = periods.first(where: { $0.status == "active" })?.id ?? periods.first?.id else {
        throw WatchAPIError.notFound
    }
    return id
}

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
                let periodId = try await fetchActivePeriodId()
                let position = try await WatchAPIClient.shared.fetchNetPosition(periodId: periodId)
                completion(NetPositionEntry(date: .now, total: position.total))
            } catch {
                completion(NetPositionEntry(date: .now, total: nil))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NetPositionEntry>) -> Void) {
        Task {
            do {
                let periodId = try await fetchActivePeriodId()
                let position = try await WatchAPIClient.shared.fetchNetPosition(periodId: periodId)
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
            .accessoryInline,
            .accessoryCorner,
        ])
    }
}

struct NetPositionComplicationView: View {
    let entry: NetPositionEntry

    @Environment(\.widgetFamily) var family

    private let accentColor = WatchDesign.accentColor

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        case .accessoryCorner:
            cornerView
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

    @ViewBuilder
    private var cornerView: some View {
        if let total = entry.total {
            Text(WatchCurrencyFormatter.formatCompact(total))
                .font(.system(size: 16, weight: .bold))
                .minimumScaleFactor(0.5)
                .widgetLabel {
                    Text(String(localized: "Net Position"))
                }
        } else {
            Image(systemName: "banknote")
                .widgetLabel {
                    Text("--")
                }
        }
    }
}

// MARK: - Days Remaining Complication

struct DaysRemainingEntry: TimelineEntry {
    let date: Date
    let daysRemaining: Int?
    let daysInPeriod: Int?
    let spent: Int64?
    let target: Int64?
}

struct DaysRemainingProvider: TimelineProvider {

    func placeholder(in context: Context) -> DaysRemainingEntry {
        DaysRemainingEntry(date: .now, daysRemaining: 12, daysInPeriod: 30, spent: 250_000, target: 500_000)
    }

    func getSnapshot(in context: Context, completion: @escaping (DaysRemainingEntry) -> Void) {
        if context.isPreview {
            completion(DaysRemainingEntry(date: .now, daysRemaining: 12, daysInPeriod: 30, spent: 250_000, target: 500_000))
            return
        }

        Task {
            do {
                let periodId = try await fetchActivePeriodId()
                let period = try await WatchAPIClient.shared.fetchCurrentPeriod(periodId: periodId)
                completion(DaysRemainingEntry(
                    date: .now,
                    daysRemaining: period.daysRemaining,
                    daysInPeriod: period.daysInPeriod,
                    spent: period.spent,
                    target: period.target
                ))
            } catch {
                completion(DaysRemainingEntry(date: .now, daysRemaining: nil, daysInPeriod: nil, spent: nil, target: nil))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DaysRemainingEntry>) -> Void) {
        Task {
            do {
                let periodId = try await fetchActivePeriodId()
                let period = try await WatchAPIClient.shared.fetchCurrentPeriod(periodId: periodId)
                let entry = DaysRemainingEntry(
                    date: .now,
                    daysRemaining: period.daysRemaining,
                    daysInPeriod: period.daysInPeriod,
                    spent: period.spent,
                    target: period.target
                )
                let nextMidnight = Calendar.current.startOfDay(
                    for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
                )
                let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
                completion(timeline)
            } catch {
                let entry = DaysRemainingEntry(date: .now, daysRemaining: nil, daysInPeriod: nil, spent: nil, target: nil)
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
        .configurationDisplayName(String(localized: "Budget Period"))
        .description(String(localized: "Shows days left and spending progress."))
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner,
        ])
    }
}

struct DaysRemainingComplicationView: View {
    let entry: DaysRemainingEntry

    @Environment(\.widgetFamily) var family

    private let accentColor = WatchDesign.accentColor

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        case .accessoryCorner:
            cornerView
        default:
            Text("--")
        }
    }

    @ViewBuilder
    private var circularView: some View {
        if let days = entry.daysRemaining, let total = entry.daysInPeriod {
            let progress = total > 0 ? Double(total - days) / Double(total) : 0

            Gauge(value: min(max(progress, 0), 1)) {
                Text("\(max(days, 0))")
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
        if let days = entry.daysRemaining, let spent = entry.spent, let target = entry.target {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(String(localized: "Budget Period"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(localized: "\(max(days, 0))d left"))
                        .font(.caption2)
                        .fontWeight(.semibold)
                }

                // Spending progress bar
                let spendProgress = target > 0 ? min(Double(spent) / Double(target), 1.0) : 0
                Gauge(value: spendProgress) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(accentColor)

                HStack {
                    Text(WatchCurrencyFormatter.formatCompact(spent))
                        .font(.caption2)
                        .fontWeight(.medium)
                    Spacer()
                    Text(WatchCurrencyFormatter.formatCompact(target))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "Period"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("--")
                        .font(.headline)
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var inlineView: some View {
        if let days = entry.daysRemaining {
            Text(String(localized: "\(max(days, 0)) days remaining"))
        } else {
            Text(String(localized: "Period: --"))
        }
    }

    @ViewBuilder
    private var cornerView: some View {
        if let days = entry.daysRemaining, let total = entry.daysInPeriod {
            let progress = total > 0 ? min(max(Double(total - days) / Double(total), 0), 1) : 0

            Text("\(max(days, 0))")
                .font(.system(size: 20, weight: .bold))
                .minimumScaleFactor(0.5)
                .widgetLabel {
                    Gauge(value: progress) {
                        Text(String(localized: "days"))
                    }
                    .gaugeStyle(.accessoryLinearCapacity)
                    .tint(accentColor)
                }
        } else {
            Image(systemName: "calendar")
                .widgetLabel {
                    Text("--")
                }
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
