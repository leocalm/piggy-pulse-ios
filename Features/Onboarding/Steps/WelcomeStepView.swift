import SwiftUI

struct WelcomeStepView: View {
    @ObservedObject var vm: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeManager) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: PPSpacing.xl) {

                // Hero image
                Image("piggy-cloud")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                    .padding(.top, PPSpacing.xl)

                // Title + subtitle
                VStack(spacing: PPSpacing.sm) {
                    Text(String(localized: "welcome.title"))
                        .font(.ppTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.ppTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "welcome.subtitle"))
                        .font(.ppBody)
                        .foregroundColor(.ppTextSecondary)
                        .multilineTextAlignment(.center)
                }

                // Bullet points
                VStack(alignment: .leading, spacing: PPSpacing.md) {
                    bulletRow(
                        bold: String(localized: "welcome.noJudgment"),
                        text: String(localized: "welcome.noJudgmentDesc")
                    )
                    bulletRow(
                        bold: String(localized: "welcome.justClarity"),
                        text: String(localized: "welcome.justClarityDesc")
                    )
                    bulletRow(
                        bold: String(localized: "welcome.yourRules"),
                        text: String(localized: "welcome.yourRulesDesc")
                    )
                }
                .padding(PPSpacing.lg)
                .background(Color.ppCard)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                // Quote
                Text(String(localized: "welcome.quote"))
                    .font(.ppCallout.italic())
                    .foregroundColor(.ppTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PPSpacing.md)

                // CTA button
                Button {
                    Task { await vm.advance() }
                } label: {
                    if vm.isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text(String(localized: "welcome.getStarted"))
                            .font(.ppCallout).fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, PPSpacing.md)
                .background(theme.primary)
                .clipShape(Capsule())

                Spacer(minLength: PPSpacing.xl)
            }
            .padding(.horizontal, PPSpacing.xl)
        }
    }

    private func bulletRow(bold: String, text: String) -> some View {
        HStack(alignment: .top, spacing: PPSpacing.sm) {
            Circle()
                .fill(theme.primary)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            Group {
                Text(bold).fontWeight(.semibold) + Text(" — ") + Text(text)
            }
            .font(.ppCallout)
            .foregroundColor(.ppTextPrimary)
        }
    }
}
