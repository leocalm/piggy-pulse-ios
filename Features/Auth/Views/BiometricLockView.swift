// Features/Auth/Views/BiometricLockView.swift
import SwiftUI
import LocalAuthentication

struct BiometricLockView: View {
    @EnvironmentObject var appState: AppState

    private let biometryType: LABiometryType = BiometricHelper.availableBiometryType()

    private var iconName: String {
        switch biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }

    private var unlockLabel: String {
        switch biometryType {
        case .faceID: return "Unlock with Face ID"
        case .touchID: return "Unlock with Touch ID"
        default: return "Unlock"
        }
    }

    var body: some View {
        ZStack {
            Color.ppBackground.ignoresSafeArea()

            VStack(spacing: PPSpacing.xl) {
                Image("piggy-coin-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)

                Text("PiggyPulse")
                    .font(.ppLargeTitle)
                    .foregroundColor(.ppTextPrimary)

                Spacer().frame(height: PPSpacing.xxxl)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task { await appState.unlockWithBiometrics() }
                } label: {
                    Label(unlockLabel, systemImage: iconName)
                        .font(.ppHeadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.lg)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.ppPrimary)

                if appState.biometricAuthFailed {
                    Text("Authentication failed. Try again.")
                        .font(.ppCaption)
                        .foregroundColor(.ppAmber)
                        .transition(.opacity)
                }
            }
            .padding(PPSpacing.xxxl)
        }
        .task { await appState.unlockWithBiometrics() }
        .animation(.easeInOut(duration: 0.2), value: appState.biometricAuthFailed)
    }
}

#Preview {
    BiometricLockView()
        .environmentObject(AppState())
}
