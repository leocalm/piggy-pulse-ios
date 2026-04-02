import SwiftUI

struct PeriodStepView: View {
    @ObservedObject var vm: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeManager) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                // Title
                Text(String(localized: "periods.title"))
                    .font(.ppTitle3).fontWeight(.bold).foregroundColor(.ppTextPrimary)

                // Descriptions
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text(String(localized: "periods.description1"))
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                    Text(String(localized: "periods.description2"))
                        .font(.ppBody).foregroundColor(.ppTextSecondary)
                }

                // Default config box
                VStack(alignment: .leading, spacing: PPSpacing.md) {
                    Text(String(localized: "periods.defaultLabel"))
                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextSecondary)

                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        HStack(spacing: PPSpacing.sm) {
                            Image(systemName: "calendar")
                                .foregroundColor(theme.primary)
                                .font(.ppCallout)
                            Text(String(localized: "periods.defaultMonthly"))
                                .font(.ppCallout).foregroundColor(.ppTextPrimary)
                        }
                        HStack(spacing: PPSpacing.sm) {
                            Image(systemName: "clock")
                                .foregroundColor(theme.primary)
                                .font(.ppCallout)
                            Text(String(localized: "periods.defaultAhead"))
                                .font(.ppCallout).foregroundColor(.ppTextPrimary)
                        }
                    }
                    .padding(PPSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(theme.primary.opacity(0.2), lineWidth: 1))
                }

                // Hint
                HStack(alignment: .top, spacing: PPSpacing.sm) {
                    Image(systemName: "info.circle").foregroundColor(.ppTextTertiary).font(.ppCaption)
                    Text(String(localized: "periods.changeHint"))
                        .font(.ppCaption).foregroundColor(.ppTextTertiary)
                }
                .padding(PPSpacing.md)
                .background(Color.ppSurface)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
            }
            .padding(PPSpacing.xl)
        }
    }
}
