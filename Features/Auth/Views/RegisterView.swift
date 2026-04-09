import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.themeManager) private var theme
    @StateObject private var viewModel = AuthViewModel(appState: AppState())
    @State private var viewModelReady = false
    @State private var agreedToTerms = false
    @Environment(\.dismiss) private var dismiss

    private var passwordScore: Int {
        PasswordStrength.score(for: viewModel.registerPassword)
    }

    private var passwordsDoNotMatch: Bool {
        !viewModel.registerConfirmPassword.isEmpty &&
        viewModel.registerPassword != viewModel.registerConfirmPassword
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
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

    // MARK: - iPad Split Layout

    private var iPadLayout: some View {
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

    // MARK: - iPhone Stacked Layout

    private var iPhoneLayout: some View {
        ZStack {
            Color.ppBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    AuthHeaderView(tagline: String(localized: "auth.tagline.register"))

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
            VStack(spacing: PPSpacing.xl) {
                VStack(spacing: PPSpacing.xs) {
                    Text(String(localized: "auth.register.title"))
                        .font(.ppTitle3)
                        .foregroundColor(.ppTextPrimary)

                    Text(String(localized: "auth.register.subtitle"))
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
                    // Full name
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        HStack(spacing: 2) {
                            Text(String(localized: "field.fullName")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                            Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                        }
                        TextField("John Doe", text: $viewModel.registerName)
                            .textContentType(.name)
                            .font(.ppBody).foregroundColor(.ppTextPrimary)
                            .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                            .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            .accessibilityIdentifier("register-name")
                    }

                    // Email
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        HStack(spacing: 2) {
                            Text(String(localized: "field.email")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                            Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                        }
                        TextField("you@example.com", text: $viewModel.registerEmail)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .font(.ppBody).foregroundColor(.ppTextPrimary)
                            .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                            .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            .accessibilityIdentifier("register-email")
                    }

                    // Password + strength bar
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        HStack(spacing: 2) {
                            Text(String(localized: "field.password")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                            Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                        }
                        SecureField("Your password", text: $viewModel.registerPassword)
                            .textContentType(.newPassword)
                            .font(.ppBody).foregroundColor(.ppTextPrimary)
                            .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                            .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            .accessibilityIdentifier("register-password")

                        if !viewModel.registerPassword.isEmpty {
                            PasswordStrengthBar(password: viewModel.registerPassword)
                        }
                    }

                    // Confirm password
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        HStack(spacing: 2) {
                            Text(String(localized: "field.confirmPassword")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                            Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                        }
                        SecureField("Confirm your password", text: $viewModel.registerConfirmPassword)
                            .textContentType(.newPassword)
                            .font(.ppBody).foregroundColor(.ppTextPrimary)
                            .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                            .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(
                                passwordsDoNotMatch ? Color.ppDestructive : Color.ppBorder,
                                lineWidth: 1
                            ))
                            .accessibilityIdentifier("register-confirm-password")

                        if passwordsDoNotMatch {
                            Text(String(localized: "auth.register.passwordsDoNotMatch"))
                                .font(.ppCaption)
                                .foregroundColor(.ppDestructive)
                        }
                    }
                }

                // Terms checkbox
                Button {
                    agreedToTerms.toggle()
                } label: {
                    HStack(alignment: .top, spacing: PPSpacing.sm) {
                        Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(agreedToTerms ? theme.primary : .ppTextSecondary)
                            .font(.system(size: 20))

                        Text(String(localized: "auth.register.agreeToTerms"))
                            .font(.ppCallout)
                            .foregroundColor(.ppTextSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("register-terms")

                Button {
                    Task { await viewModel.register() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(String(localized: "button.register"))
                                .font(.ppHeadline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PPSpacing.md)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.primary)
                .buttonBorderShape(.capsule)
                .disabled(viewModel.isRegisterDisabled || !agreedToTerms || passwordsDoNotMatch)
                .accessibilityIdentifier("register-submit")

                HStack(spacing: 4) {
                    Text(String(localized: "auth.alreadyHaveAccount"))
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary)
                    Button(String(localized: "button.login")) {
                        dismiss()
                    }
                    .font(.ppCallout)
                    .foregroundColor(theme.primary)
                }
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
}
