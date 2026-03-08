import SwiftUI

struct SummaryStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                Text("You're all set — here's what will be configured when you enter PiggyPulse.")
                    .font(.ppBody).foregroundColor(.ppTextPrimary)

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
                            .font(.ppCallout).foregroundColor(.ppTextSecondary)
                    }
                }

                // Accounts summary
                summarySection(title: "Accounts") {
                    if let currencyId = vm.selectedCurrencyId,
                       let currency = vm.currencies.first(where: { $0.id == currencyId }) {
                        labeledRow("Currency", "\(currency.symbol) \(currency.code)")
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
                        Text("Incoming").font(.ppCaption).fontWeight(.semibold).foregroundColor(.ppSuccess)
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
            .padding(PPSpacing.xl)
        }
    }

    @ViewBuilder
    private func summarySection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.md) {
            Text(title).font(.ppTitle3).foregroundColor(.ppTextPrimary)
            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                content()
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func labeledRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.ppCallout).foregroundColor(.ppTextSecondary)
            Spacer()
            Text(value).font(.ppCallout).foregroundColor(.ppTextPrimary)
        }
    }
}
