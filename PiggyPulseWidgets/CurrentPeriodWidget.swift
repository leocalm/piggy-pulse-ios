import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct CurrentPeriodEntry: TimelineEntry {
    let date: Date
    let spent: Int64?
    let target: Int64?
    let daysRemaining: Int?
    let daysInPeriod: Int?
    let projectedSpend: Int64?
    let isPlaceholder: Bool

    var spendProgress: Double {
        guard let spent = spent, let target = target, target > 0 else { return 0 }
        return min(Double(spent) / Double(target), 1.0)
    }

    var timeProgress: Double {
        guard let remaining = daysRemaining, let total = daysInPeriod, total > 0 else { return 0 }
        return min(max(Double(total - remaining) / Double(total), 0), 1.0)
    }

    static let placeholder = CurrentPeriodEntry(
        date: .now, spent: 417_268, target: 305_787,
        daysRemaining: 8, daysInPeriod: 30, projectedSpend: 513_560,
        isPlaceholder: true
    )

    static let empty = CurrentPeriodEntry(
        date: .now, spent: nil, target: nil,
        daysRemaining: nil, daysInPeriod: nil, projectedSpend: nil,
        isPlaceholder: false
    )
}

// MARK: - Timeline Provider

struct CurrentPeriodProvider: TimelineProvider {

    func placeholder(in context: Context) -> CurrentPeriodEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (CurrentPeriodEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        Task {
            completion(await fetchEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CurrentPeriodEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    private func fetchEntry() async -> CurrentPeriodEntry {
        do {
            let periodId = try await WidgetAPIClient.fetchActivePeriodId()
            let data = try await WidgetAPIClient.fetchCurrentPeriod(periodId: periodId)
            return CurrentPeriodEntry(
                date: .now, spent: data.spent, target: data.target,
                daysRemaining: data.daysRemaining, daysInPeriod: data.daysInPeriod,
                projectedSpend: data.projectedSpend, isPlaceholder: false
            )
        } catch {
            return .empty
        }
    }
}

// MARK: - Widget Definition

struct CurrentPeriodWidget: Widget {
    let kind = "CurrentPeriodWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CurrentPeriodProvider()) { entry in
            CurrentPeriodWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(String(localized: "Budget Period"))
        .description(String(localized: "Shows spending progress for your current budget period."))
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

struct CurrentPeriodWidgetView: View {
    let entry: CurrentPeriodEntry

    @Environment(\.widgetFamily) var family

    private let accent = Color(red: 139.0/255, green: 126.0/255, blue: 200.0/255)

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
            Label(String(localized: "Budget"), systemImage: "chart.pie")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let spent = entry.spent, let target = entry.target {
                Text(WidgetCurrencyFormatter.format(spent, compact: true))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(accent)
                    .minimumScaleFactor(0.6)

                Text(String(localized: "of \(WidgetCurrencyFormatter.format(target, compact: true))"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.quaternary)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(accent)
                            .frame(width: geo.size.width * entry.spendProgress)
                    }
                }
                .frame(height: 6)

                if let days = entry.daysRemaining {
                    Text(String(localized: "\(max(days, 0)) days left"))
                        .font(.caption2)
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

    // MARK: - System Medium

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left: circular progress
            if let spent = entry.spent, let target = entry.target {
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: entry.spendProgress)
                        .stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(entry.spendProgress * 100))%")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .frame(width: 70, height: 70)

                // Right: details
                VStack(alignment: .leading, spacing: 6) {
                    Label(String(localized: "Budget Period"), systemImage: "chart.pie")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(WidgetCurrencyFormatter.format(spent, compact: true))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(accent)

                    Text(String(localized: "of \(WidgetCurrencyFormatter.format(target, compact: true))"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let days = entry.daysRemaining {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(String(localized: "\(max(days, 0)) days remaining"))
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                signInPrompt
                    .frame(maxWidth: .infinity)
            }
        }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }

    // MARK: - System Large

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Budget Period"), systemImage: "chart.pie")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let spent = entry.spent, let target = entry.target {
                // Spent + target
                HStack(alignment: .firstTextBaseline) {
                    Text(WidgetCurrencyFormatter.format(spent))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(accent)
                        .minimumScaleFactor(0.5)
                }

                Text(String(localized: "of \(WidgetCurrencyFormatter.format(target))"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Spend progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(accent)
                            .frame(width: geo.size.width * entry.spendProgress)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text(String(localized: "\(Int(entry.spendProgress * 100))% spent"))
                        .font(.caption)
                    Spacer()
                    Text(String(localized: "\(Int(entry.timeProgress * 100))% elapsed"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Stats grid
                HStack(spacing: 16) {
                    statBox(
                        icon: "calendar",
                        label: String(localized: "Days Left"),
                        value: entry.daysRemaining.map { "\(max($0, 0))" } ?? "--"
                    )
                    statBox(
                        icon: "chart.line.uptrend.xyaxis",
                        label: String(localized: "Projected"),
                        value: entry.projectedSpend.map { WidgetCurrencyFormatter.format($0, compact: true) } ?? "--"
                    )
                }

                Spacer(minLength: 0)
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
        Group {
            if let days = entry.daysRemaining, let total = entry.daysInPeriod, total > 0 {
                Gauge(value: min(max(entry.timeProgress, 0), 1)) {
                    Text("\(max(days, 0))")
                        .font(.system(size: 16, weight: .bold))
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(accent)
            } else {
                VStack(spacing: 1) {
                    Image(systemName: "chart.pie")
                        .font(.caption2)
                    Text("--")
                        .font(.caption)
                }
            }
        }
    }

    private var lockRectangularView: some View {
        Group {
            if let spent = entry.spent, let target = entry.target {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(String(localized: "Budget"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let days = entry.daysRemaining {
                            Text(String(localized: "\(max(days, 0))d left"))
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                    }

                    Gauge(value: entry.spendProgress) {
                        EmptyView()
                    }
                    .gaugeStyle(.accessoryLinearCapacity)
                    .tint(accent)

                    HStack {
                        Text(WidgetCurrencyFormatter.formatCompact(spent))
                            .font(.caption2)
                            .fontWeight(.medium)
                        Spacer()
                        Text(WidgetCurrencyFormatter.formatCompact(target))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Budget"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("--")
                            .font(.headline)
                    }
                    Spacer()
                }
            }
        }
    }

    private var lockInlineView: some View {
        Group {
            if let days = entry.daysRemaining {
                Text(String(localized: "\(max(days, 0)) days remaining"))
            } else {
                Text(String(localized: "Budget: --"))
            }
        }
    }

    // MARK: - Helpers

    private func statBox(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
