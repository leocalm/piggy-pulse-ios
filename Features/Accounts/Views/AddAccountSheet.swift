import SwiftUI

struct AddAccountSheet: View {
    @EnvironmentObject var appState: AppState
@Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var spendLimitText = ""
    @State private var color = "#007AFF"
    @State private var accountType = "Checking"
    @State private var balanceText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var onCreated: () -> Void

    private let accountTypes = ["Checking", "Savings", "CreditCard", "Wallet", "Allowance"]
    private let typeLabels = ["Checking": "Checking", "Savings": "Savings", "CreditCard": "Credit Card", "Wallet": "Wallet", "Allowance": "Allowance"]
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
        case "Checking": return "🏦"
        case "Savings": return "💰"
        case "CreditCard": return "💳"
        case "Wallet": return "👛"
        case "Allowance": return "🎯"
        default: return "🏦"
        }
    }

    private var showSpendLimit: Bool {
        accountType == "CreditCard" || accountType == "Allowance"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground(colorScheme).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: PPSpacing.xl) {
                        if let error = errorMessage {
                            Text(error).font(.ppCallout).foregroundColor(.ppDestructive).multilineTextAlignment(.center)
                        }

                        // Details
                        VStack(alignment: .leading, spacing: PPSpacing.lg) {
                            Text("Account Details")
                                .font(.ppTitle3).foregroundColor(.ppTextPrimary(colorScheme))

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack(spacing: 2) {
                                    Text("Name").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                }
                                TextField("e.g. Main Checking", text: $name)
                                    .font(.ppBody).foregroundColor(.ppTextPrimary(colorScheme))
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface(colorScheme)).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
                            }

                            // Account Type
                            HStack {
                                Text("Account Type")
                                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                                Spacer()
                                Picker("Account Type", selection: $accountType) {
                                    ForEach(accountTypes, id: \.self) { type in
                                        Text(typeLabels[type] ?? type).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.ppPrimary)
                            }

                            // Starting Balance
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text("Starting Balance")
                                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                                HStack {
                                    Text(currencySymbol).font(.ppAmount).foregroundColor(.ppTextSecondary(colorScheme))
                                    TextField("0.00", text: $balanceText).keyboardType(.decimalPad)
                                        .font(.ppAmount).foregroundColor(.ppTextPrimary(colorScheme))
                                }
                                .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                .background(Color.ppSurface(colorScheme)).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
                            }
                            
                            // Spend Limit (for CreditCard and Allowance)
                            if showSpendLimit {
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    Text("Spend Limit")
                                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                                    HStack {
                                        Text(currencySymbol).font(.ppAmount).foregroundColor(.ppTextSecondary(colorScheme))
                                        TextField("0.00", text: $spendLimitText).keyboardType(.decimalPad)
                                            .font(.ppAmount).foregroundColor(.ppTextPrimary(colorScheme))
                                    }
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface(colorScheme)).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
                                }
                            }
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard(colorScheme)).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder(colorScheme), lineWidth: 1))

                        // Appearance
                        VStack(alignment: .leading, spacing: PPSpacing.lg) {
                            Text("Appearance")
                                .font(.ppTitle3).foregroundColor(.ppTextPrimary(colorScheme))

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text("Color").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: PPSpacing.sm) {
                                    ForEach(colorOptions, id: \.self) { c in
                                        Circle()
                                            .fill(Color(hex: c) ?? .ppPrimary)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle().stroke(Color.white, lineWidth: color == c ? 2 : 0)
                                            )
                                            .onTapGesture { color = c }
                                    }
                                }
                            }
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard(colorScheme)).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle("Add Account").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground(colorScheme), for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.ppTextSecondary(colorScheme))
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
                    .foregroundColor(.ppTextSecondary(colorScheme))
                    .disabled(isDisabled || isLoading)
                    .opacity(isDisabled ? 0.6 : 1)
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
            let name: String; let color: String; let icon: String
            let accountType: String; let balance: Int64; let spendLimit: Int32?
        }
        let req = Req(name: name.trimmingCharacters(in: .whitespaces), color: color, icon: defaultIcon, accountType: accountType, balance: balanceInCents, spendLimit: spendLimit)
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
