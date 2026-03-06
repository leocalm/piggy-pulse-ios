import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel(appState: AppState())

    @State private var viewModelReady = false

    var body: some View {
        ZStack {
            Color.ppBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)

                    // Card
                    VStack(spacing: PPSpacing.xxl) {
                        // Logo + tagline
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

                            Text("Clarity begins with structure.")
                                .font(.ppCallout)
                                .foregroundColor(.ppTextSecondary)
                        }

                        if viewModel.needs2FA {
                            twoFactorContent
                        } else {
                            loginContent
                        }
                    }
                    .padding(PPSpacing.xxl)
                    .background(Color.ppCard)
                    .cornerRadius(PPRadius.xl)
                    .overlay(
                        RoundedRectangle(cornerRadius: PPRadius.xl)
                            .stroke(Color.ppBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, PPSpacing.lg)

                    Spacer()
                }
            }
        }
        .onAppear {
            if !viewModelReady {
                viewModel.appState = appState
                viewModelReady = true
            }
            viewModel.resetState()
        }
    }

    // MARK: - Login Form

    private var loginContent: some View {
        VStack(spacing: PPSpacing.xl) {
            Text("Welcome back")
                .font(.ppTitle3)
                .foregroundColor(.ppTextPrimary)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.ppCallout)
                    .foregroundColor(.ppDestructive)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: PPSpacing.lg) {
                PPTextField(
                    label: "Email",
                    placeholder: "you@example.com",
                    isRequired: true,
                    text: $viewModel.email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )

                PPTextField(
                    label: "Password",
                    placeholder: "Your password",
                    isRequired: true,
                    text: $viewModel.password,
                    isSecure: true,
                    textContentType: .password
                )
            }

            Button {
                Task { await viewModel.login() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Log in")
                            .font(.ppHeadline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, PPSpacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(.ppPrimary)
            .cornerRadius(PPRadius.full)
            .disabled(viewModel.isLoginDisabled)
            .opacity(viewModel.isLoginDisabled ? 0.6 : 1)

            VStack(spacing: PPSpacing.md) {
                NavigationLink("Forgot password?") {
                    ForgotPasswordView()
                        .environmentObject(appState)
                }
                .font(.ppCallout)
                .foregroundColor(.ppPrimary)

                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary)
                    NavigationLink("Sign up") {
                        RegisterView()
                            .environmentObject(appState)
                    }
                    .font(.ppCallout)
                    .foregroundColor(.ppPrimary)
                }
            }
        }
    }

    // MARK: - 2FA Form

    private var twoFactorContent: some View {
        VStack(spacing: PPSpacing.xl) {
            VStack(spacing: PPSpacing.sm) {
                Text("Two-Factor Authentication")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                Text("Enter the code from your authenticator app.")
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

            PPTextField(
                label: "Code",
                placeholder: "123456",
                isRequired: true,
                text: $viewModel.twoFactorCode,
                keyboardType: .numberPad,
                textContentType: .oneTimeCode
            )

            Button {
                Task { await viewModel.submit2FA() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Verify")
                            .font(.ppHeadline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, PPSpacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(.ppPrimary)
            .cornerRadius(PPRadius.full)
            .disabled(viewModel.is2FADisabled)
            .opacity(viewModel.is2FADisabled ? 0.6 : 1)

            Button("Back to login") {
                viewModel.needs2FA = false
                viewModel.twoFactorCode = ""
                viewModel.errorMessage = nil
            }
            .font(.ppCallout)
            .foregroundColor(.ppPrimary)
        }
    }
}
