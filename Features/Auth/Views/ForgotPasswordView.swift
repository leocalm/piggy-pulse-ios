import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.themeManager) private var theme
    @StateObject private var viewModel = AuthViewModel(appState: AppState())
    @State private var viewModelReady = false
    @Environment(\.dismiss) private var dismiss

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
                    AuthHeaderView(tagline: String(localized: "auth.tagline.forgotPassword"))

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
    }

    // MARK: - Form

    private var formContent: some View {
        VStack(spacing: PPSpacing.xl) {
            VStack(spacing: PPSpacing.sm) {
                Text(String(localized: "auth.passwordRecovery"))
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                Text(String(localized: "auth.passwordRecoveryDesc"))
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
                    Text(String(localized: "field.email")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
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
                        Text(String(localized: "button.sendLink"))
                            .font(.ppHeadline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, PPSpacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.primary)
            .buttonBorderShape(.capsule)
            .disabled(viewModel.isForgotDisabled)

            Button(String(localized: "button.backToLogin")) {
                dismiss()
            }
            .font(.ppCallout)
            .foregroundColor(theme.primary)
        }
    }

    // MARK: - Success

    private var successContent: some View {
        VStack(spacing: PPSpacing.xl) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.primary)

            VStack(spacing: PPSpacing.sm) {
                Text(String(localized: "auth.checkEmail"))
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                Text(String(localized: "auth.checkEmailDesc"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(String(localized: "button.backToLogin")) {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(theme.primary)
            .frame(maxWidth: .infinity)
            .controlSize(.large)
        }
    }
}
