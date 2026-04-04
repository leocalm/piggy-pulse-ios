import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct NetPositionEntry: TimelineEntry {
    let date: Date
    let total: Int64?
    let difference: Int64?
    let liquid: Int64?
    let protected: Int64?
    let debt: Int64?
    let accountCount: Int?
    let isPlaceholder: Bool

    static let placeholder = NetPositionEntry(
        date: .now, total: 675_333, difference: 352_732,
        liquid: 42_033, protected: 696_000, debt: 66_700,
        accountCount: 4, isPlaceholder: true
    )

    static let empty = NetPositionEntry(
        date: .now, total: nil, difference: nil,
        liquid: nil, protected: nil, debt: nil,
        accountCount: nil, isPlaceholder: false
    )
}

// MARK: - Timeline Provider

struct NetPositionProvider: TimelineProvider {

    func placeholder(in context: Context) -> NetPositionEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (NetPositionEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        Task {
            completion(await fetchEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NetPositionEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    private func fetchEntry() async -> NetPositionEntry {
        do {
            let periodId = try await WidgetAPIClient.fetchActivePeriodId()
            let data = try await WidgetAPIClient.fetchNetPosition(periodId: periodId)
            return NetPositionEntry(
                date: .now, total: data.total, difference: data.differenceThisPeriod,
                liquid: data.liquidAmount, protected: data.protectedAmount, debt: data.debtAmount,
                accountCount: data.numberOfAccounts, isPlaceholder: false
            )
        } catch {
            return .empty
        }
    }
}

// MARK: - Widget Definition

struct NetPositionWidget: Widget {
    let kind = "NetPositionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NetPositionProvider()) { entry in
            NetPositionWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(String(localized: "Net Position"))
        .description(String(localized: "Shows your total net position and breakdown."))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .systemExtraLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

// MARK: - Widget View

struct NetPositionWidgetView: View {
    let entry: NetPositionEntry

    @Environment(\.widgetFamily) var family

    private var accent: Color { WidgetTheme.current.primary }

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        case .accessoryCircular:
            lockCircularView
        case .accessoryRectangular:
            lockRectangularView
        case .accessoryInline:
            lockInlineView
        default:
            smallView
        }
    }

    // MARK: - System Small

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(String(localized: "Net Position"), systemImage: "banknote")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let total = entry.total {
                Text(WidgetCurrencyFormatter.format(total, compact: true))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(accent)
                    .minimumScaleFactor(0.6)

                if let diff = entry.difference {
                    let sign = diff >= 0 ? "+" : ""
                    Text("\(sign)\(WidgetCurrencyFormatter.format(diff, compact: true))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                signInPrompt
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }

    // MARK: - System Medium

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left: total + change
            VStack(alignment: .leading, spacing: 6) {
                Label(String(localized: "Net Position"), systemImage: "banknote")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let total = entry.total {
                    Text(WidgetCurrencyFormatter.format(total))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(accent)
                        .minimumScaleFactor(0.6)

                    if let diff = entry.difference {
                        let isPositive = diff >= 0
                        HStack(spacing: 2) {
                            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2)
                            Text(WidgetCurrencyFormatter.format(diff, compact: true))
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                } else {
                    signInPrompt
                }

                Spacer(minLength: 0)
            }

            // Right: breakdown
            if entry.total != nil {
                VStack(alignment: .leading, spacing: 8) {
                    breakdownRow(icon: "drop.fill", label: String(localized: "Liquid"), amount: entry.liquid)
                    breakdownRow(icon: "lock.fill", label: String(localized: "Protected"), amount: entry.protected)
                    breakdownRow(icon: "creditcard.fill", label: String(localized: "Debt"), amount: entry.debt)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }

    // MARK: - System Large

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Net Position"), systemImage: "banknote")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let total = entry.total {
                Text(WidgetCurrencyFormatter.format(total))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(accent)
                    .minimumScaleFactor(0.5)

                if let diff = entry.difference {
                    let isPositive = diff >= 0
                    HStack(spacing: 4) {
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        Text("\(WidgetCurrencyFormatter.format(diff, compact: true)) this period")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }

                Divider()

                // Breakdown
                VStack(spacing: 12) {
                    largeBreakdownRow(icon: "drop.fill", label: String(localized: "Liquid"), amount: entry.liquid)
                    largeBreakdownRow(icon: "lock.fill", label: String(localized: "Protected"), amount: entry.protected)
                    largeBreakdownRow(icon: "creditcard.fill", label: String(localized: "Debt"), amount: entry.debt)
                }

                Spacer(minLength: 0)

                if let count = entry.accountCount {
                    HStack {
                        Image(systemName: "building.columns")
                        Text(String(localized: "\(count) accounts"))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else {
                signInPrompt
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }

    // MARK: - Lock Screen

    private var lockCircularView: some View {
        VStack(spacing: 1) {
            Image(systemName: "banknote")
                .font(.caption2)
            if let total = entry.total {
                Text(WidgetCurrencyFormatter.formatCompact(total))
                    .font(.system(size: 12, weight: .bold))
                    .minimumScaleFactor(0.5)
            } else {
                Text("--")
                    .font(.caption)
            }
        }
    }

    private var lockRectangularView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Net Position"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let total = entry.total {
                    Text(WidgetCurrencyFormatter.format(total, compact: true))
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

    private var lockInlineView: some View {
        Group {
            if let total = entry.total {
                Text("Net: \(WidgetCurrencyFormatter.formatCompact(total))")
            } else {
                Text(String(localized: "Net Position: --"))
            }
        }
    }

    // MARK: - Helpers

    private func breakdownRow(icon: String, label: String, amount: Int64?) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 12)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(amount.map { WidgetCurrencyFormatter.format($0, compact: true) } ?? "--")
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    private func largeBreakdownRow(icon: String, label: String, amount: Int64?) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(amount.map { WidgetCurrencyFormatter.format($0, compact: true) } ?? "--")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    private var signInPrompt: some View {
        VStack(spacing: 4) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(String(localized: "Open PiggyPulse to sign in"))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
