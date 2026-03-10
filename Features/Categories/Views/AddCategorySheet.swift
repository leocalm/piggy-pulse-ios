import SwiftUI

struct AddCategorySheet: View {
    @EnvironmentObject var appState: AppState
@Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "🛒"
    @State private var color = "#007AFF"
    @State private var categoryType = "Outgoing"
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
                            Text("Category Details")
                                .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack(spacing: 2) {
                                    Text("Name").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                }
                                TextField("e.g. Groceries", text: $name)
                                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }

                            // Type
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text("Type").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                Picker("Type", selection: $categoryType) {
                                    Text("Incoming").tag("Incoming")
                                    Text("Outgoing").tag("Outgoing")
                                }
                                .pickerStyle(.segmented)
                            }

                            // Icon selector
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text("Icon").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                let icons = ["🛒", "🏠", "🚗", "💡", "🎮", "👕", "🍽️", "☕", "✈️", "🏥", "📚", "🎵", "💼", "🎁", "🐾", "💰", "📱", "🏋️", "🎬", "🧾", "💳", "🚌", "🍕", "🛍️"]
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: PPSpacing.sm) {
                                    ForEach(icons, id: \.self) { i in
                                        Text(i)
                                            .font(.system(size: 24))
                                            .frame(width: 36, height: 36)
                                            .background(icon == i ? Color.ppPrimary.opacity(0.3) : Color.clear)
                                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: PPRadius.sm)
                                                    .stroke(icon == i ? Color.ppPrimary : Color.clear, lineWidth: 1)
                                            )
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
                        .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle("Add Category").navigationBarTitleDisplayMode(.inline)
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
                }
            }
        }
    }

    private func create() async {
        isLoading = true; errorMessage = nil
        struct Req: Encodable {
            let name: String; let color: String; let icon: String; let categoryType: String
        }
        let req = Req(name: name.trimmingCharacters(in: .whitespaces), color: color, icon: icon, categoryType: categoryType)
        do {
            try await appState.apiClient.request(.createCategory, body: req)
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
