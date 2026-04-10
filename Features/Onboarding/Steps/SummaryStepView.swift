import SwiftUI

struct SummaryStepView: View {
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
                    .frame(maxWidth: 180)
                    .padding(.top, PPSpacing.xl)

                // Title + subtitle
                VStack(spacing: PPSpacing.sm) {
                    Text(String(localized: "complete.title"))
                        .font(.ppTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.ppTextPrimary)
                        .accessibilityIdentifier("onboarding-summary-title")

                    Text(String(localized: "complete.subtitle"))
                        .font(.ppBody)
                        .foregroundColor(.ppTextSecondary)
                        .multilineTextAlignment(.center)
                }

                // Summary sections
                VStack(spacing: PPSpacing.md) {

                    // Currency
                    summarySection(title: String(localized: "currency.title")) {
                        if let currency = vm.selectedCurrency {
                            HStack {
                                Text(currency.symbol).font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currency.name).font(.ppCallout).foregroundColor(.ppTextPrimary)
                                    Text(currency.code).font(.ppCaption).foregroundColor(.ppTextSecondary)
                                }
                            }
                        } else {
                            Text(String(localized: "summary.noCurrency"))
                                .font(.ppCallout).foregroundColor(.ppTextTertiary)
                        }
                    }

                    // Periods
                    summarySection(title: String(localized: "periods.title")) {
                        HStack(spacing: PPSpacing.sm) {
                            Image(systemName: "calendar").foregroundColor(theme.primary)
                            Text(String(localized: "periods.defaultMonthly"))
                                .font(.ppCallout).foregroundColor(.ppTextPrimary)
                        }
                        HStack(spacing: PPSpacing.sm) {
                            Image(systemName: "clock").foregroundColor(theme.primary)
                            Text(String(localized: "periods.defaultAhead"))
                                .font(.ppCallout).foregroundColor(.ppTextPrimary)
                        }
                    }

                    // Accounts (if any)
                    if !vm.accounts.isEmpty {
                        summarySection(title: String(localized: "accounts.title")) {
                            ForEach(vm.accounts) { account in
                                HStack {
                                    Text(account.defaultIcon)
                                    Text(account.name.isEmpty ? "Unnamed" : account.name)
                                        .font(.ppCallout).foregroundColor(.ppTextPrimary)
                                    Spacer()
                                    Text(vm.selectedCurrency?.symbol ?? "")
                                        .font(.ppCaption).foregroundColor(.ppTextTertiary)
                                    Text(account.balanceText.isEmpty ? "0.00" : account.balanceText)
                                        .font(.ppCallout).foregroundColor(.ppTextSecondary)
                                }
                            }
                        }
                    }

                    // Categories (if any)
                    if !vm.createdCategories.isEmpty {
                        let incoming = vm.createdCategories.filter { $0.type == "income" }
                        let outgoing = vm.createdCategories.filter { $0.type == "expense" }

                        summarySection(title: String(localized: "categories.title")) {
                            if !incoming.isEmpty {
                                Text(String(localized: "category.incoming"))
                                    .font(.ppCaption).fontWeight(.semibold).foregroundColor(.ppTextTertiary)
                                ForEach(incoming) { cat in
                                    HStack(spacing: PPSpacing.sm) {
                                        Text(cat.icon)
                                        Text(cat.name).font(.ppCallout).foregroundColor(.ppTextPrimary)
                                    }
                                }
                            }
                            if !outgoing.isEmpty {
                                Text(String(localized: "category.outgoing"))
                                    .font(.ppCaption).fontWeight(.semibold).foregroundColor(.ppTextTertiary)
                                    .padding(.top, PPSpacing.xs)
                                ForEach(outgoing) { cat in
                                    HStack(spacing: PPSpacing.sm) {
                                        Text(cat.icon)
                                        Text(cat.name).font(.ppCallout).foregroundColor(.ppTextPrimary)
                                    }
                                }
                            }
                        }
                    }
                }

                // CTA buttons
                VStack(spacing: PPSpacing.md) {
                    Button {
                        Task { await vm.advance() }
                    } label: {
                        if vm.isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text(String(localized: "complete.goToDashboard"))
                                .font(.ppCallout).fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PPSpacing.md)
                    .background(theme.primary)
                    .clipShape(Capsule())
                    .disabled(vm.isSaving)
                    .accessibilityIdentifier("onboarding-go-to-dashboard")

                }

                Spacer(minLength: PPSpacing.xl)
            }
            .padding(.horizontal, PPSpacing.xl)
        }
    }

    @ViewBuilder
    private func summarySection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            Text(title)
                .font(.ppCaption).fontWeight(.semibold).foregroundColor(.ppTextTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                content()
            }
            .padding(PPSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
