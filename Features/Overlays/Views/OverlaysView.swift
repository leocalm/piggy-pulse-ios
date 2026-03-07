import SwiftUI

struct OverlaysView: View {
    @EnvironmentObject var appState: AppState
    @State private var overlays: [OverlayItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showPast = false

    private var active: [OverlayItem] { overlays.filter { $0.status == .active } }
    private var upcoming: [OverlayItem] { overlays.filter { $0.status == .upcoming } }
    private var past: [OverlayItem] { overlays.filter { $0.status == .ended } }

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    Section {
                        HStack { Spacer(); ProgressView().tint(.ppTextSecondary); Spacer() }
                            .padding(.vertical, PPSpacing.xxxl)
                            .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                    }
                } else if let error = errorMessage {
                    Section {
                        VStack(spacing: PPSpacing.md) {
                            Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundColor(.ppAmber)
                            Text(error).font(.ppBody).foregroundColor(.ppTextSecondary)
                            Button("Retry") { Task { await load() } }.font(.ppHeadline).foregroundColor(.ppPrimary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                    }
                } else if overlays.isEmpty {
                    Section {
                        VStack(spacing: PPSpacing.lg) {
                            Image(systemName: "square.stack").font(.system(size: 40)).foregroundColor(.ppTextTertiary)
                            Text("No overlays yet").font(.ppBody).foregroundColor(.ppTextSecondary)
                            Text("Create overlays from the web app to track temporary spending goals.").font(.ppCallout).foregroundColor(.ppTextTertiary).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                    }
                } else {
                    // Active
                    overlaySection("ACTIVE OVERLAYS", items: active, badge: true)
                    
                    // Upcoming
                    overlaySection("UPCOMING OVERLAYS", items: upcoming, badge: false)
                    
                    // Past
                    if !past.isEmpty {
                        Section {
                            if showPast {
                                ForEach(past) { overlay in
                                    overlayCard(overlay)
                                        .listRowBackground(Color.ppBackground)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                }
                            }
                        } header: {
                            Button {
                                withAnimation { showPast.toggle() }
                            } label: {
                                HStack {
                                    Text("PAST OVERLAYS").font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)
                                    Spacer()
                                    Text("\(past.count)").font(.ppCaption).foregroundColor(.ppTextSecondary)
                                        .padding(.horizontal, PPSpacing.sm).padding(.vertical, 2)
                                        .background(Color.ppCard).cornerRadius(PPRadius.full)
                                    Image(systemName: showPast ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12)).foregroundColor(.ppTextSecondary)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.ppBackground)
            .refreshable { await load() }
            .task { await load() }
            .navigationTitle("Overlays")
            .navigationBarTitleDisplayMode(.large)
            .navigationSubtitle("Temporary spending plans that run alongside your periods.")
        }
    }

    private func overlaySection(_ title: String, items: [OverlayItem], badge: Bool) -> some View {
        Group {
            if !items.isEmpty {
                Section {
                    ForEach(items) { overlay in
                        overlayCard(overlay)
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }
                } header: {
                    HStack {
                        Text(title).font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)
                        Spacer()
                        Text("\(items.count)").font(.ppCaption).foregroundColor(.white)
                            .padding(.horizontal, PPSpacing.sm).padding(.vertical, 2)
                            .background(badge ? Color.ppPrimary : Color.ppCard)
                            .cornerRadius(PPRadius.full)
                    }
                }
            }
        }
    }

    private func overlayCard(_ overlay: OverlayItem) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.md) {
            // Header
            HStack {
                if let icon = overlay.icon, !icon.isEmpty {
                    Text(icon).font(.system(size: 20))
                }
                Text(overlay.name)
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary)
                Spacer()

                // Status badges
                HStack(spacing: PPSpacing.xs) {
                    statusBadge(overlay.status)
                    Text(overlay.inclusionMode.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.ppTextSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.ppSurface)
                        .cornerRadius(PPRadius.sm)
                }
            }

            // Date range
            HStack(spacing: 4) {
                Image(systemName: "calendar").font(.system(size: 12)).foregroundColor(.ppTextTertiary)
                Text(formatDateRange(overlay.startDate, overlay.endDate))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)

                if overlay.status == .active {
                    Text("·").foregroundColor(.ppTextTertiary)
                    Text("\(overlay.daysRemaining) days left")
                        .font(.ppCaption)
                        .foregroundColor(.ppAmber)
                }
            }

            // Spending progress
            if let cap = overlay.totalCapAmount {
                HStack {
                    Text(formatCurrency(overlay.spentAmount, code: appState.currencyCode))
                        .font(.ppAmountSmall)
                        .foregroundColor(.ppTextPrimary)
                    Text("/ \(formatCurrency(cap, code: appState.currencyCode))")
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.ppBorder).frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(overlay.spentPercentage > 1.0 ? Color.ppDestructive : Color.ppCyan)
                            .frame(width: geo.size.width * min(overlay.spentPercentage, 1.0), height: 4)
                    }
                }
                .frame(height: 4)

                if let remaining = overlay.remainingAmount {
                    Text("\(formatCurrency(remaining)) remaining")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextTertiary)
                }
            }

            // Footer
            HStack {
                Text("\(overlay.transactionCount) transactions")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
                Spacer()
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .cornerRadius(PPRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func statusBadge(_ status: OverlayStatus) -> some View {
        Text(statusText(status))
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(statusColor(status))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor(status).opacity(0.15))
            .cornerRadius(PPRadius.sm)
    }

    private func statusText(_ status: OverlayStatus) -> String {
        switch status {
        case .active: return "ACTIVE"
        case .upcoming: return "UPCOMING"
        case .ended: return "ENDED"
        case .unknown: return ""
        }
    }

    private func statusColor(_ status: OverlayStatus) -> Color {
        switch status {
        case .active: return .ppCyan
        case .upcoming: return .ppAmber
        case .ended: return .ppTextTertiary
        case .unknown: return .ppTextTertiary
        }
    }

    private func formatDateRange(_ start: String, _ end: String) -> String {
        guard let s = DateFormatter.apiDate.date(from: start),
              let e = DateFormatter.apiDate.date(from: end) else { return "\(start) - \(end)" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let days = Calendar.current.dateComponents([.day], from: s, to: e).day ?? 0
        return "\(fmt.string(from: s)) - \(fmt.string(from: e)) · \(days) days"
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: [OverlayItem] = try await appState.apiClient.request(.overlays)
            overlays = response
        } catch {
            errorMessage = "Failed to load overlays."
        }
        isLoading = false
    }
}
