import SwiftUI

struct SummaryStepView: View {
    @ObservedObject var vm: OnboardingViewModel
@Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                Text("You're all set — here's what will be configured when you enter PiggyPulse.")
                    .font(.ppBody).foregroundColor(.ppTextPrimary(colorScheme))
                    .padding(.horizontal, PPSpacing.xl)

                // Period summary
                summarySection(title: "Period") {
                    if vm.customize {
                        labeledRow("Start Day", "\(vm.startDay)")
                        labeledRow("Period Length", "\(vm.periodLength) month\(vm.periodLength == 1 ? "" : "s")")
                        labeledRow("Periods to Prepare", "\(vm.periodsToPrepare)")
                        labeledRow("If Saturday", vm.saturdayBehavior.label)
                        labeledRow("If Sunday", vm.sundayBehavior.label)
                    } else {
                        Text("Monthly, starting on the 1st (default)")
                            .font(.ppCallout).foregroundColor(.ppTextSecondary(colorScheme))
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
                                .font(.ppCallout).foregroundColor(.ppTextPrimary(colorScheme))
                            Spacer()
                            Text(account.balanceText.isEmpty ? "0.00" : account.balanceText)
                                .font(.ppCallout).foregroundColor(.ppTextSecondary(colorScheme))
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
                            HStack { Text(cat.icon); Text(cat.name).font(.ppCallout).foregroundColor(.ppTextPrimary(colorScheme)) }
                        }
                    }
                    if !outgoing.isEmpty {
                        Text("Outgoing").font(.ppCaption).fontWeight(.semibold).foregroundColor(.ppDestructive)
                            .padding(.top, 4)
                        ForEach(outgoing) { cat in
                            HStack { Text(cat.icon); Text(cat.name).font(.ppCallout).foregroundColor(.ppTextPrimary(colorScheme)) }
                        }
                    }
                }
            }
            .padding(.vertical, PPSpacing.xl)
        }
    }

    @ViewBuilder
    private func summarySection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.md) {
            Text(title).font(.ppTitle3).foregroundColor(.ppTextPrimary(colorScheme))
            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                content()
            }
        }
        .padding(PPSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppCard(colorScheme))
        .overlay(
            VStack {
                Divider().background(Color.ppBorder(colorScheme))
                Spacer()
                Divider().background(Color.ppBorder(colorScheme))
            }
        )
    }

    private func labeledRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.ppCallout).foregroundColor(.ppTextSecondary(colorScheme))
            Spacer()
            Text(value).font(.ppCallout).foregroundColor(.ppTextPrimary(colorScheme))
        }
    }
}
