import SwiftUI

struct AccountsStepView: View {
    @ObservedObject var vm: OnboardingViewModel
@Environment(\.colorScheme) private var colorScheme

    private let accountTypes = ["Checking", "Savings", "CreditCard", "Wallet", "Allowance"]
    private let typeLabels: [String: String] = [
        "Checking": "Checking", "Savings": "Savings",
        "CreditCard": "Credit Card", "Wallet": "Wallet", "Allowance": "Allowance"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                Text("Accounts are where your money goes.")
                    .font(.ppBody).foregroundColor(.ppTextPrimary)

                // Currency picker
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text("Currency")
                        .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                    if vm.currencies.isEmpty {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Picker("Currency", selection: $vm.selectedCurrencyId) {
                            ForEach(vm.currencies) { currency in
                                Text("\(currency.symbol) \(currency.currency) — \(currency.name)")
                                    .tag(Optional(currency.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.ppPrimary)
                        .padding(PPSpacing.md)
                        .background(Color.ppCard)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                    }
                }

                // Account cards
                VStack(alignment: .leading, spacing: PPSpacing.md) {
                    Text("Accounts")
                        .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                    ForEach($vm.accounts) { $account in
                        AccountCardView(
                            account: $account,
                            typeLabels: typeLabels,
                            accountTypes: accountTypes,
                            onRemove: { vm.accounts.removeAll { $0.id == account.id } }
                        )
                    }

                    if vm.accounts.count < 10 {
                        Button {
                            vm.accounts.append(DraftAccount())
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill").foregroundColor(.ppPrimary)
                                Text("Add Account").font(.ppCallout).foregroundColor(.ppPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(PPSpacing.md)
                            .background(Color.ppPrimary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        }
                    }
                }
            }
            .padding(PPSpacing.xl)
        }
        .task { await vm.loadCurrencies() }
    }
}

// MARK: - Account card

private struct AccountCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var account: DraftAccount
    let typeLabels: [String: String]
    let accountTypes: [String]
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.md) {
            HStack {
                Text(account.defaultIcon).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name.isEmpty ? "New Account" : account.name)
                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    Text(typeLabels[account.accountType] ?? account.accountType)
                        .font(.ppCaption).foregroundColor(.ppTextSecondary)
                }
                Spacer()
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.ppTextTertiary)
                }
            }

            Divider()

            TextField("Account name", text: $account.name)
                .font(.ppBody).foregroundColor(.ppTextPrimary)
                .padding(.horizontal, PPSpacing.md).padding(.vertical, PPSpacing.sm)
                .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.sm).stroke(Color.ppBorder, lineWidth: 1))

            HStack {
                Text("Type").font(.ppCallout).foregroundColor(.ppTextSecondary)
                Spacer()
                Picker("Type", selection: $account.accountType) {
                    ForEach(accountTypes, id: \.self) { t in
                        Text(typeLabels[t] ?? t).tag(t)
                    }
                }
                .pickerStyle(.menu).tint(.ppPrimary)
            }

            HStack {
                Text("Starting Balance").font(.ppCallout).foregroundColor(.ppTextSecondary)
                Spacer()
                TextField("0.00", text: $account.balanceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                    .frame(width: 120)
            }

            if account.showSpendLimit {
                HStack {
                    Text("Spend Limit").font(.ppCallout).foregroundColor(.ppTextSecondary)
                    Text("(optional)").font(.ppCaption).foregroundColor(.ppTextTertiary)
                    Spacer()
                    TextField("0.00", text: $account.spendLimitText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                        .frame(width: 120)
                }
                .animation(.easeInOut(duration: 0.15), value: account.showSpendLimit)
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }
}
