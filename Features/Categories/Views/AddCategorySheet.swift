import SwiftUI

struct AddCategorySheet: View {
    @EnvironmentObject var appState: AppState
@Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme

    @State private var name = ""
    @State private var icon = "🛒"
    @State private var color = "#007AFF"
    @State private var categoryType = "Outgoing"
    @State private var targetAmountText = ""
    @State private var behavior = "variable"
    @State private var isLoading = false
    @State private var errorMessage: String?

    var onCreated: () -> Void

    private let colorOptions = ["#007AFF", "#00B894", "#E17055", "#0984E3", "#FDCB6E", "#E84393", "#00CEC9", "#636E72"]

    private var isDisabled: Bool {
        name.trimmingCharacters(in: .whitespaces).count < 3 || isLoading
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
                            Text(String(localized: "section.categoryDetails"))
                                .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack(spacing: 2) {
                                    Text(String(localized: "field.name")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                }
                                TextField("e.g. Groceries", text: $name)
                                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                    .accessibilityIdentifier("category-name-input")
                            }

                            // Type
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text(String(localized: "field.type")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                Picker("Type", selection: $categoryType) {
                                    Text(String(localized: "category.incoming")).tag("Incoming")
                                        .accessibilityIdentifier("category-type-income")
                                    Text(String(localized: "category.outgoing")).tag("Outgoing")
                                        .accessibilityIdentifier("category-type-expense")
                                }
                                .pickerStyle(.segmented)
                            }

                            // Icon selector
                            EmojiPicker(selection: $icon)

                            // Color is determined by type+behavior on the server

                            // Behavior
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text(String(localized: "category.behavior"))
                                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                Picker("", selection: $behavior) {
                                    Text(String(localized: "category.behavior.fixed")).tag("fixed")
                                    Text(String(localized: "category.behavior.variable")).tag("variable")
                                    Text(String(localized: "category.behavior.subscription")).tag("subscription")
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: behavior) { _, newValue in
                                    if newValue == "subscription" {
                                        targetAmountText = ""
                                    }
                                }
                            }

                            // Target amount (hidden for subscription behavior)
                            if behavior != "subscription" {
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    Text(String(localized: "category.target"))
                                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    TextField(String(localized: "category.targetPlaceholder"), text: $targetAmountText)
                                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                                        .keyboardType(.decimalPad)
                                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                        .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                    Text(String(localized: "category.targetHint"))
                                        .font(.ppCaption).foregroundColor(.ppTextTertiary)
                                }
                            } else {
                                HStack(spacing: PPSpacing.sm) {
                                    Image(systemName: "info.circle")
                                        .font(.ppBody).foregroundColor(.ppTextSecondary)
                                    Text(String(localized: "category.subscription.addInfo"))
                                        .font(.ppCaption).foregroundColor(.ppTextSecondary)
                                }
                                .padding(PPSpacing.md)
                                .background(Color.ppSurface)
                                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            }
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle(String(localized: "nav.addCategory")).navigationBarTitleDisplayMode(.inline)
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
                    .accessibilityIdentifier("category-form-submit")
                }
            }
        }
    }

    private func create() async {
        isLoading = true; errorMessage = nil
        struct Req: Encodable {
            let name: String; let color: String; let icon: String; let type: String; let behavior: String?
        }
        struct CategoryCreatedResponse: Decodable {
            let id: UUID
        }
        let targetCents: Int64? = {
            let cleaned = targetAmountText.replacingOccurrences(of: ",", with: ".")
            guard let decimal = Decimal(string: cleaned), decimal > 0 else { return nil }
            return NSDecimalNumber(decimal: decimal * 100).int64Value
        }()
        let v2Type = categoryType == "Incoming" ? "income" : "expense"
        let req = Req(name: name.trimmingCharacters(in: .whitespaces), color: "#000000", icon: icon, type: v2Type, behavior: behavior.isEmpty ? nil : behavior)
        do {
            let created: CategoryCreatedResponse = try await appState.apiClient.request(.createCategory, body: req)
            // Create target as a separate API call if a value was entered
            if let cents = targetCents {
                try await appState.apiClient.request(
                    .createCategoryTarget,
                    body: CreateTargetRequest(categoryId: created.id, value: cents)
                )
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onCreated(); dismiss()
        } catch let e as APIError {
            errorMessage = e.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "Failed to create category.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isLoading = false
    }
}
