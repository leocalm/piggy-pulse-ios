import SwiftUI

struct AddAccountSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var spendLimitText = ""
    @State private var color = "#6C5CE7"
    @State private var accountType = "Checking"
    @State private var balanceText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var onCreated: () -> Void

    private let accountTypes = ["Checking", "Savings", "CreditCard", "Wallet", "Allowance"]
    private let typeLabels = ["Checking": "Checking", "Savings": "Savings", "CreditCard": "Credit Card", "Wallet": "Wallet", "Allowance": "Allowance"]
    private let colorOptions = ["#6C5CE7", "#00B894", "#E17055", "#0984E3", "#FDCB6E", "#E84393", "#00CEC9", "#636E72"]

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
                Color.ppBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: PPSpacing.xl) {
                        if let error = errorMessage {
                            Text(error).font(.ppCallout).foregroundColor(.ppDestructive).multilineTextAlignment(.center)
                        }

                        // Details
                        VStack(alignment: .leading, spacing: PPSpacing.lg) {
                            Text("Account Details")
                                .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                            PPTextField(label: "Name", placeholder: "e.g. Main Checking", isRequired: true, text: $name)

                            // Account Type
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text("Account Type")
                                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                Menu {
                                    ForEach(accountTypes, id: \.self) { type in
                                        Button(typeLabels[type] ?? type) { accountType = type }
                                    }
                                } label: {
                                    HStack {
                                        Text(typeLabels[accountType] ?? accountType)
                                            .font(.ppBody).foregroundColor(.ppTextPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 12)).foregroundColor(.ppTextSecondary)
                                    }
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).cornerRadius(PPRadius.md)
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                            }

                            // Starting Balance
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text("Starting Balance")
                                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                HStack {
                                    Text("€").font(.ppBody).foregroundColor(.ppTextSecondary)
                                    TextField("0.00", text: $balanceText).keyboardType(.decimalPad)
                                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                                }
                                .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                .background(Color.ppSurface).cornerRadius(PPRadius.md)
                                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }
                            
                            // Spend Limit (for CreditCard and Allowance)
                            if showSpendLimit {
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    Text("Spend Limit")
                                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    HStack {
                                        Text("€").font(.ppBody).foregroundColor(.ppTextSecondary)
                                        TextField("0.00", text: $spendLimitText).keyboardType(.decimalPad)
                                            .font(.ppBody).foregroundColor(.ppTextPrimary)
                                    }
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).cornerRadius(PPRadius.md)
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                            }
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard).cornerRadius(PPRadius.lg)
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                        // Appearance
                        VStack(alignment: .leading, spacing: PPSpacing.lg) {
                            Text("Appearance")
                                .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text("Color").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
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
                        .padding(PPSpacing.lg).background(Color.ppCard).cornerRadius(PPRadius.lg)
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                        // Submit
                        Button {
                            Task { await create() }
                        } label: {
                            Group {
                                if isLoading { ProgressView().tint(.white) }
                                else { Label("Create Account", systemImage: "plus.circle").font(.ppHeadline) }
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.md)
                        }
                        .buttonStyle(.borderedProminent).tint(.ppPrimary).cornerRadius(PPRadius.full)
                        .disabled(isDisabled).opacity(isDisabled ? 0.6 : 1)
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle("Add Account").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.ppTextSecondary)
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
            let _: AccountListItem = try await appState.apiClient.request(.createAccount, body: req)
            onCreated(); dismiss()
        } catch let e as APIError { errorMessage = e.errorDescription }
        catch { errorMessage = "Failed to create account." }
        isLoading = false
    }
}
