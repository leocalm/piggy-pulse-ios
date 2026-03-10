import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = AuthViewModel(appState: AppState())
    @State private var viewModelReady = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.ppBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)

                    VStack(spacing: PPSpacing.xxl) {
                        // Logo
                        VStack(spacing: PPSpacing.sm) {
                            Image("piggy-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 44)

                            Text("PiggyPulse")
                                .font(.ppTitle)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.ppCyan, .ppPrimary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }

                        if viewModel.forgotPasswordSent {
                            successContent
                        } else {
                            formContent
                        }
                    }
                    .padding(PPSpacing.xxl)
                    .background(Color.ppCard)
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: PPRadius.xl)
                            .stroke(Color.ppBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, PPSpacing.lg)

                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if !viewModelReady {
                viewModel.appState = appState
                viewModelReady = true
            }
        }
    }

    // MARK: - Form

    private var formContent: some View {
        VStack(spacing: PPSpacing.xl) {
            VStack(spacing: PPSpacing.sm) {
                Text("Password recovery")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                Text("Enter your email address. If it is registered, you will receive a reset link.")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.ppCallout)
                    .foregroundColor(.ppDestructive)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                HStack(spacing: 2) {
                    Text("Email").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                }
                TextField("name@example.com", text: $viewModel.forgotEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
            }

            Button {
                Task { await viewModel.requestPasswordReset() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send link")
                            .font(.ppHeadline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, PPSpacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(.ppPrimary)
            .buttonBorderShape(.capsule)
            .disabled(viewModel.isForgotDisabled)

            Button("Back to login") {
                dismiss()
            }
            .font(.ppCallout)
            .foregroundColor(.ppPrimary)
        }
    }

    // MARK: - Success

    private var successContent: some View {
        VStack(spacing: PPSpacing.xl) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 48))
                .foregroundColor(.ppPrimary)

            VStack(spacing: PPSpacing.sm) {
                Text("Check your email")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                Text("If an account exists for that email, we've sent a password reset link. Check your inbox and spam folder.")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button("Back to login") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.ppPrimary)
            .frame(maxWidth: .infinity)
            .controlSize(.large)
        }
    }
}
