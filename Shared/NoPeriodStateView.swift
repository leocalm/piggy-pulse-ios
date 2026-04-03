import SwiftUI

/// Displayed when no budget period is selected.
/// Shows a clear visual indicator with a calendar icon and a button to open the period picker.
struct NoPeriodStateView: View {
    let pageTitle: String
    var showTitle: Bool = true

    @Environment(\.themeManager) private var theme
    @EnvironmentObject private var appState: AppState
    @State private var showPeriodPicker = false
    @State private var periods: [BudgetPeriod] = []

    var body: some View {
        VStack(spacing: PPSpacing.xl) {
            if showTitle {
                HStack {
                    Text(pageTitle)
                        .font(.ppLargeTitle)
                        .foregroundColor(.ppTextPrimary)
                    Spacer()
                }
            }

            VStack(spacing: PPSpacing.lg) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, PPSpacing.sm)

                Text(String(localized: "noPeriod.title"))
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)
                    .multilineTextAlignment(.center)

                Text(String(localized: "noPeriod.description"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)

                Button {
                    showPeriodPicker = true
                } label: {
                    Label(String(localized: "noPeriod.selectPeriod"), systemImage: "calendar")
                        .font(.ppHeadline)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.primary)
            }
            .padding(.vertical, PPSpacing.xxxl)
            .frame(maxWidth: .infinity)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.lg)
                    .stroke(Color.ppBorder, lineWidth: 1)
            )

            Spacer()
        }
        .padding(PPSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ppBackground)
        .task {
            let repo = PeriodRepository(apiClient: appState.apiClient)
            periods = (try? await repo.fetchPeriods()) ?? []
        }
        .sheet(isPresented: $showPeriodPicker) {
            PeriodPickerSheet(
                periods: periods,
                selectedPeriod: nil,
                onSelect: { period in
                    appState.selectedPeriod = period
                    showPeriodPicker = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}
