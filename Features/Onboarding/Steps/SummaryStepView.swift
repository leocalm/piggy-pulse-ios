import SwiftUI

struct SummaryStepView: View {
    @ObservedObject var vm: OnboardingViewModel
@Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                Text("You're all set — here's what will be configured when you enter PiggyPulse.")
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                    .padding(.horizontal, PPSpacing.xl)

                // Period summary
                summarySection(title: "Period") {
                    if vm.customize {
                        labeledRow("Start Day", "\(vm.startDay)")
                        labeledRow("Period Length", vm.periodLength == 1 ? String(localized: "1 month") : String(localized: "\(vm.periodLength) months"))
                        labeledRow("Periods to Prepare", "\(vm.periodsToPrepare)")
                        labeledRow("If Saturday", vm.saturdayBehavior.label)
                        labeledRow("If Sunday", vm.sundayBehavior.label)
                    } else {
                        Text("Monthly, starting on the 1st (default)")
                            .font(.ppCallout).foregroundColor(.ppTextSecondary)
                    }
                }

                // Accounts summary
                summarySection(title: "Accounts") {
                    if let currencyId = vm.selectedCurrencyId,
                       let currency = vm.currencies.first(where: { $0.id == currencyId }) {
                        labeledRow("Currency", "\(currency.symbol) \(currency.currency)")
                    }
                    ForEach(vm.accounts) { account in
                        HStack {
                            Text(account.defaultIcon)
                            Text(account.name.isEmpty ? "Unnamed" : account.name)
                                .font(.ppCallout).foregroundColor(.ppTextPrimary)
                            Spacer()
                            Text(account.balanceText.isEmpty ? "0.00" : account.balanceText)
                                .font(.ppCallout).foregroundColor(.ppTextSecondary)
                        }
                    }
                }

                // Categories summary
                summarySection(title: "Categories") {
                    let incoming = vm.categories.filter { $0.categoryType == "Incoming" }
                    let outgoing = vm.categories.filter { $0.categoryType == "Outgoing" }
                    if !incoming.isEmpty {
                        Text("Incoming").font(.ppCaption).fontWeight(.semibold).foregroundColor(.ppTeal)
                        ForEach(incoming) { cat in
                            HStack { Text(cat.icon); Text(cat.name).font(.ppCallout).foregroundColor(.ppTextPrimary) }
                        }
                    }
                    if !outgoing.isEmpty {
                        Text("Outgoing").font(.ppCaption).fontWeight(.semibold).foregroundColor(.ppDestructive)
                            .padding(.top, 4)
                        ForEach(outgoing) { cat in
                            HStack { Text(cat.icon); Text(cat.name).font(.ppCallout).foregroundColor(.ppTextPrimary) }
                        }
                    }
                }
            }
            .padding(.vertical, PPSpacing.xl)
        }
    }

    @ViewBuilder
    private func summarySection<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.md) {
            Text(title).font(.ppTitle3).foregroundColor(.ppTextPrimary)
            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                content()
            }
        }
        .padding(PPSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppCard)
        .overlay(
            VStack {
                Divider().background(Color.ppBorder)
                Spacer()
                Divider().background(Color.ppBorder)
            }
        )
    }

    private func labeledRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(label).font(.ppCallout).foregroundColor(.ppTextSecondary)
            Spacer()
            Text(value).font(.ppCallout).foregroundColor(.ppTextPrimary)
        }
    }
}
