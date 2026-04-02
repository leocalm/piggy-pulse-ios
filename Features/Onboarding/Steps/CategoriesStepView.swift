import SwiftUI

struct CategoriesStepView: View {
    @ObservedObject var vm: OnboardingViewModel
    @Environment(\.themeManager) private var theme

    @State private var name = ""
    @State private var icon = "🛒"
    @State private var categoryType = "expense"  // "income" | "expense"
    @State private var behavior = "variable"      // "fixed" | "variable"
    @State private var targetText = ""

    private var isFormValid: Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 3
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                // Title
                Text(String(localized: "onboarding.categories.createTitle"))
                    .font(.ppTitle3).fontWeight(.bold).foregroundColor(.ppTextPrimary)

                // Description
                Text(String(localized: "onboarding.categories.createDesc"))
                    .font(.ppBody).foregroundColor(.ppTextSecondary)

                // Inline creation form
                VStack(alignment: .leading, spacing: PPSpacing.lg) {

                    // Name
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        Text(String(localized: "field.name"))
                            .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        TextField(String(localized: "onboarding.categories.namePlaceholder"), text: $name)
                            .font(.ppBody).foregroundColor(.ppTextPrimary)
                            .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                            .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                    }

                    // Emoji picker
                    EmojiPicker(selection: $icon)

                    // Type picker (Income / Expense)
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        Text(String(localized: "field.type"))
                            .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        Picker("", selection: $categoryType) {
                            Text(String(localized: "category.incoming")).tag("income")
                            Text(String(localized: "category.outgoing")).tag("expense")
                        }
                        .pickerStyle(.segmented)
                    }

                    // Behavior picker (Fixed / Variable)
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        Text(String(localized: "category.behavior"))
                            .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        Picker("", selection: $behavior) {
                            Text(String(localized: "category.behavior.fixed")).tag("fixed")
                            Text(String(localized: "category.behavior.variable")).tag("variable")
                        }
                        .pickerStyle(.segmented)
                    }

                    // Target amount (optional)
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        Text(String(localized: "category.target"))
                            .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        TextField(String(localized: "category.targetPlaceholder"), text: $targetText)
                            .font(.ppBody).foregroundColor(.ppTextPrimary)
                            .keyboardType(.decimalPad)
                            .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                            .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                        Text(String(localized: "onboarding.categories.targetHint"))
                            .font(.ppCaption).foregroundColor(.ppTextTertiary)
                    }

                    // Add button
                    Button {
                        Task { await addCategory() }
                    } label: {
                        Group {
                            if vm.isCreatingCategory {
                                ProgressView().tint(.white)
                            } else {
                                Label(String(localized: "onboarding.categories.addButton"), systemImage: "plus.circle.fill")
                                    .font(.ppCallout).fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.md)
                        .background(isFormValid ? theme.primary : theme.primary.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                    }
                    .disabled(!isFormValid || vm.isCreatingCategory)
                }
                .padding(PPSpacing.lg)
                .background(Color.ppCard)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                // Created categories list
                if !vm.createdCategories.isEmpty {
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        Text(String(localized: "onboarding.categories.created"))
                            .font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)

                        ForEach(vm.createdCategories) { cat in
                            HStack(spacing: PPSpacing.md) {
                                Text(cat.icon).font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cat.name)
                                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    Text("\(cat.type == "income" ? String(localized: "category.incoming") : String(localized: "category.outgoing")) · \(cat.behavior)")
                                        .font(.ppCaption).foregroundColor(.ppTextSecondary)
                                }
                                Spacer()
                                Button {
                                    Task { await vm.deleteOnboardingCategory(cat) }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.ppCaption)
                                        .foregroundColor(.ppTextTertiary)
                                }
                            }
                            .padding(PPSpacing.md)
                            .background(Color.ppCard)
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                        }
                    }
                }

                // Hint
                HStack(alignment: .top, spacing: PPSpacing.sm) {
                    Image(systemName: "info.circle").foregroundColor(.ppTextTertiary).font(.ppCaption)
                    Text(String(localized: "onboarding.categories.hint"))
                        .font(.ppCaption).foregroundColor(.ppTextTertiary)
                }
                .padding(PPSpacing.md)
                .background(Color.ppSurface)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
            }
            .padding(PPSpacing.xl)
        }
    }

    private func addCategory() async {
        let targetCents: Int64? = {
            let cleaned = targetText.replacingOccurrences(of: ",", with: ".")
            guard let decimal = Decimal(string: cleaned), decimal > 0 else { return nil }
            return NSDecimalNumber(decimal: decimal * 100).int64Value
        }()

        await vm.createCategory(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: icon,
            type: categoryType,
            behavior: behavior,
            target: targetCents
        )

        // Reset form for next category
        name = ""
        icon = "🛒"
        targetText = ""
    }
}
