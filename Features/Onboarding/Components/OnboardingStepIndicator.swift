import SwiftUI

struct OnboardingStepIndicator: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeManager) private var theme
    let currentStep: OnboardingStep

    private var indicatorSteps: [OnboardingStep] { OnboardingStep.indicatorSteps }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(indicatorSteps.enumerated()), id: \.element) { idx, step in
                stepDot(step: step, index: idx)
                if idx < indicatorSteps.count - 1 {
                    connectorLine(afterStep: step)
                }
            }
        }
        .padding(.horizontal, PPSpacing.xl)
    }

    private func status(for step: OnboardingStep) -> StepStatus {
        if step.index < currentStep.index { return .completed }
        if step == currentStep { return .current }
        return .future
    }

    @ViewBuilder
    private func stepDot(step: OnboardingStep, index: Int) -> some View {
        let s = status(for: step)
        VStack(spacing: PPSpacing.xs) {
            ZStack {
                Circle()
                    .fill(s == .current ? theme.primary : s == .completed ? theme.primary.opacity(0.2) : Color.ppSurface)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().stroke(
                            s == .future ? Color.ppBorder : theme.primary,
                            lineWidth: s == .current ? 2 : 1
                        )
                    )
                if s == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.primary)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(s == .current ? .white : .ppTextTertiary)
                }
            }

            Text(step.indicatorTitle)
                .font(.ppCaption)
                .fontWeight(s == .current ? .semibold : .regular)
                .foregroundColor(s == .current ? .ppTextPrimary : s == .completed ? theme.primary : .ppTextTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func connectorLine(afterStep step: OnboardingStep) -> some View {
        let s = status(for: step)
        Rectangle()
            .fill(s == .completed ? theme.primary.opacity(0.4) : Color.ppBorder)
            .frame(height: 1)
            .padding(.bottom, 20) // align with dot center, accounting for label below
    }

    private enum StepStatus { case completed, current, future }
}
