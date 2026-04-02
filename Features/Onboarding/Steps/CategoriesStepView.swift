import SwiftUI

struct CategoriesStepView: View {
    @ObservedObject var vm: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeManager) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                // Title
                Text(String(localized: "categories.title"))
                    .font(.ppTitle3).fontWeight(.bold).foregroundColor(.ppTextPrimary)

                // Descriptions
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text(String(localized: "categories.description1"))
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                    Text(String(localized: "categories.description2"))
                        .font(.ppBody).foregroundColor(.ppTextSecondary)
                }

                // Template cards
                if vm.isLoadingTemplates {
                    ProgressView().frame(maxWidth: .infinity)
                } else if !vm.templates.isEmpty {
                    VStack(spacing: PPSpacing.sm) {
                        ForEach(vm.templates) { template in
                            templateCard(template)
                        }
                    }
                }

                // Selected template category preview
                if let selected = vm.selectedTemplate {
                    categoryPreview(for: selected)
                }

                // Color hint
                HStack(alignment: .top, spacing: PPSpacing.sm) {
                    Image(systemName: "info.circle").foregroundColor(.ppTextTertiary).font(.ppCaption)
                    Text(String(localized: "categories.colorHint"))
                        .font(.ppCaption).foregroundColor(.ppTextTertiary)
                }
                .padding(PPSpacing.md)
                .background(Color.ppSurface)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
            }
            .padding(PPSpacing.xl)
        }
        .task { await vm.loadTemplates() }
    }

    private func templateCard(_ template: OnboardingTemplate) -> some View {
        let isSelected = vm.selectedTemplateId == template.id
        return Button {
            if vm.selectedTemplateId == template.id {
                vm.selectedTemplateId = nil
                vm.appliedCategories = []
            } else {
                vm.selectedTemplateId = template.id
                vm.appliedCategories = template.categories
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: PPSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.ppCallout).fontWeight(.semibold)
                        .foregroundColor(isSelected ? theme.primary : .ppTextPrimary)
                    Text(template.description)
                        .font(.ppCaption).foregroundColor(.ppTextSecondary)
                        .lineLimit(2)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(theme.primary)
                }
            }
            .padding(PPSpacing.lg)
            .background(isSelected ? theme.primary.opacity(0.08) : Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.md)
                    .stroke(isSelected ? theme.primary : Color.ppBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func categoryPreview(for template: OnboardingTemplate) -> some View {
        let incoming = template.categories.filter { $0.type.lowercased() == "income" }
        let outgoing = template.categories.filter { $0.type.lowercased() == "expense" }

        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            if !incoming.isEmpty {
                Text(String(localized: "category.incoming"))
                    .font(.ppCaption).fontWeight(.semibold).foregroundColor(.ppTextSecondary)
                    .padding(.top, PPSpacing.xs)
                ForEach(incoming) { cat in
                    categoryPreviewRow(cat)
                }
            }
            if !outgoing.isEmpty {
                Text(String(localized: "category.outgoing"))
                    .font(.ppCaption).fontWeight(.semibold).foregroundColor(.ppTextSecondary)
                    .padding(.top, PPSpacing.xs)
                ForEach(outgoing) { cat in
                    categoryPreviewRow(cat)
                }
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func categoryPreviewRow(_ cat: OnboardingTemplateCategory) -> some View {
        HStack(spacing: PPSpacing.sm) {
            Text(cat.icon).font(.body)
            Text(cat.name)
                .font(.ppCallout).foregroundColor(.ppTextPrimary)
            Spacer()
            if let behavior = cat.behavior {
                Text(behavior)
                    .font(.ppCaption).foregroundColor(.ppTextTertiary)
                    .padding(.horizontal, PPSpacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.ppSurface)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, PPSpacing.xs)
    }
}
