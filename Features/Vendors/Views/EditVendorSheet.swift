import SwiftUI

struct EditVendorSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let vendor: VendorListItem
    var onUpdated: () -> Void

    @State private var name = ""
    @State private var desc = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                            Text("Vendor Details").font(.ppTitle3).foregroundColor(.ppTextPrimary)
                            PPTextField(label: "Name", placeholder: "Vendor name", isRequired: true, text: $name)
                            PPTextField(label: "Description", placeholder: "Optional", isRequired: false, text: $desc)
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard).cornerRadius(PPRadius.lg)
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle("Edit Vendor").navigationBarTitleDisplayMode(.inline)
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
            .onAppear { name = vendor.name; desc = vendor.description ?? "" }
        }
    }

    private func save() async {
        isLoading = true; errorMessage = nil
        struct Req: Encodable { let name: String; let description: String? }
        let d = desc.trimmingCharacters(in: .whitespaces)
        let req = Req(name: name.trimmingCharacters(in: .whitespaces), description: d.isEmpty ? nil : d)
        do {
            let _: VendorListItem = try await appState.apiClient.request(.updateVendor(vendor.id), body: req)
            onUpdated(); dismiss()
        } catch let e as APIError { errorMessage = e.errorDescription }
        catch { errorMessage = "Failed to update vendor." }
        isLoading = false
    }
}
