import SwiftUI

struct AddVendorSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var onCreated: () -> Void

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
                            Text("Vendor Details")
                                .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                            PPTextField(label: "Name", placeholder: "e.g. Albert Heijn", isRequired: true, text: $name)
                            PPTextField(label: "Description", placeholder: "Optional description", isRequired: false, text: $description)
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard).cornerRadius(PPRadius.lg)
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle("Add Vendor").navigationBarTitleDisplayMode(.inline)
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
            let name: String; let description: String?
        }
        let desc = description.trimmingCharacters(in: .whitespaces)
        let req = Req(name: name.trimmingCharacters(in: .whitespaces), description: desc.isEmpty ? nil : desc)
        do {
            let _: VendorListItem = try await appState.apiClient.request(.createVendor, body: req)
            onCreated(); dismiss()
        } catch let e as APIError { errorMessage = e.errorDescription }
        catch { errorMessage = "Failed to create vendor." }
        isLoading = false
    }
}
