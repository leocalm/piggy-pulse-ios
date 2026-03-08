import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm: OnboardingViewModel

    init(appState: AppState) {
        _vm = StateObject(wrappedValue: OnboardingViewModel(apiClient: appState.apiClient))
    }

    var body: some View {
        ZStack {
            Color.ppBackground.ignoresSafeArea()

            if vm.isLoading {
                ProgressView()
            } else {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: PPSpacing.md) {
                        Text("Welcome to PiggyPulse")
                            .font(.ppTitle2).fontWeight(.bold).foregroundColor(.ppTextPrimary)
                        OnboardingStepIndicator(currentStep: vm.currentStep)
                    }
                    .padding(.top, PPSpacing.xl)
                    .padding(.bottom, PPSpacing.md)

                    // Step content
                    Group {
                        switch vm.currentStep {
                        case .period:     PeriodStepView(vm: vm)
                        case .accounts:   AccountsStepView(vm: vm)
                        case .categories: CategoriesStepView(vm: vm)
                        case .summary:    SummaryStepView(vm: vm)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Error
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.ppCallout).foregroundColor(.ppDestructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, PPSpacing.xl)
                    }

                    // Navigation buttons
                    HStack(spacing: PPSpacing.md) {
                        if vm.currentStep != .period {
                            Button("Back") { vm.goBack() }
                                .font(.ppCallout).foregroundColor(.ppTextSecondary)
                                .frame(minWidth: 80)
                        }
                        Spacer()
                        Button {
                            Task { await vm.advance() }
                        } label: {
                            if vm.isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text(vm.currentStep == .summary ? "Finish" : "Continue")
                                    .font(.ppCallout).fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, PPSpacing.xl)
                        .padding(.vertical, PPSpacing.md)
                        .background(vm.canAdvance ? Color.ppPrimary : Color.ppPrimary.opacity(0.4))
                        .clipShape(Capsule())
                        .disabled(!vm.canAdvance || vm.isSaving)
                    }
                    .padding(.horizontal, PPSpacing.xl)
                    .padding(.vertical, PPSpacing.lg)
                }
            }
        }
        .task { await vm.loadStatus() }
        .interactiveDismissDisabled(true)
        .onChange(of: vm.isComplete) { _, complete in
            if complete {
                Task { await appState.checkAuth() }
            }
        }
    }
}
