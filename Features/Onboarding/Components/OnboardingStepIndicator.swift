import SwiftUI

struct OnboardingStepIndicator: View {
    let currentStep: OnboardingStep

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PPSpacing.sm) {
                ForEach(Array(OnboardingStep.allCases.enumerated()), id: \.element) { idx, step in
                    let isCurrent = step == currentStep
                    let isPast = step.index < currentStep.index

                    HStack(spacing: PPSpacing.xs) {
                        if isPast {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption).foregroundColor(.ppTeal)
                        } else {
                            Text("\(idx + 1)")
                                .font(.ppCaption).fontWeight(.semibold)
                                .foregroundColor(isCurrent ? .ppPrimary : .ppTextTertiary)
                        }
                        Text(step.title)
                            .font(.ppCaption).fontWeight(isCurrent ? .semibold : .regular)
                            .foregroundColor(isCurrent ? .ppTextPrimary : .ppTextTertiary)
                    }
                    .padding(.horizontal, PPSpacing.md)
                    .padding(.vertical, PPSpacing.sm)
                    .background(isCurrent ? Color.ppPrimary.opacity(0.15) : Color.clear)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(isCurrent ? Color.ppPrimary : Color.ppBorder, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, PPSpacing.xl)
        }
    }
}
