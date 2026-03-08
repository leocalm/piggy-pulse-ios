import SwiftUI

struct PeriodSelectorBar: View {
    @EnvironmentObject var appState: AppState
    @State private var periods: [BudgetPeriod] = []
    @State private var showPicker = false
    @State private var isLoading = true
    @Environment(\.tabViewBottomAccessoryPlacement) var placement

    var body: some View {
        HStack(spacing: 0) {
            Button {
                showPicker = true
            } label: {
                HStack(spacing: PPSpacing.md) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.white)

                    if isLoading {
                        ProgressView()
                            .tint(.ppTextSecondary)
                            .scaleEffect(0.8)
                    } else if let period = appState.selectedPeriod {
                        Text(period.name)
                            .font(.ppCallout)
                            .fontWeight(.semibold)
                            .foregroundColor(.ppTextPrimary)

                        switch placement {
                        case .inline:
                            Text(period.statusText)
                                .font(.ppCaption)
                                .foregroundColor(statusColor(period.status))
                        case .expanded:
                            HStack(spacing: 4) {
                                Text(period.dateRangeText)
                                    .font(.ppCaption)
                                    .foregroundColor(.ppTextSecondary)

                                if !period.statusText.isEmpty {
                                    Text("·")
                                        .font(.ppCaption)
                                        .foregroundColor(.ppTextTertiary)
                                    Text(period.statusText)
                                        .font(.ppCaption)
                                        .foregroundColor(statusColor(period.status))
                                }
                            }
                        default:
                            Text("No period selected")
                                .font(.ppCallout)
                                .foregroundColor(.ppTextSecondary)
                        }
                    } else {
                        Text("No period selected")
                            .font(.ppCallout)
                            .foregroundColor(.ppTextSecondary)
                    }
                }
                .padding(.horizontal, PPSpacing.lg)
                .padding(.vertical, PPSpacing.md)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        }
        .sheet(isPresented: $showPicker) {
            PeriodPickerSheet(
                periods: periods,
                selectedPeriod: appState.selectedPeriod,
                onSelect: { period in
                    appState.selectedPeriod = period
                    showPicker = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .task(id: appState.isAuthenticated) {
            if appState.isAuthenticated {
                await loadPeriods()
            }
        }
    }

    private func loadPeriods() async {
        isLoading = true
        let repo = PeriodRepository(apiClient: appState.apiClient)
        do {
            let fetched = try await repo.fetchPeriods()
            periods = fetched

            if appState.selectedPeriod == nil {
                appState.selectedPeriod = fetched.first(where: { $0.status == .active })
                    ?? fetched.first
            }
        } catch {
            
        }
        isLoading = false
    }

    private func statusColor(_ status: PeriodStatus) -> Color {
        switch status {
        case .active: return .ppCyan
        case .ended: return .ppTextTertiary
        case .upcoming: return .ppAmber
        case .unknown: return .ppTextTertiary
        }
    }
}

// MARK: - Period Picker Sheet

struct PeriodPickerSheet: View {
    let periods: [BudgetPeriod]
    let selectedPeriod: BudgetPeriod?
    let onSelect: (BudgetPeriod) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: PPSpacing.sm) {
                    ForEach(periods) { period in
                        Button {
                            onSelect(period)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(period.name)
                                        .font(.ppHeadline)
                                        .foregroundColor(.ppTextPrimary)

                                    HStack(spacing: 4) {
                                        Text(period.dateRangeText)
                                            .font(.ppCaption)
                                            .foregroundColor(.ppTextSecondary)
                                        Text("·")
                                            .font(.ppCaption)
                                            .foregroundColor(.ppTextTertiary)
                                        Text(period.statusText)
                                            .font(.ppCaption)
                                            .foregroundColor(statusColor(period.status))
                                    }
                                }

                                Spacer()

                                if period.id == selectedPeriod?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.ppPrimary)
                                }
                            }
                            .padding(PPSpacing.lg)
                            .background(
                                period.id == selectedPeriod?.id
                                    ? Color.ppPrimary.opacity(0.1)
                                    : Color.ppCard
                            )
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: PPRadius.md)
                                    .stroke(
                                        period.id == selectedPeriod?.id
                                            ? Color.ppPrimary.opacity(0.3)
                                            : Color.ppBorder,
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
                .padding(PPSpacing.lg)
            }
            .background(Color.ppBackground)
            .navigationTitle("Select Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private func statusColor(_ status: PeriodStatus) -> Color {
        switch status {
        case .active: return .ppCyan
        case .ended: return .ppTextTertiary
        case .upcoming: return .ppAmber
        case .unknown: return .ppTextTertiary
        }
    }
}
