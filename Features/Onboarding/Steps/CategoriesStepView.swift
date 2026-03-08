import SwiftUI

struct CategoriesStepView: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var showAddCategory = false
    @State private var newName = ""
    @State private var newIcon = "📦"
    @State private var newType = "Outgoing"

    private let templates: [(title: String, subtitle: String, template: CategoryTemplate)] = [
        ("Essential 5",  "5 basic categories to get started",        .essential),
        ("Detailed 12",  "12 categories for detailed tracking",       .detailed),
        ("Custom",       "Start with an empty list",                  .custom),
    ]

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
                            Text("Incoming").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppSuccess)
                            ForEach(incoming) { cat in categoryRow(cat) }
                        }
                        if !outgoing.isEmpty {
                            Text("Outgoing").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppDestructive)
                                .padding(.top, PPSpacing.sm)
                            ForEach(outgoing) { cat in categoryRow(cat) }
                        }
                    }
                }

                // Add category
                if vm.selectedTemplate != .none {
                    if showAddCategory {
                        addCategoryForm
                    } else {
                        Button {
                            showAddCategory = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill").foregroundColor(.ppPrimary)
                                Text("Add Category").font(.ppCallout).foregroundColor(.ppPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(PPSpacing.md)
                            .background(Color.ppPrimary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
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

    private var addCategoryForm: some View {
        VStack(alignment: .leading, spacing: PPSpacing.md) {
            Text("New Category").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)

            HStack(spacing: PPSpacing.sm) {
                TextField("Icon", text: $newIcon).frame(width: 48)
                    .font(.title3).multilineTextAlignment(.center)
                    .padding(.horizontal, PPSpacing.sm).padding(.vertical, PPSpacing.sm)
                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.sm).stroke(Color.ppBorder, lineWidth: 1))

                TextField("Category name", text: $newName)
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                    .padding(.horizontal, PPSpacing.md).padding(.vertical, PPSpacing.sm)
                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.sm).stroke(Color.ppBorder, lineWidth: 1))
            }

            Picker("Direction", selection: $newType) {
                Text("Incoming").tag("Incoming")
                Text("Outgoing").tag("Outgoing")
            }.pickerStyle(.segmented)

            HStack {
                Button("Cancel") {
                    showAddCategory = false; newName = ""; newIcon = "📦"; newType = "Outgoing"
                }.foregroundColor(.ppTextSecondary)
                Spacer()
                Button("Add") {
                    guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    vm.addCategory(DraftCategory(name: newName.trimmingCharacters(in: .whitespaces), icon: newIcon, categoryType: newType))
                    showAddCategory = false; newName = ""; newIcon = "📦"; newType = "Outgoing"
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .foregroundColor(.ppPrimary).fontWeight(.semibold)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func templateMatches(_ template: CategoryTemplate) -> Bool {
        switch (vm.selectedTemplate, template) {
        case (.essential, .essential), (.detailed, .detailed), (.custom, .custom): return true
        default: return false
        }
    }
}
