import SwiftUI

struct CategoriesStepView: View {
    @ObservedObject var vm: OnboardingViewModel
@Environment(\.colorScheme) private var colorScheme

    private var templates: [(title: String, subtitle: String, template: CategoryTemplate)] {[
        (String(localized: "Essential 5"),  String(localized: "5 basic categories to get started"),        .essential),
        (String(localized: "Detailed 12"),  String(localized: "12 categories for detailed tracking"),       .detailed),
    ]}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                Text("Categories are how you organize your spendings.")
                    .font(.ppBody).foregroundColor(.ppTextPrimary)

                // Template selector
                VStack(alignment: .leading, spacing: PPSpacing.md) {
                    Text("Choose a starting point")
                        .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                    ForEach(templates, id: \.title) { item in
                        let isSelected = templateMatches(item.template)
                        Button { vm.applyTemplate(item.template) } label: {
                            HStack(spacing: PPSpacing.md) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title).font(.ppCallout).fontWeight(.semibold)
                                        .foregroundColor(isSelected ? .ppPrimary : .ppTextPrimary)
                                    Text(item.subtitle).font(.ppCaption).foregroundColor(.ppTextSecondary)
                                }
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.ppPrimary)
                                }
                            }
                            .padding(PPSpacing.lg)
                            .background(isSelected ? Color.ppPrimary.opacity(0.08) : Color.ppCard)
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md)
                                .stroke(isSelected ? Color.ppPrimary : Color.ppBorder, lineWidth: isSelected ? 2 : 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Category list
                if !vm.categories.isEmpty || vm.selectedTemplate != .none {
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        let incoming = vm.categories.filter { $0.categoryType == "Incoming" }
                        let outgoing = vm.categories.filter { $0.categoryType == "Outgoing" }

                        if !incoming.isEmpty {
                            Text("Incoming").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTeal)
                            ForEach(incoming) { cat in categoryRow(cat) }
                        }
                        if !outgoing.isEmpty {
                            Text("Outgoing").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppDestructive)
                                .padding(.top, PPSpacing.sm)
                            ForEach(outgoing) { cat in categoryRow(cat) }
                        }
                    }
                }

            }
            .padding(PPSpacing.xl)
        }
    }

    private func categoryRow(_ cat: DraftCategory) -> some View {
        HStack {
            Text(cat.icon).font(.title3)
            Text(cat.name).font(.ppCallout).foregroundColor(.ppTextPrimary)
            Spacer()
            Button(role: .destructive) {
                vm.categories.removeAll { $0.id == cat.id }
            } label: {
                Image(systemName: "xmark").font(.caption).foregroundColor(.ppTextTertiary)
            }
        }
        .padding(.horizontal, PPSpacing.md).padding(.vertical, PPSpacing.sm)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
    }


    private func templateMatches(_ template: CategoryTemplate) -> Bool {
        switch (vm.selectedTemplate, template) {
        case (.essential, .essential), (.detailed, .detailed), (.custom, .custom): return true
        default: return false
        }
    }
}
