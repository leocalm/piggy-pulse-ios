import SwiftUI

struct AccountsStepView: View {
    @ObservedObject var vm: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeManager) private var theme

    private let accountTypes = ["checking", "savings", "wallet"]
    private let typeLabels: [String: String] = [
        "checking": "checking",
        "savings": "savings",
        "wallet": "wallet"
    ]

    private var currencySymbol: String {
        vm.selectedCurrency?.symbol ?? "$"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                // Title
                Text(String(localized: "accounts.title"))
                    .font(.ppTitle3).fontWeight(.bold).foregroundColor(.ppTextPrimary)

                // Descriptions
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text(String(localized: "accounts.description1"))
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                    Text(String(localized: "accounts.description2"))
                        .font(.ppBody).foregroundColor(.ppTextSecondary)
                }

                // Account cards
                if !vm.accounts.isEmpty {
                    VStack(alignment: .leading, spacing: PPSpacing.md) {
                        ForEach($vm.accounts) { $account in
                            AccountCardView(
                                account: $account,
                                typeLabels: typeLabels,
                                accountTypes: accountTypes,
                                currencySymbol: currencySymbol,
                                onRemove: { vm.accounts.removeAll { $0.id == account.id } }
                            )
                        }
                    }
                }

                // Add account button
                if vm.accounts.count < 10 {
                    Button {
                        vm.accounts.append(DraftAccount())
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill").foregroundColor(theme.primary)
                            Text(String(localized: "button.addAccount"))
                                .font(.ppCallout).foregroundColor(theme.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(PPSpacing.md)
                        .background(theme.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                    }
                }
            }
            .padding(PPSpacing.xl)
        }
    }
}

// MARK: - Account card

private struct AccountCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeManager) private var theme
    @Binding var account: DraftAccount
    let typeLabels: [String: String]
    let accountTypes: [String]
    let currencySymbol: String
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

            TextField(String(localized: "field.accountName"), text: $account.name)
                .font(.ppBody).foregroundColor(.ppTextPrimary)
                .padding(.horizontal, PPSpacing.md).padding(.vertical, PPSpacing.sm)
                .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.sm).stroke(Color.ppBorder, lineWidth: 1))

            HStack {
                Text(String(localized: "field.type")).font(.ppCallout).foregroundColor(.ppTextSecondary)
                Spacer()
                Picker("Type", selection: $account.accountType) {
                    ForEach(accountTypes, id: \.self) { t in
                        Text(typeLabels[t] ?? t).tag(t)
                    }
                }
                .pickerStyle(.menu).tint(theme.primary)
            }

            HStack {
                Text(String(localized: "field.startingBalance")).font(.ppCallout).foregroundColor(.ppTextSecondary)
                Spacer()
                Text(currencySymbol)
                    .font(.ppCallout).foregroundColor(.ppTextTertiary)
                TextField("0.00", text: $account.balanceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                    .frame(width: 110)
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }
}
