import SwiftUI

/// Displayed when no budget period is selected.
/// Shows a clear visual indicator with a calendar icon and a button to navigate to Periods.
struct NoPeriodStateView: View {
    let pageTitle: String
    var showTitle: Bool = true
    /// Called when the user taps "Go to Periods". The parent is responsible for navigation.
    var onGoToPeriods: (() -> Void)?

    @Environment(\.themeManager) private var theme

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

                if let onGoToPeriods {
                    Button {
                        onGoToPeriods()
                    } label: {
                        Label(String(localized: "noPeriod.goToPeriods"), systemImage: "calendar")
                            .font(.ppHeadline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.primary)
                }
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
    }
}
