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
    private let colorOptions = ["#6C5CE7", "#00B894", "#E17055", "#0984E3", "#FDCB6E", "#E84393", "#00CEC9", "#636E72"]

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
                            PPTextField(label: "Name", placeholder: "Account name", isRequired: true, text: $name)

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text("Account Type").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                Menu {
                                    ForEach(accountTypes, id: \.self) { type in
                                        Button(typeLabels[type] ?? type) { accountType = type }
                                    }
                                } label: {
                                    HStack {
                                        Text(typeLabels[accountType] ?? accountType).font(.ppBody).foregroundColor(.ppTextPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 12)).foregroundColor(.ppTextSecondary)
                                    }
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).cornerRadius(PPRadius.md)
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                            }

                            if showSpendLimit {
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    Text("Spend Limit").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    HStack {
                                        Text("€").font(.ppBody).foregroundColor(.ppTextSecondary)
                                        TextField("0.00", text: $spendLimitText).keyboardType(.decimalPad).font(.ppBody).foregroundColor(.ppTextPrimary)
                                    }
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).cornerRadius(PPRadius.md)
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                            }
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard).cornerRadius(PPRadius.lg)
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
                        .padding(PPSpacing.lg).background(Color.ppCard).cornerRadius(PPRadius.lg)
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                        Button { Task { await save() } } label: {
                            Group {
                                if isLoading { ProgressView().tint(.white) }
                                else { Text("Save Changes").font(.ppHeadline) }
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.md)
                        }
                        .buttonStyle(.borderedProminent).tint(.ppPrimary).cornerRadius(PPRadius.full)
                        .disabled(isDisabled).opacity(isDisabled ? 0.6 : 1)
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle("Edit Account").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(.ppTextSecondary) }
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
            let _: AccountListItem = try await appState.apiClient.request(.updateAccount(account.id), body: req)
            onUpdated(); dismiss()
        } catch let e as APIError { errorMessage = e.errorDescription }
        catch { errorMessage = "Failed to update account." }
        isLoading = false
    }
}
