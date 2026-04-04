import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.themeManager) private var theme
    @StateObject private var viewModel = AuthViewModel(appState: AppState())

    @State private var viewModelReady = false

    var body: some View {
        Group {
            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
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

    // MARK: - iPad Split Layout

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            AuthBrandingPanel(tagline: String(localized: "auth.tagline.login"))

            NavigationStack {
                GeometryReader { geo in
                    ScrollView {
                        VStack {
                            Spacer()
                            formCard
                                .frame(maxWidth: 420)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: geo.size.height)
                    }
                }
                .background(Color.ppBackground)
            }
        }
    }

    // MARK: - iPhone Stacked Layout

    private var iPhoneLayout: some View {
        ZStack {
            Color.ppBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    AuthHeaderView(tagline: String(localized: "auth.tagline.login"))

                    formCard
                        .padding(.horizontal, PPSpacing.lg)
                        .padding(.top, PPSpacing.xl)

                    Spacer()
                        .frame(height: PPSpacing.xxl)
                }
            }
        }
    }

    // MARK: - Shared Form Card

    private var formCard: some View {
        VStack(spacing: PPSpacing.xxl) {
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
    }

    // MARK: - Login Form

    private var loginContent: some View {
        VStack(spacing: PPSpacing.xl) {
            VStack(spacing: PPSpacing.xs) {
                Text(String(localized: "auth.login.title"))
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                Text(String(localized: "auth.login.subtitle"))
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
            .tint(theme.primary)
            .buttonBorderShape(.capsule)
            .disabled(viewModel.isLoginDisabled)

            VStack(spacing: PPSpacing.md) {
                NavigationLink(String(localized: "auth.forgotPassword")) {
                    ForgotPasswordView()
                        .environmentObject(appState)
                }
                .font(.ppCallout)
                .foregroundColor(theme.primary)

                HStack(spacing: 4) {
                    Text(String(localized: "auth.noAccount"))
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary)
                    NavigationLink(String(localized: "button.signUp")) {
                        RegisterView()
                            .environmentObject(appState)
                    }
                    .font(.ppCallout)
                    .foregroundColor(theme.primary)
                }
            }
        }
    }

    // MARK: - 2FA Form

    private var twoFactorContent: some View {
        VStack(spacing: PPSpacing.xl) {
            twoFactorHeader

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.ppCallout)
                    .foregroundColor(.ppDestructive)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if viewModel.twoFactorUseRecovery {
                recoveryCodeField
            } else {
                authenticatorCodeField
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
            .tint(theme.primary)
            .buttonBorderShape(.capsule)
            .disabled(viewModel.is2FADisabled)

            Button {
                viewModel.twoFactorUseRecovery.toggle()
                viewModel.twoFactorCode = ""
                viewModel.errorMessage = nil
            } label: {
                Text(viewModel.twoFactorUseRecovery
                     ? String(localized: "auth.twoFactor.useAuthenticator")
                     : String(localized: "auth.twoFactor.useRecoveryCode"))
                    .font(.ppCallout)
                    .foregroundColor(theme.primary)
            }

            Button(String(localized: "button.backToLogin")) {
                viewModel.needs2FA = false
                viewModel.twoFactorCode = ""
                viewModel.twoFactorUseRecovery = false
                viewModel.errorMessage = nil
            }
            .font(.ppCallout)
            .foregroundColor(.ppTextSecondary)
        }
    }

    private var twoFactorHeader: some View {
        VStack(spacing: PPSpacing.sm) {
            if viewModel.twoFactorUseRecovery {
                Text(String(localized: "auth.twoFactor.recoveryTitle"))
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                Text(String(localized: "auth.twoFactor.recoveryDesc"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text(String(localized: "auth.twoFactor"))
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                Text(String(localized: "auth.twoFactorDesc"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var authenticatorCodeField: some View {
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
    }

    private var recoveryCodeField: some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            HStack(spacing: 2) {
                Text(String(localized: "field.recoveryCode")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
            }
            TextField("xxxxxxxx-xxxx-xxxx", text: $viewModel.twoFactorCode)
                .keyboardType(.asciiCapable)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .font(.ppBody).foregroundColor(.ppTextPrimary)
                .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
        }
    }
}
