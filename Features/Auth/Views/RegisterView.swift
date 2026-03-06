import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
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
                                PPTextField(
                                    label: "Full Name",
                                    placeholder: "John Doe",
                                    isRequired: true,
                                    text: $viewModel.registerName,
                                    textContentType: .name
                                )

                                PPTextField(
                                    label: "Email",
                                    placeholder: "you@example.com",
                                    isRequired: true,
                                    text: $viewModel.registerEmail,
                                    keyboardType: .emailAddress,
                                    textContentType: .emailAddress
                                )

                                PPTextField(
                                    label: "Password",
                                    placeholder: "Your password",
                                    isRequired: true,
                                    text: $viewModel.registerPassword,
                                    isSecure: true,
                                    textContentType: .newPassword
                                )

                                PPTextField(
                                    label: "Confirm Password",
                                    placeholder: "Confirm your password",
                                    isRequired: true,
                                    text: $viewModel.registerConfirmPassword,
                                    isSecure: true,
                                    textContentType: .newPassword
                                )
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
                            .cornerRadius(PPRadius.full)
                            .disabled(viewModel.isRegisterDisabled)
                            .opacity(viewModel.isRegisterDisabled ? 0.6 : 1)

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
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if !viewModelReady {
                viewModel.appState = appState
                viewModelReady = true
            }
        }
    }
}
