import SwiftUI

struct EditCategorySheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let category: CategoryManagementItem
    var onUpdated: () -> Void

    @State private var name = ""
    @State private var icon = ""
    @State private var color = ""
    @State private var categoryType = "Outgoing"
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let colorOptions = ["#6C5CE7", "#00B894", "#E17055", "#0984E3", "#FDCB6E", "#E84393", "#00CEC9", "#636E72"]
    private let icons = ["🛒", "🏠", "🚗", "💡", "🎮", "👕", "🍽️", "☕", "✈️", "🏥", "📚", "🎵", "💼", "🎁", "🐾", "💰", "📱", "🏋️", "🎬", "🧾", "💳", "🚌", "🍕", "🛍️"]
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
                            Text("Category Details").font(.ppTitle3).foregroundColor(.ppTextPrimary)
                            PPTextField(label: "Name", placeholder: "Category name", isRequired: true, text: $name)

                            if !category.isSystem {
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    Text("Type").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    HStack(spacing: 0) {
                                        typeButton("Incoming"); typeButton("Outgoing")
                                    }
                                    .background(Color.ppSurface).cornerRadius(PPRadius.md)
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                            }

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text("Icon").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: PPSpacing.sm) {
                                    ForEach(icons, id: \.self) { i in
                                        Text(i).font(.system(size: 24)).frame(width: 36, height: 36)
                                            .background(icon == i ? Color.ppPrimary.opacity(0.3) : Color.clear).cornerRadius(PPRadius.sm)
                                            .overlay(RoundedRectangle(cornerRadius: PPRadius.sm).stroke(icon == i ? Color.ppPrimary : Color.clear, lineWidth: 1))
                                            .onTapGesture { icon = i }
                                    }
                                }
                            }

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
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle("Edit Category").navigationBarTitleDisplayMode(.inline)
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
            .onAppear { name = category.name; icon = category.icon; color = category.color; categoryType = category.categoryType }
        }
    }

    private func typeButton(_ type: String) -> some View {
        Button {
            categoryType = type
        } label: {
            Text(type).font(.ppCallout).fontWeight(categoryType == type ? .semibold : .regular)
                .foregroundColor(categoryType == type ? .ppTextPrimary : .ppTextSecondary)
                .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.md)
                .background(categoryType == type ? Color.ppCard : Color.clear).cornerRadius(PPRadius.sm)
        }
    }

    private func save() async {
        isLoading = true; errorMessage = nil
        struct Req: Encodable {
            let name: String; let color: String; let icon: String; let categoryType: String
        }
        let req = Req(name: name.trimmingCharacters(in: .whitespaces), color: color, icon: icon, categoryType: categoryType)
        do {
            let _: CategoryListItem = try await appState.apiClient.request(.updateCategory(category.id), body: req)
            onUpdated(); dismiss()
        } catch let e as APIError { errorMessage = e.errorDescription }
        catch { errorMessage = "Failed to update category." }
        isLoading = false
    }
}
