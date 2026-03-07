import SwiftUI

struct ChangePasswordSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var success = false

    private var isDisabled: Bool {
        currentPassword.isEmpty || newPassword.count < 8 || newPassword != confirmPassword || isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: PPSpacing.xl) {
                        if let error = errorMessage {
                            Text(error)
                                .font(.ppCallout)
                                .foregroundColor(.ppDestructive)
                                .multilineTextAlignment(.center)
                        }

                        if success {
                            VStack(spacing: PPSpacing.md) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.ppCyan)
                                Text("Password changed successfully")
                                    .font(.ppHeadline)
                                    .foregroundColor(.ppTextPrimary)
                            }
                            .padding(.vertical, PPSpacing.xxxl)
                        } else {
                            PPTextField(label: "Current Password", placeholder: "Enter current password", isRequired: true, text: $currentPassword, isSecure: true)
                            PPTextField(label: "New Password", placeholder: "Min 8 characters", isRequired: true, text: $newPassword, isSecure: true)
                            PPTextField(label: "Confirm Password", placeholder: "Repeat new password", isRequired: true, text: $confirmPassword, isSecure: true)

                            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                                Text("Passwords don't match")
                                    .font(.ppCaption)
                                    .foregroundColor(.ppDestructive)
                            }
                        }
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle("Change Password")
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
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await changePassword() }
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

    private func changePassword() async {
        isLoading = true
        errorMessage = nil

        struct PasswordRequest: Encodable {
            let currentPassword: String
            let newPassword: String
        }

        do {
            let _: String = try await appState.apiClient.requestString(
                .changePassword,
                body: PasswordRequest(currentPassword: currentPassword, newPassword: newPassword)
            )
            success = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to change password."
        }
        isLoading = false
    }
}
