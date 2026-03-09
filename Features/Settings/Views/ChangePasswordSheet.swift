import SwiftUI

struct ChangePasswordSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

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
                Color.ppBackground(colorScheme).ignoresSafeArea()

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
                                    .foregroundColor(.ppTextPrimary(colorScheme))
                            }
                            .padding(.vertical, PPSpacing.xxxl)
                        } else {
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack(spacing: 2) {
                                    Text("Current Password").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                }
                                SecureField("Enter current password", text: $currentPassword)
                                    .textContentType(.password)
                                    .font(.ppBody).foregroundColor(.ppTextPrimary(colorScheme))
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface(colorScheme)).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
                            }
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack(spacing: 2) {
                                    Text("New Password").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                }
                                SecureField("Min 8 characters", text: $newPassword)
                                    .textContentType(.newPassword)
                                    .font(.ppBody).foregroundColor(.ppTextPrimary(colorScheme))
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface(colorScheme)).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
                            }
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack(spacing: 2) {
                                    Text("Confirm Password").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                }
                                SecureField("Repeat new password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .font(.ppBody).foregroundColor(.ppTextPrimary(colorScheme))
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface(colorScheme)).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
                            }

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
            .toolbarBackground(Color.ppBackground(colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.ppTextSecondary(colorScheme))
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
                    .foregroundColor(.ppTextSecondary(colorScheme))
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
            try await appState.apiClient.request(
                .changePassword,
                body: PasswordRequest(currentPassword: currentPassword, newPassword: newPassword)
            )
            success = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch let error as APIError {
            errorMessage = error.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "Failed to change password.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isLoading = false
    }
}
