import SwiftUI

struct RegisterView: View {
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
                        }

                        VStack(spacing: PPSpacing.xl) {
                            Text("Create an account")
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
                                        Text("Full Name").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                    }
                                    TextField("John Doe", text: $viewModel.registerName)
                                        .textContentType(.name)
                                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                        .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }

                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    HStack(spacing: 2) {
                                        Text("Email").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
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
                                }

                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    HStack(spacing: 2) {
                                        Text("Password").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                    }
                                    SecureField("Your password", text: $viewModel.registerPassword)
                                        .textContentType(.newPassword)
                                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                        .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }

                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    HStack(spacing: 2) {
                                        Text("Confirm Password").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                    }
                                    SecureField("Confirm your password", text: $viewModel.registerConfirmPassword)
                                        .textContentType(.newPassword)
                                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                        .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                            }

                            Button {
                                Task { await viewModel.register() }
                            } label: {
                                Group {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Register")
                                            .font(.ppHeadline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, PPSpacing.md)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.ppPrimary)
                            .buttonBorderShape(.capsule)
                            .disabled(viewModel.isRegisterDisabled)

                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(.ppCallout)
                                    .foregroundColor(.ppTextSecondary)
                                Button("Login") {
                                    dismiss()
                                }
                                .font(.ppCallout)
                                .foregroundColor(.ppPrimary)
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
}
