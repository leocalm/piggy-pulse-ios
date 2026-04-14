import SwiftUI

struct EditCategorySheet: View {
    @EnvironmentObject var appState: AppState
@Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme

    let category: CategoryManagementItem
    let apiClient: APIClient
    var currentTarget: Int64?
    var onUpdated: () -> Void

    @State private var hasActiveSubscriptions = false
    @State private var refreshToken = 0

    @State private var name = ""
    @State private var icon = ""
    @State private var color = ""
    @State private var categoryType = "Outgoing"
    @State private var targetAmountText = ""
    @State private var behavior: String = ""
    private let behaviorOptions = ["", "fixed", "variable", "subscription"]
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let colorOptions = ["#007AFF", "#00B894", "#E17055", "#0984E3", "#FDCB6E", "#E84393", "#00CEC9", "#636E72"]
    private var isDisabled: Bool { name.trimmingCharacters(in: .whitespaces).count < 3 || isLoading }

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
                            Text(String(localized: "section.categoryDetails")).font(.ppTitle3).foregroundColor(.ppTextPrimary)
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack(spacing: 2) {
                                    Text(String(localized: "field.name")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                }
                                TextField("Category name", text: $name)
                                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }

                            // Category type is immutable after creation. The backend
                            // enforces this via a BEFORE UPDATE trigger on the `category`
                            // table (piggy-pulse-api migration 20260327000004) because
                            // category_type is snapshotted by the transaction aggregate
                            // trigger at insert time to classify inflow/outflow/spending.
                            // Editing it would silently drift the materialized aggregates.
                            // We keep the picker visible so the user can see the current
                            // type, but disable it in edit mode.
                            if !category.isSystem {
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    Text(String(localized: "field.type")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    Picker("Type", selection: $categoryType) {
                                        Text(String(localized: "category.incoming")).tag("Incoming")
                                        Text(String(localized: "category.outgoing")).tag("Outgoing")
                                    }
                                    .pickerStyle(.segmented)
                                    .disabled(true)
                                }
                            }

                            EmojiPicker(selection: $icon)

                            // Color is determined by type+behavior on the server
                            // Behavior
                            behaviorSection

                            // Target amount (hidden for subscription behavior)
                            if behavior != "subscription" {
                                targetSection
                            }
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                        // Inline subscription management for subscription-behavior categories
                        if behavior == "subscription" {
                            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                                Text(String(localized: "category.subscription.section.title"))
                                    .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                                CategorySubscriptionSection(
                                    categoryId: category.id,
                                    apiClient: apiClient,
                                    currencyCode: appState.currencyCode,
                                    onSubscriptionChanged: { refreshToken += 1 }
                                )
                            }
                            .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
                        }
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle(String(localized: "nav.editCategory")).navigationBarTitleDisplayMode(.inline)
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
            .onAppear {
                name = category.name; icon = category.icon; color = category.color
                behavior = category.behavior ?? ""
                // Normalize casing to match Picker tags ("Incoming"/"Outgoing")
                categoryType = category.type.lowercased() == "income" ? "Incoming" : "Outgoing"
                if let target = currentTarget, target > 0 {
                    targetAmountText = String(format: "%.2f", Double(target) / 100.0)
                }
            }
            .task(id: refreshToken) {
                // Check if there are active subscriptions to lock the behavior picker
                guard category.behavior == "subscription" else { return }
                let subs: [Subscription]? = try? await apiClient.request(
                    .subscriptions,
                    queryItems: [URLQueryItem(name: "categoryId", value: category.id.uuidString)]
                )
                hasActiveSubscriptions = subs?.contains(where: { $0.status == .active }) ?? false
            }
        }
    }

    // MARK: - Extracted Sections

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            HStack(spacing: PPSpacing.sm) {
                Text(String(localized: "category.behavior"))
                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                if hasActiveSubscriptions {
                    Image(systemName: "lock.fill")
                        .font(.ppCaption).foregroundColor(.ppTextTertiary)
                }
            }
            Picker("", selection: $behavior) {
                Text(String(localized: "category.behavior.fixed")).tag("fixed")
                Text(String(localized: "category.behavior.variable")).tag("variable")
                Text(String(localized: "category.behavior.subscription")).tag("subscription")
            }
            .pickerStyle(.segmented)
            .disabled(hasActiveSubscriptions)
            .opacity(hasActiveSubscriptions ? 0.6 : 1)

            if hasActiveSubscriptions {
                Text(String(localized: "category.subscription.behaviorLocked"))
                    .font(.ppCaption).foregroundColor(.ppTextTertiary)
            }
        }
    }

    private var targetSection: some View {
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
    }

    private func save() async {
        isLoading = true; errorMessage = nil
        struct Req: Encodable {
            let name: String; let color: String; let icon: String; let type: String; let target: Int64?; let behavior: String?
            enum CodingKeys: String, CodingKey { case name, color, icon, type, target, behavior }
            func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                try c.encode(name, forKey: .name)
                try c.encode(color, forKey: .color)
                try c.encode(icon, forKey: .icon)
                try c.encode(type, forKey: .type)
                try c.encodeIfPresent(target, forKey: .target)
                try c.encodeIfPresent(behavior, forKey: .behavior)
            }
        }
        let targetCents: Int64? = {
            let cleaned = targetAmountText.replacingOccurrences(of: ",", with: ".")
            guard let decimal = Decimal(string: cleaned), decimal > 0 else { return nil }
            return NSDecimalNumber(decimal: decimal * 100).int64Value
        }()
        // Map UI types to v2 types
        let v2Type = categoryType == "Incoming" ? "income" : "expense"
        let req = Req(name: name.trimmingCharacters(in: .whitespaces), color: "#000000", icon: icon, type: v2Type, target: targetCents, behavior: behavior.isEmpty ? nil : behavior)
        do {
            try await appState.apiClient.request(.updateCategory(category.id), body: req)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onUpdated(); dismiss()
        } catch let e as APIError {
            errorMessage = e.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "Failed to update category.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isLoading = false
    }
}
