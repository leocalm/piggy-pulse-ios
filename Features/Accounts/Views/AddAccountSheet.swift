import SwiftUI

struct AddAccountSheet: View {
    @EnvironmentObject var appState: AppState
@Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme

    @State private var name = ""
    @State private var spendLimitText = ""
    @State private var color = "#007AFF"
    @State private var accountType = "checking"
    @State private var balanceText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var onCreated: () -> Void

    private let accountTypes = ["checking", "savings", "creditcard", "wallet", "allowance"]
    private var typeLabels: [String: String] {
        ["checking": String(localized: "Checking"), "savings": String(localized: "Savings"), "creditcard": String(localized: "Credit Card"), "wallet": String(localized: "Wallet"), "allowance": String(localized: "Allowance")]
    }
    private let colorOptions = ["#007AFF", "#00B894", "#E17055", "#0984E3", "#FDCB6E", "#E84393", "#00CEC9", "#636E72"]

    private var currencySymbol: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = appState.currencyCode
        return fmt.currencySymbol ?? appState.currencyCode
    }

    private var balanceInCents: Int64 {
        let cleaned = balanceText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned) else { return 0 }
        return Int64(value * 100)
    }

    private var isDisabled: Bool {
        name.trimmingCharacters(in: .whitespaces).count < 3 || isLoading
    }
    
    private var defaultIcon: String {
        switch accountType {
        case "checking": return "🏦"
        case "savings": return "💰"
        case "creditcard": return "💳"
        case "wallet": return "👛"
        case "allowance": return "🎯"
        default: return "🏦"
        }
    }

    private var showSpendLimit: Bool {
        accountType == "creditcard" || accountType == "allowance"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: PPSpacing.xl) {
                        if let error = errorMessage {
                            Text(error).font(.ppCallout).foregroundColor(.ppDestructive).multilineTextAlignment(.center)
                        }

                        // Details
                        VStack(alignment: .leading, spacing: PPSpacing.lg) {
                            Text(String(localized: "section.accountDetails"))
                                .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack(spacing: 2) {
                                    Text(String(localized: "field.name")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                }
                                TextField("e.g. Main Checking", text: $name)
                                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                    .accessibilityIdentifier("account-name-input")
                            }

                            // Account Type
                            HStack {
                                Text(String(localized: "field.accountType"))
                                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                Spacer()
                                Picker("Account Type", selection: $accountType) {
                                    ForEach(accountTypes, id: \.self) { type in
                                        Text(typeLabels[type] ?? type).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(theme.primary)
                                .accessibilityIdentifier("account-type-picker")
                            }

                            // Starting Balance
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text(String(localized: "field.startingBalance"))
                                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                HStack {
                                    Text(currencySymbol).font(.ppAmount).foregroundColor(.ppTextSecondary)
                                    TextField("0.00", text: $balanceText).keyboardType(.decimalPad)
                                        .font(.ppAmount).foregroundColor(.ppTextPrimary)
                                        .accessibilityIdentifier("account-balance-input")
                                }
                                .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }

                            // Spend Limit (for CreditCard and Allowance)
                            if showSpendLimit {
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    Text(String(localized: "field.spendLimit"))
                                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    HStack {
                                        Text(currencySymbol).font(.ppAmount).foregroundColor(.ppTextSecondary)
                                        TextField("0.00", text: $spendLimitText).keyboardType(.decimalPad)
                                            .font(.ppAmount).foregroundColor(.ppTextPrimary)
                                    }
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                            }
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                        // Appearance
                        VStack(alignment: .leading, spacing: PPSpacing.lg) {
                            Text(String(localized: "section.appearance"))
                                .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text(String(localized: "field.color")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: PPSpacing.sm) {
                                    ForEach(colorOptions, id: \.self) { c in
                                        Circle()
                                            .fill(Color(hex: c) ?? theme.primary)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle().stroke(Color.white, lineWidth: color == c ? 2 : 0)
                                            )
                                            .onTapGesture { color = c }
                                    }
                                }
                            }
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle(String(localized: "nav.addAccount")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.ppTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await create() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                        }
                    }
                    .foregroundColor(.ppTextSecondary)
                    .disabled(isDisabled || isLoading)
                    .opacity(isDisabled ? 0.6 : 1)
                    .accessibilityIdentifier("account-form-submit")
                }
            }
        }
    }

    private func create() async {
        isLoading = true; errorMessage = nil

        let spendLimit: Int32? = {
            guard showSpendLimit, !spendLimitText.isEmpty else { return nil }
            let cleaned = spendLimitText.replacingOccurrences(of: ",", with: ".")
            guard let value = Double(cleaned) else { return nil }
            return Int32(value * 100)
        }()
        
        struct Req: Encodable {
            let name: String; let color: String
            let accountType: String; let initialBalance: Int64; let spendLimit: Int32?
            let currencyId: String?
        }
        let req = Req(name: name.trimmingCharacters(in: .whitespaces), color: color, accountType: accountType, initialBalance: balanceInCents, spendLimit: spendLimit, currencyId: nil)
        do {
            try await appState.apiClient.request(.createAccount, body: req)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onCreated(); dismiss()
        } catch let e as APIError {
            errorMessage = e.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "Failed to create account.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isLoading = false
    }
}
