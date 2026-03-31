import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
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

                            Text(String(localized: "auth.tagline"))
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
            Text(String(localized: "auth.welcomeBack"))
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
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text(String(localized: "field.email")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    TextField("you@example.com", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                        .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text(String(localized: "field.password")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    SecureField("Your password", text: $viewModel.password)
                        .textContentType(.password)
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                        .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                }
            }

            Button {
                Task { await viewModel.login() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(String(localized: "button.logIn"))
                            .font(.ppHeadline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, PPSpacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(.ppPrimary)
            .buttonBorderShape(.capsule)
            .disabled(viewModel.isLoginDisabled)

            VStack(spacing: PPSpacing.md) {
                NavigationLink("Forgot password?") {
                    ForgotPasswordView()
                        .environmentObject(appState)
                }
                .font(.ppCallout)
                .foregroundColor(.ppPrimary)

                HStack(spacing: 4) {
                    Text(String(localized: "auth.noAccount"))
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
                Text(String(localized: "auth.twoFactor"))
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                Text(String(localized: "auth.twoFactorDesc"))
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
                    Text(String(localized: "field.code")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                }
                TextField("123456", text: $viewModel.twoFactorCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
            }

            Button {
                Task { await viewModel.submit2FA() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(String(localized: "button.verify"))
                            .font(.ppHeadline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, PPSpacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(.ppPrimary)
            .buttonBorderShape(.capsule)
            .disabled(viewModel.is2FADisabled)

            Button(String(localized: "button.backToLogin")) {
                viewModel.needs2FA = false
                viewModel.twoFactorCode = ""
                viewModel.errorMessage = nil
            }
            .font(.ppCallout)
            .foregroundColor(.ppPrimary)
        }
    }
}
