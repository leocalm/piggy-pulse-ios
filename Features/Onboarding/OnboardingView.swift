import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeManager) private var theme
    @StateObject private var vm: OnboardingViewModel

    init(apiClient: APIClient) {
        _vm = StateObject(wrappedValue: OnboardingViewModel(apiClient: apiClient))
    }

    var body: some View {
        ZStack {
            Color.ppBackground.ignoresSafeArea()

            if vm.isLoading {
                ProgressView()
            } else {
                VStack(spacing: 0) {

                    // Step indicator (only for steps 1–4)
                    if OnboardingStep.indicatorSteps.contains(vm.currentStep) {
                        OnboardingStepIndicator(currentStep: vm.currentStep)
                            .padding(.top, PPSpacing.xl)
                            .padding(.bottom, PPSpacing.sm)
                    }

                    // Step content
                    Group {
                        switch vm.currentStep {
                        case .welcome:
                            WelcomeStepView(vm: vm)
                        case .currency:
                            CurrencyStepView(vm: vm)
                        case .period:
                            PeriodStepView(vm: vm)
                        case .accounts:
                            AccountsStepView(vm: vm)
                        case .categories:
                            CategoriesStepView(vm: vm)
                        case .summary:
                            SummaryStepView(vm: vm)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Error
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.ppCallout).foregroundColor(.ppDestructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, PPSpacing.xl)
                            .padding(.bottom, PPSpacing.sm)
                    }

                    // Navigation buttons (not shown on welcome or summary — those have their own)
                    if vm.currentStep != .welcome && vm.currentStep != .summary {
                        navigationBar
                    }
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

    @ViewBuilder
    private var navigationBar: some View {
        let isSkippable = vm.currentStep == .accounts || vm.currentStep == .categories

        HStack(spacing: PPSpacing.md) {
            Button(String(localized: "common.back")) { vm.goBack() }
                .font(.ppCallout).foregroundColor(.ppTextSecondary)
                .frame(minWidth: 80)

            Spacer()

            if isSkippable {
                Button(String(localized: "button.skipForNow")) { vm.skip() }
                    .font(.ppCallout).foregroundColor(.ppTextSecondary)
                    .padding(.horizontal, PPSpacing.lg)
                    .padding(.vertical, PPSpacing.md)
            }

            Button {
                Task { await vm.advance() }
            } label: {
                if vm.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text(String(localized: "button.continue"))
                        .font(.ppCallout).fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, PPSpacing.xl)
            .padding(.vertical, PPSpacing.md)
            .background(vm.canAdvance ? theme.primary : theme.primary.opacity(0.4))
            .clipShape(Capsule())
            .disabled(!vm.canAdvance || vm.isSaving)
        }
        .padding(.horizontal, PPSpacing.xl)
        .padding(.vertical, PPSpacing.lg)
    }
}
