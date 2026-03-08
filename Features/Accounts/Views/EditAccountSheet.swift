import SwiftUI

struct EditAccountSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let account: AccountListItem
    var onUpdated: () -> Void

    @State private var name = ""
    @State private var color = ""
    @State private var accountType = "Checking"
    @State private var spendLimitText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let accountTypes = ["Checking", "Savings", "CreditCard", "Wallet", "Allowance"]
    private let typeLabels = ["Checking": "Checking", "Savings": "Savings", "CreditCard": "Credit Card", "Wallet": "Wallet", "Allowance": "Allowance"]
    private let colorOptions = ["#007AFF", "#00B894", "#E17055", "#0984E3", "#FDCB6E", "#E84393", "#00CEC9", "#636E72"]

    private var currencySymbol: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = appState.currencyCode
        return fmt.currencySymbol ?? appState.currencyCode
    }

    private var showSpendLimit: Bool { accountType == "CreditCard" || accountType == "Allowance" }
    private var isDisabled: Bool { name.trimmingCharacters(in: .whitespaces).count < 3 || isLoading }

    private var defaultIcon: String {
        switch accountType {
        case "Checking": return "🏦"; case "Savings": return "💰"; case "CreditCard": return "💳"
        case "Wallet": return "👛"; case "Allowance": return "🎯"; default: return "🏦"
        }
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

                        VStack(alignment: .leading, spacing: PPSpacing.lg) {
                            Text("Account Details").font(.ppTitle3).foregroundColor(.ppTextPrimary)
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack(spacing: 2) {
                                    Text("Name").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                }
                                TextField("Account name", text: $name)
                                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }

                            HStack {
                                Text("Account Type").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                Spacer()
                                Picker("Account Type", selection: $accountType) {
                                    ForEach(accountTypes, id: \.self) { type in
                                        Text(typeLabels[type] ?? type).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.ppPrimary)
                            }

                            if showSpendLimit {
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    Text("Spend Limit").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    HStack {
                                        Text(currencySymbol).font(.ppBody).foregroundColor(.ppTextSecondary)
                                        TextField("0.00", text: $spendLimitText).keyboardType(.decimalPad).font(.ppBody).foregroundColor(.ppTextPrimary)
                                    }
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                            }
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                        VStack(alignment: .leading, spacing: PPSpacing.lg) {
                            Text("Appearance").font(.ppTitle3).foregroundColor(.ppTextPrimary)
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text("Color").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: PPSpacing.sm) {
                                    ForEach(colorOptions, id: \.self) { c in
                                        Circle().fill(Color(hex: c) ?? .ppPrimary).frame(width: 32, height: 32)
                                            .overlay(Circle().stroke(Color.white, lineWidth: color == c ? 2 : 0))
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
            .navigationTitle("Edit Account").navigationBarTitleDisplayMode(.inline)
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
                        Task { await save() }
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
                }
            }
            .onAppear { prefill() }
        }
    }

    private func prefill() {
        name = account.name
        color = account.color
        accountType = account.accountType
        if let limit = account.spendLimit {
            spendLimitText = String(format: "%.2f", Double(limit) / 100.0)
        }
    }

    private func save() async {
        isLoading = true; errorMessage = nil
        let spendLimit: Int32? = {
            guard showSpendLimit, !spendLimitText.isEmpty else { return nil }
            let cleaned = spendLimitText.replacingOccurrences(of: ",", with: ".")
            guard let value = Double(cleaned) else { return nil }
            return Int32(value * 100)
        }()

        struct Req: Encodable {
            let name: String; let color: String; let icon: String; let accountType: String; let spendLimit: Int32?
        }
        let req = Req(name: name.trimmingCharacters(in: .whitespaces), color: color, icon: defaultIcon, accountType: accountType, spendLimit: spendLimit)
        do {
            try await appState.apiClient.request(.updateAccount(account.id), body: req)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onUpdated(); dismiss()
        } catch let e as APIError {
            errorMessage = e.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "Failed to update account.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isLoading = false
    }
}
