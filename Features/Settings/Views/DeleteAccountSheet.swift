import SwiftUI

struct DeleteAccountSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var confirmationText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showConfirmation = false

    private var isDisabled: Bool {
        confirmationText != "DELETE" || isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: PPSpacing.xl) {
                        VStack(spacing: PPSpacing.md) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.ppDestructive)

                            Text("Delete Account")
                                .font(.ppTitle3)
                                .foregroundColor(.ppTextPrimary)

                            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
                                .font(.ppCallout)
                                .foregroundColor(.ppTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, PPSpacing.lg)

                        if let error = errorMessage {
                            Text(error)
                                .font(.ppCallout)
                                .foregroundColor(.ppDestructive)
                                .multilineTextAlignment(.center)
                        }

                        VStack(alignment: .leading, spacing: PPSpacing.sm) {
                            Text("Type **DELETE** to confirm")
                                .font(.ppCallout)
                                .foregroundColor(.ppTextPrimary)

                            TextField("DELETE", text: $confirmationText)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                                .font(.ppBody).foregroundColor(.ppTextPrimary)
                                .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            showConfirmation = true
                        } label: {
                            HStack {
                                Group {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Delete My Account")
                                            .font(.ppHeadline)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, PPSpacing.md)
                            .background(isDisabled ? Color.ppDestructive.opacity(0.4) : Color.ppDestructive)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        }
                        .disabled(isDisabled)
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.ppTextSecondary)
                }
            }
            .confirmationDialog(
                "Are you sure?",
                isPresented: $showConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your account and all data will be permanently deleted. This cannot be undone.")
            }
        }
    }

    private func deleteAccount() async {
        isLoading = true
        errorMessage = nil

        do {
            try await appState.deleteAccount(confirmation: confirmationText)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch let error as APIError {
            errorMessage = error.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "Failed to delete account.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isLoading = false
    }
}
